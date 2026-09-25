#!/bin/sh -eu
# Watch the declared Slack channel without a model in the loop.
#
#   watch-slack.sh --root REPO [--interval SECONDS] [--once]
#
# Every interval (default 120s, WORKAHOLIC_WATCH_INTERVAL) it runs the one channel reader,
# `transport/scripts/observe-channel.sh`, which captures messages and advances the cursor. It
# prints ONE JSON line per new human message and NOTHING when the channel is quiet, so a session
# streaming this output (Claude Code's Monitor tool) is woken only by a change and spends no
# tokens while nothing happens:
#
#   {"event":"message","ts":"...","thread_ts":null|"...","user":"U...","text":"..."}
#   {"event":"observe_failed","reason":"..."}   printed once per distinct reason, not every tick
#
# The loop's own posts are dropped: the connector's "Sent using" signature, and roots opening
# with one of the loop's post shapes, as the emoji or as the :shortcode: Slack stores it as. Text is cut at WORKAHOLIC_WATCH_TEXT_MAX (1500) characters.
# Messages older than WORKAHOLIC_WATCH_MAX_AGE seconds (default 3600) are dropped: a changed
# declaration mints a new binding record with no cursor, and its first read returns the channel's
# history, which must not wake the session as if it were new.
# --once reads a single time and exits, for a caller that brings its own clock.

ROOT=; INTERVAL=${WORKAHOLIC_WATCH_INTERVAL:-120}; ONCE=false
TEXT_MAX=${WORKAHOLIC_WATCH_TEXT_MAX:-1500}
MAX_AGE=${WORKAHOLIC_WATCH_MAX_AGE:-3600}
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=${2:-}; shift 2 ;;
    --interval) INTERVAL=${2:-}; shift 2 ;;
    --once) ONCE=true; shift ;;
    *) printf 'usage: watch-slack.sh --root REPO [--interval SECONDS] [--once]\n' >&2; exit 2 ;;
  esac
done
[ -n "$ROOT" ] || { printf 'usage: watch-slack.sh --root REPO [--interval SECONDS] [--once]\n' >&2; exit 2; }
case "$INTERVAL" in ''|*[!0-9]*) INTERVAL=120 ;; esac
case "$TEXT_MAX" in ''|*[!0-9]*) TEXT_MAX=1500 ;; esac
case "$MAX_AGE" in ''|*[!0-9]*) MAX_AGE=3600 ;; esac
command -v jq >/dev/null 2>&1 || { printf '{"event":"observe_failed","reason":"jq_unavailable"}\n'; exit 0; }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OBSERVE="$SCRIPT_DIR/../../transport/scripts/observe-channel.sh"
GITDIR=$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || printf '')
case "$GITDIR" in /*|'') ;; *) GITDIR="$ROOT/$GITDIR" ;; esac
BINDINGS="$GITDIR/workaholic/runtime/v1/bindings"
LAST_FAIL=

# The captured record for one provider id: the capture is the only place the text is kept.
message_for() {
  _f=$(grep -rl --include='*.json' "\"provider_id\":\"$1\"" "$BINDINGS" 2>/dev/null | head -n 1 || true)
  [ -n "$_f" ] || return 0
  jq -c '.data.message' "$_f" 2>/dev/null || true
}

tick() {
  out=$(sh "$OBSERVE" --root "$ROOT" 2>/dev/null || printf '')
  status=$(printf '%s' "$out" | jq -r '.status // empty' 2>/dev/null || printf '')
  if [ "$status" != ok ]; then
    reason=$(printf '%s' "$out" | jq -r '.reason // empty' 2>/dev/null || printf '')
    [ -n "$reason" ] || reason=observe_unreadable
    if [ "$reason" != "$LAST_FAIL" ]; then
      jq -cn --arg r "$reason" '{event:"observe_failed",reason:$r}'
      LAST_FAIL=$reason
    fi
    return 0
  fi
  LAST_FAIL=
  ids=$(printf '%s' "$out" | jq -r '[(.data.new_input_ids // [])[], ((.data.thread_replies // [])[] | .id)] | unique | .[]' 2>/dev/null || printf '')
  for id in $ids; do
    m=$(message_for "$id")
    [ -n "$m" ] || continue
    printf '%s' "$m" | jq -c --argjson max "$TEXT_MAX" --argjson oldest "$(( $(date +%s) - MAX_AGE ))" '
      select((((.ts // .id // "0") | tostring | split(".")[0] | tonumber? ) // 0) >= $oldest)
      | (.text // "") as $t
      | select(($t | contains("*Sent using*")) | not)
      | select(($t | ltrimstr(" ")) as $s
          | ["🙋","📝 FB","🔎 Moderation","🔵 Proposed","🟢 Implemented","🟡 Handoff","📥 受理","💬","📊","🏁","⚪","🔴",
             ":raising_hand:",":memo: FB",":mag: Moderation",":large_blue_circle: Proposed",
             ":large_green_circle: Implemented",":large_yellow_circle: Handoff",":inbox_tray: 受理",
             ":speech_balloon:",":bar_chart:",":checkered_flag:",":white_circle:",":red_circle:"]
          | any(.[]; . as $p | $s | startswith($p)) | not)
      | {event:"message", ts:(.ts // .id), thread_ts:(.thread_ts // null),
         user:(.sender_id // .user // null), text:($t | .[0:$max])}' 2>/dev/null || true
  done
  return 0
}

if [ "$ONCE" = true ]; then tick; exit 0; fi
while :; do
  tick
  sleep "$INTERVAL"
done
