#!/bin/sh -eu
# Pure polling/cadence decision. It never observes the repository or starts a worker.
# Usage: plan-poll.sh --input FILE
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd); . "$SCRIPT_DIR/lib/result.sh"
[ "${1:-}" = --input ] || runtime_usage "usage: plan-poll.sh --input FILE"
INPUT=${2:-}; runtime_require_json_file "$INPUT"
jq -e '(.now_epoch|type=="number") and (.polling|type=="object") and (.state|type=="object")' "$INPUT" >/dev/null 2>&1 || runtime_usage "invalid poll input"
jq -c '
  def due($v): ($v != null and $v <= .now_epoch);
  . as $i | (.polling.interval_seconds // 300) as $explicit
  | (if (.polling.mode // "fixed")=="adaptive" then
       (if (.state.conversation_active // false) then (.polling.conversation_seconds // 30)
        else (if (.state.idle_streak // 0)>0 then (.polling.max_seconds // 900) else (.polling.idle_seconds // 300) end) end)
     else $explicit end) as $fixed
  | if ($fixed|type)!="number" or $fixed<=0 then error("bad interval") else . end
  | (.state.retry_after_epoch // null) as $retry
  | (.state.remote_due_epoch // null) as $remote
  | (.state.exploration_due_epoch // null) as $explore
  | (.state.maintenance_due_epoch // null) as $maintain
  | ((.state.local_fingerprint // "") != (.observed.local_fingerprint // "")) as $local_changed
  | ((.observed.input_ids // []) - (.state.captured_input_ids // [])) as $new_inputs
  | if due($retry) then {observe:true,launch_worker:false,reason:"provider_retry",due:["retry"],next_due:($i.now_epoch+$fixed)}
    elif $retry != null then {observe:false,launch_worker:false,reason:"provider_backoff",due:[],next_due:$retry}
    elif $local_changed or ($new_inputs|length)>0 then {observe:true,launch_worker:(($new_inputs|length)>0),reason:(if $local_changed then "local_changed" else "new_input" end),due:[],next_due:($i.now_epoch+$fixed)}
    elif due($remote) or due($explore) or due($maintain) then
      {observe:true,launch_worker:false,reason:"cadence_due",due:[if due($remote) then "remote" else empty end,if due($explore) then "exploration" else empty end,if due($maintain) then "maintenance" else empty end],next_due:($i.now_epoch+$fixed)}
    else {observe:false,launch_worker:false,reason:"idle_cached",due:[],next_due:([$remote,$explore,$maintain]|map(select(.!=null))|min // ($i.now_epoch+$fixed))}
    end
  | {protocol:"workaholic.runtime/v1",request_id:"plan-poll",status:"ok",reason:"",data:.}' "$INPUT" 2>/dev/null || runtime_usage "invalid poll values"
