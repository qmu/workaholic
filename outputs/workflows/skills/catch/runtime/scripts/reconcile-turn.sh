#!/bin/sh -eu
# Reconcile one native-loop turn before cadence resumes.
# Usage: reconcile-turn.sh --input <facts.json>
# Pure reader: it chooses owners; the native parent performs the returned actions.

INPUT=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    --input) INPUT=${2:-}; shift 2 ;;
    *) printf '{"ok":false,"reason":"unknown_argument"}\n'; exit 2 ;;
  esac
done
[ -n "$INPUT" ] && [ -s "$INPUT" ] || {
  printf '{"ok":false,"reason":"input_required"}\n'; exit 2
}

jq -e '
  type == "object" and
  (.receipts | type == "array") and
  (.claims | type == "array") and
  (.needs_agent | type == "array") and
  (.answered_handoffs | type == "array")
' "$INPUT" >/dev/null 2>&1 || {
  printf '{"ok":false,"reason":"invalid_facts"}\n'; exit 2
}

jq -c '
  def live: .state == "reserved" or .state == "launching" or .state == "running" or .state == "unknown";
  def tickets: (.target.tickets // []);
  def overlaps($a; $b): any($a[]; . as $x | $b | index($x));
  . as $in |
  [ .receipts[] | select(live) ] as $live |
  [ .claims[] |
    . as $claim |
    ($live | map(select(overlaps(tickets; ($claim.tickets // []))))) as $owners |
    if ($claim.awaiting_person // false) and
       (($in.answered_handoffs | index($claim.unit)) == null) then
      {unit:$claim.unit, action:"wait_for_person", owner:null,
       reason:"unanswered_handoff"}
    elif ($owners | length) > 0 then
      ($owners | sort_by(.reserved_at, .id) | .[0]) as $owner |
      {unit:$claim.unit, action:"adopt", owner:$owner.id,
       worktree:($claim.worktree // null), branch:($claim.branch // null),
       losers:[$owners[1:][]?.id], reason:"live_owner"}
    else
      {unit:$claim.unit, action:"dispatch", owner:null,
       worktree:($claim.worktree // null), branch:($claim.branch // null),
       losers:[], reason:"unowned_claim"}
    end
  ] as $claims |
  [ .needs_agent[] |
    . as $need |
    ($live | map(select(.role == ($need.role // "moderate"))) | sort_by(.reserved_at, .id) | .[0]) as $owner |
    if $owner != null then
      {key:$need.key, action:"dispatch_to_live", owner:$owner.id, receipt:null}
    else
      {key:$need.key, action:"follow_up_receipt", owner:null,
       receipt:("follow-up:" + $need.key)}
    end
  ] as $actions |
  {ok:true, reason:"", claims:$claims, actions:$actions,
   unowned_actions:[$actions[] | select(.action != "dispatch_to_live" and (.receipt == null))],
   cadence_ready:(([$claims[] | select(.action == "dispatch")] | length) == 0 and
                  ([$actions[] | select(.owner == null and .receipt == null)] | length) == 0)}
' "$INPUT"
