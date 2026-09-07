#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
[ "${1:-}" = --input ] || runtime_usage "usage: plan-turn.sh --input FILE"
INPUT=${2:-}; runtime_require_json_file "$INPUT"
jq -e '(.now|type=="string") and (.snapshot|type=="object") and (.state|type=="object")' "$INPUT" >/dev/null 2>&1 || runtime_usage "plan input requires now, snapshot, and state"
jq -c '
  def action($name;$reason;$target): {action:$name,reason:$reason,target:$target};
  . as $input
  | ((.state.exploration_due // false) or ((.state.exploration_due_at? // "9999") <= .now)) as $exploration_due
  | ((.state.maintenance_due // false) or ((.state.maintenance_due_at? // "9999") <= .now)) as $maintenance_due
  | if (.state.stop_requested // false) then
    {actions:[action("stop";"stop_requested";null)],next_due:null,reasons:["stop_requested"]}
  elif ((.state.results_incomplete // [])|length)>0 or ((.state.results_unknown // [])|length)>0 then
    {actions:[action("reconcile_result";"result_incomplete_or_unknown";((.state.results_incomplete // []) + (.state.results_unknown // [])))],next_due:null,reasons:["result_incomplete_or_unknown"]}
  elif ((.snapshot.communication.new_input_ids // [])|length)>0 then
    {actions:[action("observe_input";"human_input";.snapshot.communication.new_input_ids),action("report";"human_input";null)],next_due:null,reasons:["human_input"]}
  elif ((.snapshot.work.claimable_units // [])|length)>0 or ((.state.ready_work // [])|length)>0 then
    {actions:[action("plan_work";"work_available";((.snapshot.work.claimable_units // []) + (.state.ready_work // []))),action("dispatch_worker";"work_available";null)],next_due:null,reasons:["work_available"]}
  elif ((.snapshot.work.strategy_survey.eligible // [])|length)>0 then
    {actions:[action("plan_work";"strategy_learning";[.snapshot.work.strategy_survey.eligible[]|{slug,stage,feedback_refs,landed,queued,residue}])],next_due:null,reasons:["strategy_learning"]}
  elif ($exploration_due or $maintenance_due) then
    {actions:[action("plan_work";(if $exploration_due then "exploration_due" else "maintenance_due" end);null)],next_due:(.state.next_due // null),reasons:[if $exploration_due then "exploration_due" else "maintenance_due" end]}
  else
    {actions:[action("wait";"nothing_due";null)],next_due:(.state.next_due // .snapshot.freshness.next_due // null),reasons:["nothing_due"]}
  end
  | {protocol:"workaholic.runtime/v1",request_id:(input_filename|if .=="" then "plan-turn" else "plan-turn" end),status:"ok",reason:"",data:.}' "$INPUT"
