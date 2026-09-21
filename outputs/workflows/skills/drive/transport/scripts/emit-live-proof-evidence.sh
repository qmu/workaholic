#!/bin/sh -eu
# Emit the per-operation evidence document `verify-live-proof.sh` consumes. Pure read.
#
#   emit-live-proof-evidence.sh --root REPO [--out FILE]
#
# WHY THIS EXISTS. The incident gate had a reader and no writer: `verify-live-proof.sh` refuses
# closure unless an evidence document proves every declared operation, the sender and one
# root/reply/reaction round trip, and nothing in the tree produced such a document. The shape was
# therefore readable only out of that script's own jq program, so the operator's remaining act was
# "save the typed evidence" into a format nobody had written down — which is how a gate ends up
# satisfied by a hand-made file nobody can check. This writes the template, pre-filled with every
# fact the repository can establish on its own, and leaves exactly the facts a credential is
# needed for empty.
#
# WHAT IT WILL NOT DO — and this is the whole point of it existing separately from the gate:
#
#   * It NEVER writes `proved: true` for any operation. A route that ADVERTISES an operation has
#     a capability; the gate asks whether the operation was PERFORMED. Reading the first as the
#     second is `operations_unsatisfied` dressed as delivery, which the ticket's own gate forbids
#     by name. `available` carries the capability reading and `proved` stays false until a live
#     act filled it in.
#   * An unreadable describe answers `available: null`, never `false`. `false` means the route
#     answered and does not carry the operation; `null` means nobody could look, and an absence
#     of a reading is never a verdict (the rule this repository applies to `unanswerable`).
#   * It performs no Slack read or write, needs no credential, and decides nothing.
#     `verify-live-proof.sh` remains the one gate over what this emits.
#
# Output (one JSON line on stdout; the document itself goes to --out, or to stdout's `evidence`
# key when no --out was given):
#   {"ok":true,"emitted":true,"out":"…","declared_digest":"…","route_readable":true,
#    "sender_declared":false,"proved_operations":0,"unavailable_operations":[…],"reason":""}
#
# Typed refusals, each its own word, nothing written:
#   `root_required`        no --root was given
#   `binding_unreadable`   the declaration could not be read (`reason` carries the reader's word)
#   `not_declared`         the repository declares no binding; there is nothing to prove against
#   `jq_unavailable`       the reading cannot be made at all

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ROOT='' OUT=''
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=${2:-}; shift 2 ;;
    --out) OUT=${2:-}; shift 2 ;;
    *) printf '{"ok":false,"emitted":false,"reason":"invalid_argument"}\n'; exit 2 ;;
  esac
done
[ -n "$ROOT" ] || { printf '{"ok":false,"emitted":false,"reason":"root_required"}\n'; exit 2; }
command -v jq >/dev/null 2>&1 \
  || { printf '{"ok":false,"emitted":false,"reason":"jq_unavailable"}\n'; exit 0; }

decl=$(sh "$SCRIPT_DIR/read-declared-binding.sh" --root "$ROOT" 2>/dev/null || true)
printf '%s' "$decl" | jq -e '.ok == true' >/dev/null 2>&1 || {
  reason=$(printf '%s' "$decl" | jq -r '.reason // "unreadable"' 2>/dev/null || echo unreadable)
  jq -cn --arg r "$reason" \
    '{ok:false,emitted:false,reason:"binding_unreadable",detail:$r}'
  exit 0
}
printf '%s' "$decl" | jq -e '.declared == true' >/dev/null 2>&1 \
  || { printf '{"ok":false,"emitted":false,"reason":"not_declared"}\n'; exit 0; }

digest=$(printf '%s' "$decl" | jq -r '.declared_digest')
workspace=$(printf '%s' "$decl" | jq -r '.binding.workspace // ""')
channel=$(printf '%s' "$decl" | jq -r '.binding.channel // ""')
mount=$(printf '%s' "$decl" | jq -r '.binding.mount // ""')
account=$(printf '%s' "$decl" | jq -r '.binding.account // ""')
sender=$(printf '%s' "$decl" | jq -r '.binding.sender_id // ""')
required=$(printf '%s' "$decl" | jq -c '.binding.operations // []')

# The route reading is evidence about capability and never about a performed act. A describe that
# could not be made leaves every `available` null rather than false.
set -- --workspace "$workspace" --channel "$channel"
[ -n "$mount" ] && set -- "$@" --mount "$mount"
[ -n "$account" ] && set -- "$@" --account "$account"
[ -n "$sender" ] && set -- "$@" --sender-id "$sender"
desc=$(sh "$SCRIPT_DIR/describe-qfs.sh" "$@" 2>/dev/null || true)
printf '%s' "$desc" | jq -e '.ok == true and .described == true' >/dev/null 2>&1 \
  || desc=''

doc=$(jq -cn \
  --arg digest "$digest" --arg workspace "$workspace" --arg channel "$channel" \
  --arg sender "$sender" --arg mount "$mount" \
  --argjson required "$required" \
  --argjson desc "${desc:-null}" '
  ($desc.observations // []) as $obs |
  (if $mount != "" then ($obs[] | select(.mount == $mount)) else $obs[0] end) as $route |
  {
    declared_digest: $digest,
    workspace: $workspace,
    channel: $channel,
    sender_id: $sender,
    operations: (reduce $required[] as $op ({}; .[$op] = {
      proved: false,
      available: (if $desc == null then null
                  elif $route == null then null
                  else (($route.operations // []) | index($op)) != null end),
      reason: (if $desc == null or $route == null then "route_unreadable"
               elif (($route.operations // []) | index($op)) == null
               then "route_does_not_advertise"
               else "not_performed" end)
    })),
    round_trip: {root_ts: "", reply_ts: "", reaction_seen: false,
                 channel_delta_seen: false, thread_change_seen: false,
                 thread_reply_seen: false},
    route: (if $route == null then null else {
      mount: $route.mount, account: $route.account,
      channel_id: $route.channel_id,
      channel_verified: $route.channel_verified,
      sender_verified: $route.sender_verified,
      limitations: ($route.limitations // [])
    } end)
  }')

if [ -n "$OUT" ]; then
  printf '%s\n' "$doc" > "$OUT"
fi

printf '%s' "$doc" | jq -c \
  --arg out "$OUT" --argjson embed "$( [ -n "$OUT" ] && echo false || echo true )" '
  {ok: true, emitted: true, out: $out,
   declared_digest: .declared_digest,
   route_readable: (.route != null),
   sender_declared: (.sender_id != ""),
   proved_operations: 0,
   unavailable_operations: [.operations | to_entries[]
     | select(.value.available != true) | .key],
   evidence: (if $embed then . else null end),
   reason: ""}'
