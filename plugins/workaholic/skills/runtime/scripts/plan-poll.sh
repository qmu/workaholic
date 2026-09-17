#!/bin/sh -eu
# Pure transition for Slack/GitHub observation cadence. Observation is optional.
#
# `observed.settled` (2026-09-17) is the observation's own answer to *may this read be reported
# as the channel having nothing new*. ABSENT MEANS SETTLED, the `merge_policy`/`status:`
# convention, so a caller not yet passing it behaves byte-identically; `false` answers
# `observation_incomplete` instead of `quiet`. It changes the WORD and never the interval: an
# unread page already forces an immediate re-poll through `has_more`, and a standing limitation
# such as a route that will never carry thread discovery would otherwise shorten the interval
# forever, which is a spin rather than a repair.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd); . "$SCRIPT_DIR/lib/result.sh"
[ "${1:-}" = --input ] || runtime_usage "usage: plan-poll.sh --input FILE"
INPUT=${2:-}; runtime_require_json_file "$INPUT"
jq -e '(.now_epoch|type=="number") and (.polling|type=="object") and (.state|type=="object") and ((.observed? // null)==null or (.observed|type=="object"))' "$INPUT" >/dev/null 2>&1 || runtime_usage "invalid poll input"
jq -c '
  . as $i
  | (.polling.mode // "adaptive") as $mode
  | (.polling.interval_seconds // 300) as $fixed
  | (.polling.conversation_seconds // 30) as $fast
  | (.polling.idle_seconds // 300) as $idle
  | (.polling.max_seconds // 900) as $max
  | if ([$fixed,$fast,$idle,$max]|all(type=="number" and .>0)) and ($mode=="fixed" or $mode=="adaptive") then . else error("bad polling") end
  | (.state.retry_after_epoch // null) as $retry
  | (.state.next_observation_epoch // 0) as $next
  | if .observed == null then
      (if $retry != null and $i.now_epoch < $retry then {observe:false,reason:"provider_backoff",next_due:$retry,next_state:.state}
       elif $i.now_epoch >= $next then {observe:true,reason:(if $retry!=null then "provider_retry" else "observation_due" end),next_due:$i.now_epoch,next_state:.state}
       else {observe:false,reason:"observation_cached",next_due:$next,next_state:.state} end)
    elif (.observed.proved // false) != true then
      ((.state.failure_streak // 0)+1) as $fail
      | ([($fast * pow(2;($fail-1))),$max]|min) as $delay
      | (.observed.retry_after_epoch // ($i.now_epoch+$delay)) as $due
      | {observe:false,reason:"observation_unreadable",next_due:$due,next_state:(.state + {failure_streak:$fail,retry_after_epoch:$due})}
    else
      ((.observed.activity // false) == true) as $activity
      | (if $mode=="fixed" then $fixed elif $activity then ([$fast,$max]|min)
         elif (.state.last_observed_epoch // null)==null then ([$idle,$max]|min)
         else ([((.state.current_interval_seconds // $fast)*2),$max]|min) end) as $interval
      | (if (.observed.has_more // false) then $i.now_epoch else ($i.now_epoch+$interval) end) as $due
      # NEVER `.observed.settled // true` here: jq treats `false` itself as empty, so the one
      # value this term exists to read would fall through to the default. Same trap as the
      # `.ok != false` guard in `adapters/qfs.sh` (`rules/shell.md`). No apostrophes: this
      # program lives inside a single-quoted shell string.
      | ((.observed | has("settled")) and (.observed.settled != true)) as $unsettled
      | {observe:false,reason:(if $activity then "activity" elif $unsettled then "observation_incomplete" else "quiet" end),next_due:$due,
         next_state:{last_observed_epoch:$i.now_epoch,last_activity_epoch:(if $activity then $i.now_epoch else (.state.last_activity_epoch // null) end),quiet_streak:(if $activity then 0 else ((.state.quiet_streak // 0)+1) end),current_interval_seconds:$interval,next_observation_epoch:$due,failure_streak:0,retry_after_epoch:null}}
    end
  | {protocol:"workaholic.runtime/v1",request_id:"plan-poll",status:"ok",reason:"",data:.}' "$INPUT" 2>/dev/null || runtime_usage "invalid poll values"
