#!/bin/sh -eu
# ANNOUNCE A CLOCK THAT STOPPED, OR THAT KEEPS TICKING WITHOUT EXECUTING ANYTHING (2026-09-19,
# ticket `20260919115511-announce-a-codex-clock-that-stopped-or-executed-nothing`).
#
# `executed: false` with a reason is an honest refusal by a worker, and it reached nobody: the
# supervisor's whole escalation reach was `write_supervisor stopped <reason>` plus a line on
# stderr, and nothing outside `skills/work/` read the status surface at all. MEASURED: a loop
# stayed `blocked / interrupted` for twelve days with a person looking at the repository the
# whole time.
#
# NO NEW SHAPE, NO NEW TRANSPORT, NO SECOND LIVENESS AUTHORITY. The shape is
# `workaholic:notify`'s precondition-stop shape verbatim -- `⚪ Paused - <signature>` on a first
# report, escalating ONCE to `🔴 Blocked - <signature>` when the same signature comes back, and a
# root re-posted at cool-down expiry naming how long it has been failing. The transport is
# `specificate/scripts/notify-slack.sh`, the one script-level seam a POSIX supervisor can reach.
# The lock and the supervisor record remain the only authorities on whether anything is running;
# this reads them and decides nothing about who may run.
#
# WHY THE LEDGER IS LOCAL. `workaholic:notify` dedups by reading the channel's recent history,
# which is the connector's surface and not a script's. A supervisor has no channel read, so the
# dedup is kept in the state directory it already owns -- a notification ledger, never a second
# reading of whether the loop is alive. The STATED COST: a ledger a person deletes re-fires the
# alert once, and a wall hit from two different state directories is announced twice.
#
#   Usage: announce-stop.sh --log <dir> --signature <sig> --text <one line> [--session-url <url>]
#                           [--now <epoch>]
#   Output: {"announced":bool,"suppressed":bool,"shape":"paused|blocked|blocked_expiry"|null,
#            "signature":"...","reason":"<word>","outbox":"<path>"|null,"reports":N,
#            "first_seen":"<iso>"}
#
# `reason` is the transport's own refusal word (`no_token`, `no_channel`, `http_<code>`,
# `slack_<error>`, `curl_failed`), `suppressed_duplicate` for a signature inside its cool-down,
# or the empty string on a landed post. AN UNDELIVERABLE TRANSPORT IS A RECORDED REFUSAL AND
# NEVER A POST: the line is retained in the state directory's outbox and `announced` is false.

# THE ROLE THIS PATH RUNS UNDER (2026-09-11, issue #1151): the base-ref gate reads
# `WORKAHOLIC_ROLE`, and an unattended path names itself at its own entry. This path writes no
# commit and no ref; it names itself because every other unattended entry does.
: "${WORKAHOLIC_ROLE:=notify}"
export WORKAHOLIC_ROLE

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NOTIFIER="${WORKAHOLIC_ANNOUNCE_NOTIFIER:-${SCRIPT_DIR}/../../specificate/scripts/notify-slack.sh}"
SPEAKING_WINDOW="${SCRIPT_DIR}/../../moderate/scripts/lib/speaking-window.sh"

LOG_DIR="" SIGNATURE="" TEXT="" SESSION_URL="" NOW=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --log) LOG_DIR="${2:-}"; shift 2 ;;
        --signature) SIGNATURE="${2:-}"; shift 2 ;;
        --text) TEXT="${2:-}"; shift 2 ;;
        --session-url) SESSION_URL="${2:-}"; shift 2 ;;
        --now) NOW="${2:-}"; shift 2 ;;
        *) printf 'bad_argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done
[ -n "$LOG_DIR" ] && [ -n "$SIGNATURE" ] && [ -n "$TEXT" ] \
    || { printf 'bad_argument: --log, --signature and --text are all required\n' >&2; exit 2; }
case "$NOW" in ''|*[!0-9]*) NOW=$(date -u +%s) ;; esac

LEDGER="${LOG_DIR}/announcements.json"
OUTBOX_DIR="${LOG_DIR}/outbox"

emit() {
    # $1 announced  $2 suppressed  $3 shape  $4 reason  $5 outbox  $6 reports  $7 first_seen
    jq -cn --argjson announced "$1" --argjson suppressed "$2" \
        --arg shape "$3" --arg reason "$4" --arg outbox "$5" \
        --argjson reports "$6" --arg first_seen "$7" --arg signature "$SIGNATURE" \
        '{announced:$announced,suppressed:$suppressed,
          shape:(if $shape=="" then null else $shape end),
          signature:$signature,reason:$reason,
          outbox:(if $outbox=="" then null else $outbox end),
          reports:$reports,first_seen:$first_seen}'
}

command -v jq >/dev/null 2>&1 || { emit false false '' jq_unavailable '' 0 ''; exit 0; }
mkdir -p "$LOG_DIR" 2>/dev/null || true
[ -f "$LEDGER" ] || printf '{}\n' > "$LEDGER"
jq -e 'type == "object"' "$LEDGER" >/dev/null 2>&1 || printf '{}\n' > "$LEDGER"

_prev=$(jq -c --arg s "$SIGNATURE" '.[$s] // null' "$LEDGER" 2>/dev/null || printf null)
_reports=$(printf '%s' "$_prev" | jq -r '.reports // 0' 2>/dev/null || printf 0)
case "$_reports" in ''|*[!0-9]*) _reports=0 ;; esac
_first_epoch=$(printf '%s' "$_prev" | jq -r '.first_epoch // ""' 2>/dev/null || printf '')
case "$_first_epoch" in ''|*[!0-9]*) _first_epoch=$NOW ;; esac
_first_seen=$(printf '%s' "$_prev" | jq -r '.first_seen // ""' 2>/dev/null || printf '')
[ -n "$_first_seen" ] || _first_seen=$(date -u -d "@${_first_epoch}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf '')
_last_post=$(printf '%s' "$_prev" | jq -r '.last_post_epoch // 0' 2>/dev/null || printf 0)
case "$_last_post" in ''|*[!0-9]*) _last_post=0 ;; esac

# THE COOL-DOWN IS COMPOSED, NEVER RE-DERIVED (`workaholic:notify`): it expires at the EARLIER of
# 24 hours after the last root and the start of the next working day -- the first hour inside
# `WORKAHOLIC_WORK_DAYS` at the end of `WORKAHOLIC_QUIET_HOURS`, in `WORKAHOLIC_QUIET_TZ`. Those
# three are the check-in gate's own values and are read through its one derivation. Where that
# derivation cannot be reached, only the 24-hour term applies and the reason says so -- a longer
# silence, which is the safe direction for a rule whose job is to suppress repeats.
cooled_down() {
    [ "$_last_post" -gt 0 ] || return 0
    [ $((NOW - _last_post)) -ge 86400 ] && return 0
    [ -f "$SPEAKING_WINDOW" ] || return 1
    # shellcheck disable=SC1090
    . "$SPEAKING_WINDOW" 2>/dev/null || return 1
    command -v speaking_window >/dev/null 2>&1 || return 1
    speaking_window "" "" "" 2>/dev/null || return 1
    [ "${SW_QUIET:-true}" = false ] && [ "${SW_OFFDAY:-true}" = false ] || return 1
    _cd_today=$(TZ="$(speaking_zone)" date -d "@${NOW}" +%Y-%m-%d 2>/dev/null || printf '')
    _cd_then=$(TZ="$(speaking_zone)" date -d "@${_last_post}" +%Y-%m-%d 2>/dev/null || printf '')
    [ -n "$_cd_today" ] && [ -n "$_cd_then" ] && [ "$_cd_today" != "$_cd_then" ]
}

_reports=$((_reports + 1))
# ONE ALERT PER WALL. A first report is the calm shape; the same signature coming back escalates
# ONCE to the red form; every later tick is suppressed until the cool-down expires, when the root
# is re-posted naming how long it has been failing.
_shape=""
if [ "$_reports" -eq 1 ]; then
    _shape=paused
    _body="⚪ Paused - ${SIGNATURE}"
elif [ "$_reports" -eq 2 ]; then
    _shape=blocked
    _body="🔴 Blocked - ${SIGNATURE}"
elif cooled_down; then
    _shape=blocked_expiry
    _body="🔴 Blocked - ${SIGNATURE}, failing since ${_first_seen}, ${_reports} ticks"
fi

write_ledger() {
    # $1 last_post_epoch
    _wl_tmp="${LEDGER}.tmp.$$"
    jq --arg s "$SIGNATURE" --argjson reports "$_reports" \
        --argjson first_epoch "$_first_epoch" --arg first_seen "$_first_seen" \
        --argjson last_post "$1" --argjson now "$NOW" \
        '.[$s] = {reports:$reports,first_epoch:$first_epoch,first_seen:$first_seen,
                  last_post_epoch:$last_post,last_seen_epoch:$now}' "$LEDGER" > "$_wl_tmp" \
        && mv "$_wl_tmp" "$LEDGER"
}

if [ -z "$_shape" ]; then
    write_ledger "$_last_post"
    emit false true '' suppressed_duplicate '' "$_reports" "$_first_seen"
    exit 0
fi

_line="$_body"
[ -z "$TEXT" ] || _line="${_line}
${TEXT}"
[ -z "$SESSION_URL" ] || _line="${_line}
${SESSION_URL}"

_result='{"notified": false, "reason": "no_notifier"}'
if [ -f "$NOTIFIER" ]; then
    _result=$(sh "$NOTIFIER" "$_line" 2>/dev/null || printf '{"notified": false, "reason": "notifier_failed"}')
fi
printf '%s' "$_result" | jq -e 'type == "object" and has("notified")' >/dev/null 2>&1 \
    || _result='{"notified": false, "reason": "notifier_unreadable"}'
_notified=$(printf '%s' "$_result" | jq -r '.notified' 2>/dev/null || printf false)
_reason=$(printf '%s' "$_result" | jq -r '.reason // ""' 2>/dev/null || printf '')

if [ "$_notified" = true ]; then
    write_ledger "$NOW"
    emit true false "$_shape" '' '' "$_reports" "$_first_seen"
    exit 0
fi

# A REFUSED CALL IS CARRIED, NEVER DROPPED, AND NEVER READ AS POSTED. The ledger's
# `last_post_epoch` is deliberately NOT advanced: nothing was posted, so nothing starts a
# cool-down, and the next tick's escalation ladder is where this one left it.
mkdir -p "$OUTBOX_DIR" 2>/dev/null || true
_slug=$(printf '%s' "$SIGNATURE" | tr -c 'A-Za-z0-9._-' '-')
_entry="${OUTBOX_DIR}/${_slug}-${NOW}.json"
jq -n --arg signature "$SIGNATURE" --arg shape "$_shape" --arg line "$_line" \
    --arg reason "${_reason:-unstated}" --argjson at "$NOW" \
    '{signature:$signature,shape:$shape,line:$line,reason:$reason,recorded_at:$at,delivered:false}' \
    > "$_entry" 2>/dev/null || _entry=""
write_ledger "$_last_post"
emit false false "$_shape" "${_reason:-unstated}" "$_entry" "$_reports" "$_first_seen"
