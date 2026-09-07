#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
SNAPSHOT="" ROLE="" UNIT=""
while [ $# -gt 0 ]; do
    case "$1" in --snapshot) SNAPSHOT=${2:-}; shift 2;; --role) ROLE=${2:-}; shift 2;; --unit) UNIT=${2:-}; shift 2;; *) runtime_usage "invalid context-packet argument";; esac
done
runtime_require_json_file "$SNAPSHOT"
case "$ROLE" in coordinator|planner|implementer|reporter|delivery) ;; *) runtime_usage "invalid role" ;; esac
jq -c --arg role "$ROLE" --arg unit "$UNIT" '
  def selected_work: if $unit=="" then (.work // {}) else {unit:$unit,item:([.work.missions[]?,.work.tickets[]?,.work.claims[]?]|map(select((.unit // .slug // .path)==$unit))|first)} end;
  {protocol:"workaholic.runtime/v1",request_id:("context-"+$role+(if $unit=="" then "" else "-"+$unit end)),status:"ok",reason:"",
   data:{snapshot_id:.snapshot_id,observed_at:.observed_at,role:$role,unit:(if $unit=="" then null else $unit end),repo:.repo,identity:.identity,work:selected_work,
     evidence:(.evidence // []),decisions:(.decisions // []),completion:(.completion[$role] // []),communication:(if $role=="coordinator" or $role=="reporter" then (.communication // {}) else {new_input_ids:(.communication.new_input_ids // [])} end)}}' "$SNAPSHOT"

