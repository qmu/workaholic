#!/bin/sh -eu
# Read one provider-side Slack delta through a live QFS description and persist
# the returned messages before exposing observation evidence to the planner.
#
# The DECLARED binding is the startup authority (`read-declared-binding.sh`); the
# environment variables are the fallback for a repository that declares nothing. Nothing is
# read from Slack until the declared destination and identity have been described and
# resolved — a describe that failed is a named refusal, never an empty channel.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "${1:-}" = --root ] && [ -n "${2:-}" ] || runtime_usage "usage: observe-channel.sh --root REPO [--now ISO]"
ROOT=$2; shift 2; NOW=""
while [ $# -gt 0 ]; do case "$1" in --now) NOW=${2:-}; shift 2;; *) runtime_usage "invalid observe-channel argument";; esac; done
[ -n "$NOW" ] || NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

empty() { runtime_json_result ok "$1" observe-channel "$(jq -cn --arg reason "$1" '{observation_proved:false,new_input_ids:[],known_thread_changes:[],has_more:null,unreadable:[$reason]}')"; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM

# ---- The declared binding decides where this reads --------------------------------------
declaration=$(sh "$SCRIPT_DIR/read-declared-binding.sh" --root "$ROOT" 2>/dev/null || printf '')
printf '%s' "$declaration" | jq -e . >/dev/null 2>&1 || declaration='{"ok":true,"declared":false,"binding":{},"conflicts":[],"declared_digest":null}'
if [ "$(printf '%s' "$declaration" | jq -r '.reason // ""')" = contradictory_declaration ]; then
  # Two instruction files naming two destinations is not a destination. Reading one of them
  # would be a guess, and a guess here is an hour of intake against a channel nobody meant.
  empty binding_contradictory; exit 0
fi
[ "$(printf '%s' "$declaration" | jq -r '.ok')" = true ] || { empty "binding_unreadable:$(printf '%s' "$declaration" | jq -r '.reason')"; exit 0; }

CHANNEL=$(printf '%s' "$declaration" | jq -r '.binding.channel // empty')
[ -n "$CHANNEL" ] || CHANNEL=${WORKAHOLIC_INBOUND_SLACK_CHANNEL:-$(basename "$ROOT")}
WORKSPACE=$(printf '%s' "$declaration" | jq -r '.binding.workspace // empty')
[ -n "$WORKSPACE" ] || WORKSPACE=${WORKAHOLIC_SLACK_WORKSPACE:-qmu}
MOUNT=$(printf '%s' "$declaration" | jq -r '.binding.mount // empty')
ACCOUNT=$(printf '%s' "$declaration" | jq -r '.binding.account // empty')
BOT=$(printf '%s' "$declaration" | jq -r '.binding.sender_id // empty')
[ -n "$BOT" ] || BOT=${WORKAHOLIC_SLACK_BOT_USER_ID:-}
DIGEST=$(printf '%s' "$declaration" | jq -c '.declared_digest')
REQUIRED=$(printf '%s' "$declaration" | jq -c 'if ((.binding.operations // []) | length) > 0 then .binding.operations else ["read_channel_delta"] end')

# ---- Describe the DECLARED route, never the literal `/slack` path ------------------------
set -- --workspace "$WORKSPACE" --channel "$CHANNEL"
if [ -n "$MOUNT" ]; then set -- "$@" --mount "$MOUNT"; fi
if [ -n "$ACCOUNT" ]; then set -- "$@" --account "$ACCOUNT"; fi
if [ -n "$BOT" ]; then set -- "$@" --sender-id "$BOT"; fi
describe=$(sh "$SCRIPT_DIR/describe-qfs.sh" "$@" 2>/dev/null || printf '')
printf '%s' "$describe" | jq -e . >/dev/null 2>&1 || { empty describe_unreadable; exit 0; }
[ "$(printf '%s' "$describe" | jq -r .ok)" = true ] || { empty "$(printf '%s' "$describe" | jq -r .reason)"; exit 0; }
observations=$(printf '%s' "$describe" | jq -c '.observations')
DESCRIBE_CALLS=$(printf '%s' "$describe" | jq -c '.calls // 1')

jq -cn --arg root "$ROOT" --arg workspace "$WORKSPACE" --arg channel "$CHANNEL" --arg sender "$BOT" \
  --arg mount "$MOUNT" --arg account "$ACCOUNT" --argjson required "$REQUIRED" \
  --argjson digest "$DIGEST" --argjson observations "$observations" '
  {protocol:"workaholic.transport/v1",request_id:"loop-observe-resolve",operation:"discover",
   repo_root:$root,instance_id:"loop-observer",
   input:{declared_digest:$digest,
          target:({workspace:$workspace,channel:$channel,operations:$required}
                  + (if $sender=="" then {} else {sender_id:$sender} end)
                  + (if $mount=="" then {} else {mount:$mount} end)
                  + (if $account=="" then {} else {account:$account} end)),
          observations:$observations}}' >"$tmp/resolve.json"
resolved=$("$SCRIPT_DIR/resolve-target.sh" --request "$tmp/resolve.json")
[ "$(printf '%s' "$resolved" | jq -r .status)" = ok ] || { empty "$(printf '%s' "$resolved" | jq -r .reason)"; exit 0; }
binding=$(printf '%s' "$resolved" | jq -c .data.binding); binding_id=$(printf '%s' "$resolved" | jq -r .data.binding_id)
STATE="$SCRIPT_DIR/../../runtime/scripts/state.sh"; call() { (cd "$ROOT" && "$STATE" "$@"); }
meta=$(call read --scope binding --id "$binding_id")
if [ "$(printf '%s' "$meta" | jq -r .data.found)" != true ]; then
  jq -cn --arg now "$NOW" --argjson target "$binding" '{updated_at:$now,owner:null,data:{lease_status:"released",target:$target,cursor:null}}' >"$tmp/meta.json"
  call create --scope binding --id "$binding_id" --input "$tmp/meta.json" >/dev/null
  meta=$(call read --scope binding --id "$binding_id")
fi
cursor=$(printf '%s' "$meta" | jq -c '.data.record.data.cursor // null')
jq -cn --arg root "$ROOT" --arg bid "$binding_id" --argjson binding "$binding" --argjson cursor "$cursor" '{protocol:"workaholic.transport/v1",request_id:"loop-observe-read",operation:"read_channel_delta",repo_root:$root,instance_id:"loop-observer",binding_id:$bid,input:{binding:$binding,cursor:$cursor,overlap_seconds:300}}' >"$tmp/read.json"
read_result=$("$SCRIPT_DIR/perform.sh" --request "$tmp/read.json")
[ "$(printf '%s' "$read_result" | jq -r .status)" = ok ] || { empty "$(printf '%s' "$read_result" | jq -r .reason)"; exit 0; }
next=$(printf '%s' "$read_result" | jq -c --argjson old "$cursor" '.data.next_cursor // ([.data.messages[]?.ts] | max) // $old')
jq -cn --arg root "$ROOT" --arg bid "$binding_id" --arg now "$NOW" --argjson messages "$(printf '%s' "$read_result" | jq -c .data.messages)" --argjson next "$next" '{repo_root:$root,binding_id:$bid,now:$now,messages:$messages,next_cursor:$next}' >"$tmp/capture.json"
captured=$("$SCRIPT_DIR/capture-inbox.sh" --request "$tmp/capture.json")
[ "$(printf '%s' "$captured" | jq -r .status)" = ok ] || { empty "$(printf '%s' "$captured" | jq -r .reason)"; exit 0; }
new_ids=$(printf '%s' "$captured" | jq -c '.data.new_input_ids // []')

# ---- Thread discovery -------------------------------------------------------------------
# A reply under an OLDER root never appears in the channel delta — Slack's channel history
# does not carry it — so a thread the loop already knew about is not the question. Ask the
# provider which THREADS changed, by their own coordinates, inside the same bounded overlap
# window, then read each changed thread whole before anything classifies a reply in it.
FANOUT=${WORKAHOLIC_THREAD_FANOUT:-5}
case "$FANOUT" in ''|*[!0-9]*) FANOUT=5 ;; esac
THREAD_CALLS=0
THREAD_STATUS=partial
THREAD_REASON=thread_discovery_not_attempted
THREAD_TRUNCATED=false
: >"$tmp/replies"
jq -cn --arg root "$ROOT" --arg bid "$binding_id" --argjson binding "$binding" --argjson cursor "$cursor" --argjson limit "$FANOUT" \
  '{protocol:"workaholic.transport/v1",request_id:"loop-observe-threads",operation:"list_thread_changes",repo_root:$root,instance_id:"loop-observer",binding_id:$bid,input:{binding:$binding,cursor:$cursor,overlap_seconds:300,limit:$limit}}' >"$tmp/threads.json"
threads_result=$("$SCRIPT_DIR/perform.sh" --request "$tmp/threads.json" 2>/dev/null || printf '')
THREAD_CALLS=$((THREAD_CALLS + 1))
if ! printf '%s' "$threads_result" | jq -e '.status == "ok"' >/dev/null 2>&1; then
  # The discovery operation is unavailable or refused. Coverage stays PARTIAL and says why:
  # reporting it as covered is the claim this whole path exists to stop making.
  THREAD_REASON=$(printf '%s' "$threads_result" | jq -r '.reason // "thread_discovery_unreadable"' 2>/dev/null || printf thread_discovery_unreadable)
  [ -n "$THREAD_REASON" ] || THREAD_REASON=thread_discovery_unreadable
else
  changed=$(printf '%s' "$threads_result" | jq -c '[.data.threads[]?.thread_ts] | unique')
  total=$(printf '%s' "$changed" | jq 'length')
  [ "$total" -le "$FANOUT" ] || THREAD_TRUNCATED=true
  printf '%s' "$changed" | jq -r --argjson limit "$FANOUT" '.[0:$limit][]' >"$tmp/changed"
  read_failed=""
  while IFS= read -r thread_ts; do
    [ -n "$thread_ts" ] || continue
    jq -cn --arg root "$ROOT" --arg bid "$binding_id" --arg thread "$thread_ts" --argjson binding "$binding" \
      '{protocol:"workaholic.transport/v1",request_id:"loop-observe-thread",operation:"read_thread",repo_root:$root,instance_id:"loop-observer",binding_id:$bid,input:{binding:$binding,thread_ts:$thread}}' >"$tmp/thread-read.json"
    thread_read=$("$SCRIPT_DIR/perform.sh" --request "$tmp/thread-read.json" 2>/dev/null || printf '')
    THREAD_CALLS=$((THREAD_CALLS + 1))
    if ! printf '%s' "$thread_read" | jq -e '.status == "ok"' >/dev/null 2>&1; then
      read_failed=$(printf '%s' "$thread_read" | jq -r '.reason // "thread_unreadable"' 2>/dev/null || printf thread_unreadable)
      continue
    fi
    messages=$(printf '%s' "$thread_read" | jq -c '.data.messages // []')
    # The CHANNEL cursor governs and was already advanced by the channel capture; a thread
    # capture must carry it forward unchanged rather than write the pre-advance value back.
    jq -cn --arg root "$ROOT" --arg bid "$binding_id" --arg now "$NOW" --argjson messages "$messages" --argjson next "$next" \
      '{repo_root:$root,binding_id:$bid,now:$now,messages:$messages,next_cursor:$next}' >"$tmp/thread-capture.json"
    thread_captured=$("$SCRIPT_DIR/capture-inbox.sh" --request "$tmp/thread-capture.json" 2>/dev/null || printf '')
    THREAD_CALLS=$((THREAD_CALLS + 1))
    if ! printf '%s' "$thread_captured" | jq -e '.status == "ok"' >/dev/null 2>&1; then
      read_failed=$(printf '%s' "$thread_captured" | jq -r '.reason // "thread_capture_failed"' 2>/dev/null || printf thread_capture_failed)
      continue
    fi
    # THE WHOLE THREAD IS READ BEFORE ANYTHING IS CLASSIFIED. What a reply is depends on what
    # it is a reply TO: under the loop's own `🙋` it is a person answering a question the loop
    # asked, under another of its shapes it is a person answering the loop, and under a human
    # root it is a message a human must be read for. The shape test is mechanical; the last
    # class is deliberately handed to the agent rather than guessed here.
    printf '%s' "$thread_read" | jq -c \
      --arg bot "$BOT" --arg thread "$thread_ts" \
      --argjson new "$(printf '%s' "$thread_captured" | jq -c '.data.new_input_ids // []')" '
      (.data.messages // []) as $all |
      (([$all[] | select(((.ts // .id) == $thread))] | first) // ($all[0] // {})) as $root |
      (($root.text // "") | ltrimstr(" ")) as $root_text |
      (if ($root_text | startswith("🙋")) then "🙋"
       elif ($root_text | startswith("📝 FB")) then "📝 FB"
       elif ($root_text | startswith("🔎 Moderation")) then "🔎 Moderation"
       elif ($root_text | startswith("🔵 Proposed")) then "🔵 Proposed"
       elif ($root_text | startswith("🟢 Implemented")) then "🟢 Implemented"
       elif ($root_text | startswith("🟡 Handoff")) then "🟡 Handoff"
       elif ($root_text | startswith("📥 受理")) then "📥 受理"
       elif ($root_text | startswith("💬")) then "💬"
       else "human_root" end) as $shape |
      [$all[] | . as $m | (.id // .ts) as $id |
        select($id != null and ($new | index($id))) |
        select($id != $thread) |
        select($bot == "" or (($m.sender_id // $m.author_id // $m.user // $m.user_id // "") != $bot)) |
        {id:$id, thread_ts:$thread, ts:($m.ts // $id), sender_id:($m.sender_id // null),
         root_shape:$shape,
         route:(if (($m.text // "") | length) == 0 then "reaction_only"
                elif $shape == "🙋" then "moderation_answer"
                elif $shape == "human_root" then "needs_judgement"
                else "answer_to_loop" end)}] | .[]' >>"$tmp/replies" 2>/dev/null || read_failed=reply_unclassifiable
  done <"$tmp/changed"
  if [ -n "$read_failed" ]; then THREAD_STATUS=partial; THREAD_REASON=$read_failed
  else THREAD_STATUS=covered; THREAD_REASON=""; fi
fi
THREAD_REPLIES=$(jq -sc '.' "$tmp/replies" 2>/dev/null || printf '[]')
data=$(printf '%s' "$read_result" | jq -c --arg bot "$BOT" --argjson new "$new_ids" --argjson binding "$binding" \
  --argjson describe_calls "$DESCRIBE_CALLS" --argjson thread_calls "$THREAD_CALLS" \
  --arg thread_status "$THREAD_STATUS" --arg thread_reason "$THREAD_REASON" \
  --argjson thread_truncated "$THREAD_TRUNCATED" --argjson thread_replies "$THREAD_REPLIES" '
  [.data.messages[]? | . as $m | (.id // .ts) as $id | select($id != null and ($new|index($id))) |
    select($bot=="" or (($m.sender_id // $m.author_id // $m.user // $m.user_id // "") != $bot))] as $fresh |
  {observation_proved:true,
   binding:{workspace:$binding.workspace,channel:$binding.channel,channel_id:$binding.channel_id,
            mount:$binding.mount,sender_id:$binding.sender_id,
            channel_verified:$binding.channel_verified,sender_verified:$binding.sender_verified,
            declared_digest:$binding.declared_digest},
   new_input_ids:[$fresh[]|(.id // .ts)]|unique,
   known_thread_changes:[$fresh[]|select((.thread_ts//"")!="")|{id:(.id//.ts),thread_ts,ts:(.ts//.id),sender_id:(.sender_id//null)}]|unique_by(.id),
   mentions:[$fresh[]|select($bot!="" and ((.text//"")|contains("<@"+$bot+">")))|{id:(.id//.ts),thread_ts:(.thread_ts//null),ts:(.ts//.id)}]|unique_by(.id),
   thread_replies:$thread_replies,
   coverage:({top_level:{status:"covered",source:"read_channel_delta"},
     # `covered` here means the DISCOVERY OPERATION ran and could return replies whose
     # coordinates were not already known. Anything less is `partial` with its reason: a
     # channel delta that happens to carry a broadcast reply is not thread coverage.
     threads:({status:$thread_status,source:"list_thread_changes",discovered:($thread_status == "covered"),truncated:$thread_truncated}
              + (if $thread_reason == "" then {} else {reason:$thread_reason} end)),
     mentions:(if $bot=="" then {status:"unreadable",reason:"sender_identity_unverified"} else {status:"covered_in_channel_delta",source:"message_text"} end)}
     | . + {complete:(.top_level.status == "covered" and .threads.status == "covered" and .mentions.status != "unreadable" and ($thread_truncated | not))}),
   calls:{describe:$describe_calls,read_channel_delta:1,capture:1,threads:$thread_calls,total:($describe_calls + 2 + $thread_calls)},
   has_more:(.data.has_more//false),
   unreadable:(([if $bot=="" then "sender_identity_unverified" else empty end]
                + [if ($binding.channel_verified//false) then empty else "channel_membership_unverified" end]
                + [if $thread_reason == "" then empty else $thread_reason end])),
   next_cursor:.data.next_cursor}')
runtime_json_result ok "" observe-channel "$data"
