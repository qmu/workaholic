#!/bin/sh -eu
# Read one provider-side Slack delta through a live QFS description and persist
# the returned messages before exposing observation evidence to the planner.
#
# The DECLARED binding is the startup authority (`read-declared-binding.sh`); the
# environment variables are the fallback for a repository that declares nothing. Nothing is
# read from Slack until the declared destination and identity have been described and
# resolved — a describe that failed is a named refusal, never an empty channel.
#
# The delta is drained to its end inside one call (`WORKAHOLIC_CHANNEL_PAGES`), every root and
# explicit permalink it names is remembered in a durable, bounded watch set, that set is what the
# thread-discovery fallback reads when `list_thread_changes` refuses, and `observation_settled`
# is the one derivation of whether this read may be reported as the channel having nothing new.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "${1:-}" = --root ] && [ -n "${2:-}" ] || runtime_usage "usage: observe-channel.sh --root REPO [--now ISO]"
ROOT=$2; shift 2; NOW=""
while [ $# -gt 0 ]; do case "$1" in --now) NOW=${2:-}; shift 2;; *) runtime_usage "invalid observe-channel argument";; esac; done
[ -n "$NOW" ] || NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NOW_EPOCH=$(date -u -d "$NOW" +%s 2>/dev/null || date -u +%s)
case "$NOW_EPOCH" in ''|*[!0-9]*) NOW_EPOCH=$(date -u +%s) ;; esac

# An unproved observation is UNREAD, never quiet (2026-09-11, issue #1151): it advances no
# cursor, and `unproved_since` is written onto the binding record beside the cursor -- the
# stored cursor, or this read's own time when none exists -- so the next proved read can
# overlap the whole interval that was never read and a report can say since when. `empty`
# takes the value that stood (or was just written) so the refusal carries it; a refusal
# before the binding is resolved carries null, because no record can be addressed yet, and
# every binding's cursor is untouched by it anyway.
empty() {
  runtime_json_result ok "$1" observe-channel "$(jq -cn --arg reason "$1" --argjson since "${2:-null}" \
    '{observation_proved:false,new_input_ids:[],known_thread_changes:[],has_more:null,unreadable:[$reason],unproved_since:$since,cursor_advanced:false,observation_settled:false,unsettled:[$reason]}')"
}

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
unproved_since=$(printf '%s' "$meta" | jq -c '.data.record.data.unproved_since // null')

# ---- The unproved interval is overlapped, never skipped -----------------------------------
# `overlap_seconds` is the greater of the standing 300 and `now - unproved_since`, so a read
# after an outage re-reads the whole interval once (bounded by the provider's page; `has_more`
# carries the same `since` forward). `window_since` is the numeric lower bound this read
# actually asked for, handed to the capture so it can clear the mark only when the proved
# window reached it.
OVERLAP=300
if [ "$unproved_since" != null ]; then
  OVERLAP=$(awk -v now="$NOW_EPOCH" -v since="$unproved_since" 'BEGIN { span = now - since; if (span < 300) span = 300; printf "%d", span }')
fi
window_since=null
if [ "$cursor" != null ]; then
  window_since=$(awk -v cursor="$(printf '%s' "$cursor" | jq -r .)" -v overlap="$OVERLAP" 'BEGIN { value = cursor - overlap; if (value < 0) value = 0; printf "%.6f", value }')
fi

# Write `unproved_since` once, keeping an earlier value; never the cursor. A failed mark is
# named in the refusal rather than hidden, and a refusal writes nothing else.
mark_unproved() {
  _mu_meta=$(call read --scope binding --id "$binding_id")
  _mu_since=$(printf '%s' "$_mu_meta" | jq -c '.data.record.data.unproved_since // null')
  if [ "$_mu_since" != null ]; then printf '%s' "$_mu_since"; return 0; fi
  if [ "$cursor" != null ]; then _mu_since=$(printf '%s' "$cursor" | jq -r .); else _mu_since=$NOW_EPOCH; fi
  _mu_rev=$(printf '%s' "$_mu_meta" | jq -r '.data.record.revision')
  printf '%s' "$_mu_meta" | jq -c --arg now "$NOW" --argjson since "$_mu_since" \
    '{updated_at:$now,data:(.data.record.data + {unproved_since:$since})}' >"$tmp/mark.json"
  _mu_written=$(call update --scope binding --id "$binding_id" --expected-revision "$_mu_rev" --input "$tmp/mark.json" 2>/dev/null || printf '{"status":"error"}')
  if [ "$(printf '%s' "$_mu_written" | jq -r .status)" = ok ]; then printf '%s' "$_mu_since"; else printf 'null'; fi
}

# ---- The channel delta is consumed to its END, boundedly ---------------------------------
# `has_more: true` used to be REPORTED and then left: one page was read, the planner shortened
# its interval, and the rest of the page waited for the next tick to come round. A tick that
# reads part of a page and calls the remainder "later" is one whose coverage claim is false for
# exactly as long as the channel is busy, so the delta is now drained here.
#
# Each page is CAPTURED before the next is asked for -- the capture is the cursor-advancing
# seam, so page N+1's lower bound is page N's own advanced cursor, asked with
# `overlap_seconds: 0` because the overlap exists to re-cover an interval nobody read and this
# one was just read. The boundary message comes back twice by construction and the capture's
# provider-id key drops it, which is the same dedup every other path relies on.
#
# `window_since` rides the FIRST page only: it is the mark-clearing term, the capture is its one
# writer, and a later page whose lower bound is the advanced cursor must not be allowed to claim
# it reached an interval it never asked for.
#
# The bound is a PAGE BUDGET (`WORKAHOLIC_CHANNEL_PAGES`, default 5), never a time. A budget
# exhausted leaves `has_more: true` standing with its own reason, so the planner re-polls at once
# and the reading never says the channel was drained when it was cut.
PAGES=${WORKAHOLIC_CHANNEL_PAGES:-5}
case "$PAGES" in ''|*[!0-9]*|0) PAGES=5 ;; esac
page=0; CHANNEL_READS=0; CHANNEL_CAPTURES=0; PAGES_READ=0
FRESH='[]'; HAS_MORE=false; PAGE_REASON=''; COVERED_UNPROVED=null
page_cursor=$cursor; page_overlap=$OVERLAP; next=$cursor
while :; do
  page=$((page + 1))
  jq -cn --arg root "$ROOT" --arg bid "$binding_id" --argjson binding "$binding" \
    --argjson cursor "$page_cursor" --argjson overlap "$page_overlap" \
    '{protocol:"workaholic.transport/v1",request_id:"loop-observe-read",operation:"read_channel_delta",repo_root:$root,instance_id:"loop-observer",binding_id:$bid,input:{binding:$binding,cursor:$cursor,overlap_seconds:$overlap}}' >"$tmp/read.json"
  read_result=$("$SCRIPT_DIR/perform.sh" --request "$tmp/read.json")
  CHANNEL_READS=$((CHANNEL_READS + 1))
  if [ "$(printf '%s' "$read_result" | jq -r .status)" != ok ]; then
    # Page 1 IS the whole reading: nothing was proved, so the observation is unread and the
    # cursor stays retryable. A LATER page's failure is different in kind -- the pages before it
    # were captured and the cursor advanced, so the read is proved and only the TAIL is unread.
    if [ "$page" -eq 1 ]; then empty "$(printf '%s' "$read_result" | jq -r .reason)" "$(mark_unproved)"; exit 0; fi
    PAGE_REASON=$(printf '%s' "$read_result" | jq -r '.reason // "channel_page_unreadable"')
    [ -n "$PAGE_REASON" ] || PAGE_REASON=channel_page_unreadable
    HAS_MORE=true; break
  fi
  page_messages=$(printf '%s' "$read_result" | jq -c '.data.messages // []')
  next=$(printf '%s' "$read_result" | jq -c --argjson old "$page_cursor" '.data.next_cursor // ([.data.messages[]?.ts] | max) // $old')
  if [ "$page" -eq 1 ]; then
    jq -cn --arg root "$ROOT" --arg bid "$binding_id" --arg now "$NOW" --argjson messages "$page_messages" --argjson next "$next" --argjson window "$window_since" '{repo_root:$root,binding_id:$bid,now:$now,messages:$messages,next_cursor:$next,window_since:$window}' >"$tmp/capture.json"
  else
    jq -cn --arg root "$ROOT" --arg bid "$binding_id" --arg now "$NOW" --argjson messages "$page_messages" --argjson next "$next" '{repo_root:$root,binding_id:$bid,now:$now,messages:$messages,next_cursor:$next}' >"$tmp/capture.json"
  fi
  captured=$("$SCRIPT_DIR/capture-inbox.sh" --request "$tmp/capture.json" 2>/dev/null || printf '')
  CHANNEL_CAPTURES=$((CHANNEL_CAPTURES + 1))
  if ! printf '%s' "$captured" | jq -e '.status == "ok"' >/dev/null 2>&1; then
    # Capture is the cursor-advancing seam. Its typed refusal must survive as the observation's
    # own reason; malformed or empty output is itself a named refusal, never an empty unreadable
    # entry. On page 1 `empty` keeps observation_proved false and leaves the cursor retryable; on
    # a later page the pages already captured stand and the tail is named unread.
    capture_reason=$(printf '%s' "$captured" | jq -r '.reason // empty' 2>/dev/null || printf '')
    [ -n "$capture_reason" ] || capture_reason=capture_unreadable
    if [ "$page" -eq 1 ]; then empty "$capture_reason" "$(mark_unproved)"; exit 0; fi
    PAGE_REASON=$capture_reason; HAS_MORE=true; break
  fi
  PAGES_READ=$page
  page_new=$(printf '%s' "$captured" | jq -c '.data.new_input_ids // []')
  # `new_input_ids` is derived from FRESH and never from the capture's own list: the capture
  # persists every message it was handed, the loop's own posts included, and the observation's
  # `new_input_ids` has always meant *new HUMAN input*. Reading the capture's list directly
  # would put the loop's own root in the channel's new input on the tick it posted it.
  FRESH=$(printf '%s' "$page_messages" | jq -c --argjson prior "$FRESH" --arg bot "$BOT" --argjson new "$page_new" '
    $prior + [.[]? | . as $m | (.id // .ts) as $id | select($id != null and ($new | index($id))) |
      select($bot == "" or (($m.sender_id // $m.author_id // $m.user // $m.user_id // "") != $bot))]
    | unique_by(.id // .ts)')
  [ "$page" -ne 1 ] || COVERED_UNPROVED=$(printf '%s' "$captured" | jq -c '.data.cleared_unproved_since // null')
  HAS_MORE=$(printf '%s' "$read_result" | jq -r '.data.has_more // false')
  [ "$HAS_MORE" = true ] || break
  if [ "$page" -ge "$PAGES" ]; then PAGE_REASON=channel_pages_exhausted; break; fi
  # The next page asks from the cursor the capture just advanced to, with NO overlap: the
  # interval below it was read on this very call.
  page_cursor=$next; page_overlap=0
done
new_ids=$(printf '%s' "$FRESH" | jq -c '[.[] | (.id // .ts)] | unique')
covered_unproved=$COVERED_UNPROVED

# ---- A mention outside the read window is DISCOVERED, not waited for ---------------------
# The mention reading was `[fresh[] | select(text contains "<@BOT>")]` and nothing else: a
# mention can therefore only be seen where the channel delta already looked, so a mention on a
# root older than the window -- or in a reply, which channel history never carries at all -- was
# invisible until somebody pasted a link. Nothing registered such a thread either, so even a
# mention that WAS seen got no cadence of its own.
#
# So the channel's own history is searched for the declared sender's mention token, through the
# operation that already exists (`search_exact`) and the one transport seam, ONE call per tick.
# Each coordinate it finds joins the durable watch set, so the ordinary cadence keeps reading it,
# and is read IMMEDIATELY -- bounded by `WORKAHOLIC_MENTION_FANOUT` (default 3) -- because a
# mention is the one discovery that means a person is waiting on an answer.
#
# THE SEARCH CAPTURES NOTHING, deliberately. Capture is per surface -- the channel capture owns
# the delta's rows and the thread capture owns a thread's -- and a capture here would persist the
# mention first, so the thread read that follows would see its own message as a DUPLICATE and the
# classifier, which emits only new ids, would drop the very reply this arm exists to route.
# Measured in the fixture: the mention was discovered and then reported by nobody. Leaving the
# capture to the thread read also means a mention whose thread could not be read stays uncaptured
# and is re-discovered next tick, which is the honest state for something nothing has processed.
#
# WHAT IT IS NOT: proof. The `search_exact` contract says a bounded message table is not a search
# index and zero rows certify nothing, so `coverage.mentions` reports what the arm did
# (`searched`, `discovered`, `tracked`, its refusal reason) and never upgrades to a completeness
# claim. An absent `sender_id` leaves the whole arm unrun -- the existing `unreadable` reading.
MENTION_FANOUT=${WORKAHOLIC_MENTION_FANOUT:-3}
case "$MENTION_FANOUT" in ''|*[!0-9]*) MENTION_FANOUT=3 ;; esac
MENTION_SEARCHED=false; MENTION_REASON=''; MENTION_CALLS=0; MENTION_FOUND='[]'
# An absent sender leaves MENTION_REASON EMPTY on purpose: `sender_identity_unverified` is
# already the first term of `unreadable[]` and the whole of `coverage.mentions`, and naming it
# twice would print one fact twice in the list a reader scans for degradations.
if [ -z "$BOT" ]; then
  :
else
  jq -cn --arg root "$ROOT" --arg bid "$binding_id" --argjson binding "$binding" --arg query "<@$BOT>" \
    '{protocol:"workaholic.transport/v1",request_id:"loop-observe-mentions",operation:"search_exact",repo_root:$root,instance_id:"loop-observer",binding_id:$bid,input:{binding:$binding,query:$query,private_inclusive:true}}' >"$tmp/mentions.json"
  mention_result=$("$SCRIPT_DIR/perform.sh" --request "$tmp/mentions.json" 2>/dev/null || printf '')
  MENTION_CALLS=1
  if printf '%s' "$mention_result" | jq -e '.status == "ok"' >/dev/null 2>&1; then
    MENTION_SEARCHED=true
    MENTION_FOUND=$(printf '%s' "$mention_result" | jq -c --arg bot "$BOT" '
      [ (.data.messages // [])[]? | . as $m | (.id // .ts) as $id |
        select($id != null and (($m.text // "") | contains("<@" + $bot + ">"))) |
        select(($m.sender_id // $m.author_id // $m.user // $m.user_id // "") != $bot) |
        {id:$id, ts:($m.ts // $id), thread_ts:($m.thread_ts // null), sender_id:($m.sender_id // null)} ]
      | unique_by(.id)')
  else
    MENTION_REASON=$(printf '%s' "$mention_result" | jq -r '.reason // "mention_search_unreadable"' 2>/dev/null || printf mention_search_unreadable)
    [ -n "$MENTION_REASON" ] || MENTION_REASON=mention_search_unreadable
  fi
fi

# ---- A discovered root is remembered, so the fallback has something to read ---------------
# A root the channel delta named, and a thread an explicit Slack permalink named, are the two
# ways this loop learns a thread coordinate WITHOUT `list_thread_changes`. Neither survived a
# tick, so while the discovery operation was unavailable the fallback had nothing to read at all
# -- which is how a request under a root discovered five minutes earlier went unanswered for as
# long as the provider kept refusing.
#
# The set is DURABLE (`watch_threads` on the binding record, beside the cursor) and BOUNDED to
# the newest `WORKAHOLIC_WATCH_SET_MAX` (default 50) by the thread's own coordinate, which sorts
# correctly as a number. It is written in ONE revision-checked update after every capture, so
# there is never a second writer inside the capture's own window; a refused write is named
# (`watch_set_unwritten`) and nothing else is touched, because a watch set that was not stored is
# a reading the next tick must not be told it has.
WATCH_MAX=${WORKAHOLIC_WATCH_SET_MAX:-50}
case "$WATCH_MAX" in ''|*[!0-9]*|0) WATCH_MAX=50 ;; esac
watch_stored=$(printf '%s' "$meta" | jq -c '.data.record.data.watch_threads // []')
discovered=$(printf '%s' "$FRESH" | jq -c --argjson mentions "$MENTION_FOUND" '
  [ .[]? | . as $m | (($m.thread_ts // "") | tostring) as $t | (($m.ts // $m.id) | tostring) as $ts |
    if $t == "" or $t == $ts then {thread_ts:$ts, source:"root"} else {thread_ts:$t, source:"reply"} end ]
  + [ .[]? | (.text // "") | scan("/archives/[A-Z0-9]+/p([0-9]{10})([0-9]{6})") | {thread_ts:(.[0] + "." + .[1]), source:"permalink"} ]
  + [ .[]? | (.text // "") | scan("thread_ts=([0-9]{10}\\.[0-9]{6})") | {thread_ts:.[0], source:"permalink"} ]
  # A mention the search found registers its OWN thread, which is the half that was missing: a
  # mention seen once and never registered got no cadence, so the next tick looked past it.
  + [ $mentions[]? | {thread_ts:(((.thread_ts // .ts) | tostring)), source:"mention"} ]
  | map(select(.thread_ts | test("^[0-9]+\\.[0-9]+$"))) | unique_by(.thread_ts)')
# The coordinates this tick must read IMMEDIATELY rather than next tick: a mention is the one
# discovery that means somebody is waiting on an answer.
mention_threads=$(printf '%s' "$MENTION_FOUND" | jq -c --argjson limit "$MENTION_FANOUT" '
  [.[]? | ((.thread_ts // .ts) | tostring)] | map(select(test("^[0-9]+\\.[0-9]+$"))) | unique | .[0:$limit]')
watch_threads=$(jq -cn --argjson stored "$watch_stored" --argjson found "$discovered" --arg now "$NOW" --argjson max "$WATCH_MAX" '
  ([$stored[]? | if type == "object" then . else {thread_ts:(. | tostring), source:"root"} end]
   + [$found[] | . + {discovered_at:$now}])
  | map(select((.thread_ts // "") != "")) | unique_by(.thread_ts)
  | sort_by(.thread_ts | tonumber) | .[-($max):]')
WATCH_WRITTEN=true; WATCH_REASON=''
if [ "$watch_threads" != "$watch_stored" ]; then
  ws_meta=$(call read --scope binding --id "$binding_id")
  ws_rev=$(printf '%s' "$ws_meta" | jq -r '.data.record.revision')
  printf '%s' "$ws_meta" | jq -c --arg now "$NOW" --argjson watch "$watch_threads" \
    '{updated_at:$now,data:(.data.record.data + {watch_threads:$watch})}' >"$tmp/watch.json"
  ws_written=$(call update --scope binding --id "$binding_id" --expected-revision "$ws_rev" --input "$tmp/watch.json" 2>/dev/null || printf '{"status":"error"}')
  [ "$(printf '%s' "$ws_written" | jq -r .status)" = ok ] || { WATCH_WRITTEN=false; WATCH_REASON=watch_set_unwritten; }
fi

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
THREAD_SOURCE=list_thread_changes
THREAD_FALLBACK_READ=0
THREAD_FALLBACK_REASON=''
: >"$tmp/replies"

# THE WHOLE THREAD IS READ BEFORE ANYTHING IS CLASSIFIED. What a reply is depends on what it is
# a reply TO: under the loop's own `🙋` it is a person answering a question the loop asked, under
# another of its shapes it is a person answering the loop, and under a human root it is a message
# a human must be read for. The shape test is mechanical; the last class is deliberately handed
# to the agent rather than guessed here. ONE classifier, so the discovery arm and the watch-set
# fallback below cannot disagree about what a reply is. It prints a reason on failure and nothing
# on success, and the caller reads that -- never an exit status, which a `continue` would eat.
# One thread is read at most ONCE per tick, whichever arm named it. Three arms can name the same
# coordinate -- the discovery, the mention search, and the watch-set fallback -- and reading it
# twice would spend a provider call to produce nothing: the second read's messages are all
# duplicates by the capture's provider-id key, so it can only return an empty reply set.
: >"$tmp/read-threads"
read_and_classify() {
  _rc_thread=$1
  if grep -qxF "$_rc_thread" "$tmp/read-threads" 2>/dev/null; then printf ''; return 0; fi
  printf '%s\n' "$_rc_thread" >>"$tmp/read-threads"
  jq -cn --arg root "$ROOT" --arg bid "$binding_id" --arg thread "$_rc_thread" --argjson binding "$binding" \
    '{protocol:"workaholic.transport/v1",request_id:"loop-observe-thread",operation:"read_thread",repo_root:$root,instance_id:"loop-observer",binding_id:$bid,input:{binding:$binding,thread_ts:$thread}}' >"$tmp/thread-read.json"
  _rc_read=$("$SCRIPT_DIR/perform.sh" --request "$tmp/thread-read.json" 2>/dev/null || printf '')
  THREAD_CALLS=$((THREAD_CALLS + 1))
  if ! printf '%s' "$_rc_read" | jq -e '.status == "ok"' >/dev/null 2>&1; then
    _rc_why=$(printf '%s' "$_rc_read" | jq -r '.reason // "thread_unreadable"' 2>/dev/null || printf thread_unreadable)
    [ -n "$_rc_why" ] || _rc_why=thread_unreadable
    printf '%s' "$_rc_why"; return 0
  fi
  _rc_messages=$(printf '%s' "$_rc_read" | jq -c '.data.messages // []')
  # The CHANNEL cursor governs and was already advanced by the channel capture; a thread
  # capture must carry it forward unchanged rather than write the pre-advance value back.
  jq -cn --arg root "$ROOT" --arg bid "$binding_id" --arg now "$NOW" --argjson messages "$_rc_messages" --argjson next "$next" \
    '{repo_root:$root,binding_id:$bid,now:$now,messages:$messages,next_cursor:$next}' >"$tmp/thread-capture.json"
  _rc_captured=$("$SCRIPT_DIR/capture-inbox.sh" --request "$tmp/thread-capture.json" 2>/dev/null || printf '')
  THREAD_CALLS=$((THREAD_CALLS + 1))
  if ! printf '%s' "$_rc_captured" | jq -e '.status == "ok"' >/dev/null 2>&1; then
    _rc_why=$(printf '%s' "$_rc_captured" | jq -r '.reason // "thread_capture_failed"' 2>/dev/null || printf thread_capture_failed)
    [ -n "$_rc_why" ] || _rc_why=thread_capture_failed
    printf '%s' "$_rc_why"; return 0
  fi
  printf '%s' "$_rc_read" | jq -c \
    --arg bot "$BOT" --arg thread "$_rc_thread" \
    --argjson new "$(printf '%s' "$_rc_captured" | jq -c '.data.new_input_ids // []')" '
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
              else "answer_to_loop" end)}] | .[]' >>"$tmp/replies" 2>/dev/null \
    || { printf reply_unclassifiable; return 0; }
  printf ''
}

# A mention's own thread is read FIRST, before either discovery arm, and its read is what the
# dedup above then lets stand: a mention is the one discovery that means a person is waiting on
# an answer, so it is tracked on the tick that found it rather than on the next one.
MENTION_THREADS_READ=0; MENTION_TRACK_REASON=''
printf '%s' "$mention_threads" | jq -r '.[]' >"$tmp/mention-threads" 2>/dev/null || : >"$tmp/mention-threads"
while IFS= read -r mention_ts; do
  [ -n "$mention_ts" ] || continue
  rc=$(read_and_classify "$mention_ts")
  MENTION_THREADS_READ=$((MENTION_THREADS_READ + 1))
  [ -z "$rc" ] || MENTION_TRACK_REASON=$rc
done <"$tmp/mention-threads"

jq -cn --arg root "$ROOT" --arg bid "$binding_id" --argjson binding "$binding" --argjson cursor "$cursor" --argjson limit "$FANOUT" --argjson overlap "$OVERLAP" \
  '{protocol:"workaholic.transport/v1",request_id:"loop-observe-threads",operation:"list_thread_changes",repo_root:$root,instance_id:"loop-observer",binding_id:$bid,input:{binding:$binding,cursor:$cursor,overlap_seconds:$overlap,limit:$limit}}' >"$tmp/threads.json"
threads_result=$("$SCRIPT_DIR/perform.sh" --request "$tmp/threads.json" 2>/dev/null || printf '')
THREAD_CALLS=$((THREAD_CALLS + 1))
if ! printf '%s' "$threads_result" | jq -e '.status == "ok"' >/dev/null 2>&1; then
  # The discovery operation is unavailable or refused. Coverage stays PARTIAL and says why:
  # reporting it as covered is the claim this whole path exists to stop making.
  THREAD_REASON=$(printf '%s' "$threads_result" | jq -r '.reason // "thread_discovery_unreadable"' 2>/dev/null || printf thread_discovery_unreadable)
  [ -n "$THREAD_REASON" ] || THREAD_REASON=thread_discovery_unreadable
  # AND THE FALLBACK READS WHAT WAS DISCOVERED, never a fixed list. Without the discovery
  # operation the only coordinates this loop holds are the ones it remembered, so each watched
  # thread is read whole through the same one classifier, NEWEST FIRST and bounded by the same
  # fan-out. A fallback is EVIDENCE, never proof of coverage: the status stays `partial` with the
  # discovery's own reason, and `source` says which arm produced the replies.
  THREAD_SOURCE=watch_set_fallback
  printf '%s' "$watch_threads" | jq -r --argjson limit "$FANOUT" 'reverse | .[0:$limit][] | .thread_ts' >"$tmp/watched" 2>/dev/null || : >"$tmp/watched"
  while IFS= read -r watched_ts; do
    [ -n "$watched_ts" ] || continue
    rc=$(read_and_classify "$watched_ts")
    THREAD_FALLBACK_READ=$((THREAD_FALLBACK_READ + 1))
    [ -z "$rc" ] || THREAD_FALLBACK_REASON=$rc
  done <"$tmp/watched"
  # THE FALLBACK'S OWN FAILURE IS ITS OWN TERM. `coverage.threads.reason` answers *why discovery
  # did not run* and must keep doing so; a fallback that also could not read is a second fact, so
  # it rides `fallback_reason` beside it and in `unreadable[]`. Folding the two into one string
  # would send a reader looking for a discovery refusal that never happened.
  [ "$(printf '%s' "$watch_threads" | jq 'length')" -le "$FANOUT" ] || THREAD_TRUNCATED=true
else
  changed=$(printf '%s' "$threads_result" | jq -c '[.data.threads[]?.thread_ts] | unique')
  total=$(printf '%s' "$changed" | jq 'length')
  [ "$total" -le "$FANOUT" ] || THREAD_TRUNCATED=true
  printf '%s' "$changed" | jq -r --argjson limit "$FANOUT" '.[0:$limit][]' >"$tmp/changed"
  read_failed=""
  while IFS= read -r thread_ts; do
    [ -n "$thread_ts" ] || continue
    rc=$(read_and_classify "$thread_ts")
    [ -z "$rc" ] || read_failed=$rc
  done <"$tmp/changed"
  if [ -n "$read_failed" ]; then THREAD_STATUS=partial; THREAD_REASON=$read_failed
  else THREAD_STATUS=covered; THREAD_REASON=""; fi
fi
THREAD_REPLIES=$(jq -sc '.' "$tmp/replies" 2>/dev/null || printf '[]')

# ---- An incomplete observation may not be called quiet ------------------------------------
# `observation_settled` is the ONE derivation of *may this read be reported as the channel having
# nothing new*: false while the delta still holds a page nobody read, while thread coverage is
# anything but `covered`, while the fan-out cut the thread list, or while the account that would
# speak was never proved. `unsettled[]` names every term, so the refusal is arguable rather than
# hidden behind a flag.
#
# It moves the WORD and never the cadence. `has_more` already forces an immediate re-poll, and a
# STANDING limitation (`operation_unavailable` on a route that will never carry the operation)
# would otherwise shorten the interval forever -- a spin, which is a worse failure than the one
# being fixed. What it buys is that `plan-poll.sh` answers `observation_incomplete` rather than
# `quiet`, so nothing is ever told a partly-read channel was silent.
data=$(jq -cn --arg bot "$BOT" --argjson binding "$binding" \
  --argjson new "$new_ids" --argjson fresh "$FRESH" --argjson next "$next" \
  --argjson overlap "$OVERLAP" --argjson window "$window_since" --argjson covered "$covered_unproved" \
  --argjson describe_calls "$DESCRIBE_CALLS" --argjson thread_calls "$THREAD_CALLS" \
  --argjson channel_reads "$CHANNEL_READS" --argjson channel_captures "$CHANNEL_CAPTURES" \
  --argjson pages_read "$PAGES_READ" --arg page_reason "$PAGE_REASON" --argjson has_more "$HAS_MORE" \
  --argjson watch "$watch_threads" --argjson watch_written "$WATCH_WRITTEN" --arg watch_reason "$WATCH_REASON" \
  --argjson fallback_read "$THREAD_FALLBACK_READ" --arg fallback_reason "$THREAD_FALLBACK_REASON" \
  --argjson mention_searched "$MENTION_SEARCHED" --arg mention_reason "$MENTION_REASON" \
  --argjson mention_found "$MENTION_FOUND" --argjson mention_calls "$MENTION_CALLS" \
  --argjson mention_threads_read "$MENTION_THREADS_READ" --arg mention_track_reason "$MENTION_TRACK_REASON" \
  --arg thread_status "$THREAD_STATUS" --arg thread_reason "$THREAD_REASON" --arg thread_source "$THREAD_SOURCE" \
  --argjson thread_truncated "$THREAD_TRUNCATED" --argjson thread_replies "$THREAD_REPLIES" '
  ([if $bot == "" then "sender_identity_unverified" else empty end]
   + [if ($binding.channel_verified // false) then empty else "channel_membership_unverified" end]
   + [if $thread_reason == "" then empty else $thread_reason end]
   + [if $page_reason == "" then empty else $page_reason end]
   + [if $fallback_reason == "" then empty else $fallback_reason end]
   + [if $mention_reason == "" then empty else $mention_reason end]
   + [if $mention_track_reason == "" then empty else $mention_track_reason end]
   + [if $watch_written then empty else $watch_reason end]) as $unreadable |
  ([if $has_more then "channel_delta_incomplete" else empty end]
   + [if $thread_status == "covered" then empty else "thread_coverage_" + $thread_status end]
   + [if $thread_truncated then "thread_fanout_truncated" else empty end]
   + [if $bot == "" then "sender_identity_unverified" else empty end]) as $unsettled |
  {observation_proved:true,
   binding:{workspace:$binding.workspace,channel:$binding.channel,channel_id:$binding.channel_id,
            mount:$binding.mount,sender_id:$binding.sender_id,
            channel_verified:$binding.channel_verified,sender_verified:$binding.sender_verified,
            declared_digest:$binding.declared_digest},
   new_input_ids:$new,
   known_thread_changes:[$fresh[]|select((.thread_ts//"")!="")|{id:(.id//.ts),thread_ts,ts:(.ts//.id),sender_id:(.sender_id//null)}]|unique_by(.id),
   # Both arms answer one list, each entry naming which found it. The delta arm covers the
   # window it read; the search arm is the only one that can reach outside it.
   mentions:(([$fresh[]|select($bot!="" and ((.text//"")|contains("<@"+$bot+">")))|{id:(.id//.ts),thread_ts:(.thread_ts//null),ts:(.ts//.id),source:"channel_delta"}]
              + [$mention_found[]|{id,thread_ts,ts,source:"mention_search"}]) | unique_by(.id)),
   thread_replies:$thread_replies,
   watch_set:{count:($watch|length),written:$watch_written,threads:[$watch[].thread_ts],fallback_read:$fallback_read},
   coverage:({top_level:({status:(if $has_more then "partial" else "covered" end),source:"read_channel_delta",pages_read:$pages_read}
              + (if $page_reason == "" then {} else {reason:$page_reason} end)),
     # `covered` here means the DISCOVERY OPERATION ran and could return replies whose
     # coordinates were not already known. Anything less is `partial` with its reason: a
     # channel delta that happens to carry a broadcast reply is not thread coverage, and
     # neither is the watch-set fallback, which reads only what somebody already saw.
     threads:({status:$thread_status,source:$thread_source,discovered:($thread_status == "covered"),truncated:$thread_truncated}
              + (if $thread_reason == "" then {} else {reason:$thread_reason} end)
              + (if $fallback_reason == "" then {} else {fallback_reason:$fallback_reason} end)),
     # A SEARCH IS NOT AN INDEX and never upgrades to a completeness claim (the `search_exact`
     # contract: zero rows certify nothing). The delta covers the window it read; `searched` says
     # whether the arm that can reach outside it ran, `discovered` what it found, and a refusal
     # rides its own reason. An absent `sender_id` leaves the whole reading `unreadable`.
     mentions:(if $bot=="" then {status:"unreadable",reason:"sender_identity_unverified"}
               else ({status:"covered_in_channel_delta",source:(if $mention_searched then "message_text+search_exact" else "message_text" end),
                      searched:$mention_searched,discovered:($mention_found|length),
                      tracked:$mention_threads_read,exhaustive:false}
                     + (if $mention_reason == "" then {} else {reason:$mention_reason} end)) end)}
     | . + {complete:(.top_level.status == "covered" and .threads.status == "covered" and .mentions.status != "unreadable" and ($thread_truncated | not))}),
   observation_settled:(($unsettled|length) == 0),
   unsettled:$unsettled,
   calls:{describe:$describe_calls,read_channel_delta:$channel_reads,capture:$channel_captures,threads:$thread_calls,mentions:$mention_calls,
          total:($describe_calls + $channel_reads + $channel_captures + $thread_calls + $mention_calls)},
   has_more:$has_more,
   overlap_seconds:$overlap,window_since:$window,covered_unproved_since:$covered,cursor_advanced:true,
   unreadable:$unreadable,
   next_cursor:$next}')
runtime_json_result ok "" observe-channel "$data"
