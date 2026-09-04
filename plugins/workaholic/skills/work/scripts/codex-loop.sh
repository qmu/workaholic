#!/bin/sh -eu
# Plugin-owned external clock for Codex CLI/IDE. Repository entrypoints are thin shims.

INTERVAL=300
ONCE=false
DRY_RUN=false
STATUS_ONLY=false
LOG_DIR=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --interval) INTERVAL="${2:-300}"; shift 2 ;;
        --once) ONCE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --status) STATUS_ONLY=true; shift ;;
        --log) LOG_DIR="${2:-}"; shift 2 ;;
        -h|--help)
            printf '%s\n' \
                'Usage: sh <installed-launcher> [--interval <seconds>] [--once] [--dry-run] [--status] [--log <dir>]' \
                '  --interval  seconds between completed ticks (default 300)' \
                '  --once      execute one tick and exit' \
                '  --dry-run   print the command without executing it' \
                '  --status    read current state without starting a tick' \
                '  --log       transcript directory (default <repository>/.codex-loop)'
            exit 0 ;;
        *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done

case "$INTERVAL" in ''|*[!0-9]*) printf 'interval must be whole seconds\n' >&2; exit 2 ;; esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/../../.." && pwd)
TICK_PROMPT="${PLUGIN_ROOT}/skills/work/SKILL.md"
COMMAND_BODY="${PLUGIN_ROOT}/commands/infinite-development.md"

if [ ! -f "$TICK_PROMPT" ]; then
    printf 'plugin_skill_missing: %s\n' "$TICK_PROMPT" >&2
    printf 'Update or reinstall the Workaholic plugin; its work skill is incomplete.\n' >&2
    exit 2
fi
if [ ! -f "$COMMAND_BODY" ]; then
    printf 'plugin_command_missing: %s\n' "$COMMAND_BODY" >&2
    printf 'Update or reinstall the Workaholic plugin; its tick command body is incomplete.\n' >&2
    exit 2
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$REPO_ROOT" ] || { printf 'repository_missing: run the launcher inside a git repository\n' >&2; exit 2; }
[ -z "$LOG_DIR" ] && LOG_DIR="${REPO_ROOT}/.codex-loop"
STATUS_FILE="${LOG_DIR}/status.json"

show_status() {
    if [ ! -f "$STATUS_FILE" ]; then
        printf 'codex loop status: absent (%s)\n' "$STATUS_FILE"
        return 4
    fi
    if command -v jq >/dev/null 2>&1 && jq -e . "$STATUS_FILE" >/dev/null 2>&1; then
        jq -r '"codex loop status: state=\(.state) outcome=\(.outcome)" +
          (if .blocked_reason == "" then "" else " blocked_reason=\(.blocked_reason)" end) +
          (if .next_due == "" then "" else " next_due=\(.next_due)" end) +
          (if .report_path == "" then "" else " report=\(.report_path)" end)' "$STATUS_FILE"
        return 0
    fi
    printf 'codex loop status: unreadable (%s)\n' "$STATUS_FILE"
    return 5
}

if [ "$STATUS_ONLY" = true ]; then
    show_status
    exit $?
fi

command -v codex >/dev/null 2>&1 || { printf 'codex_cli_missing: the codex CLI is not on PATH\n' >&2; exit 2; }

SETTINGS="${REPO_ROOT}/.claude/settings.json"
ENV_SOURCE="none"
if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
    if _pairs=$(jq -r '(.env // {}) | to_entries[] | "\(.key)=\(.value)"' "$SETTINGS" 2>/dev/null); then
        ENV_SOURCE="settings"
        for _pair in $_pairs; do
            _k=${_pair%%=*}
            _v=${_pair#*=}
            case "$_k" in CLAUDE_*) continue ;; esac
            case "$_k" in [A-Za-z_][A-Za-z0-9_]*) ;; *) continue ;; esac
            eval "_cur=\${${_k}:-}"
            [ -n "${_cur}" ] || export "${_k}=${_v}"
        done
    else
        ENV_SOURCE="unreadable"
    fi
fi

mkdir -p "$LOG_DIR"

json_quote() {
    if command -v jq >/dev/null 2>&1; then
        jq -Rn --arg value "$1" '$value'
    else
        printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/'
    fi
}

write_status() {
    _state=$1 _outcome=$2 _reason=$3 _tick=$4 _started=$5 _finished=$6
    _report=$7 _transcript=$8 _transport=$9 _next_due=${10}
    _tmp="${STATUS_FILE}.tmp.$$"
    {
        printf '{\n'
        printf '  "state": %s,\n' "$(json_quote "$_state")"
        printf '  "outcome": %s,\n' "$(json_quote "$_outcome")"
        printf '  "blocked_reason": %s,\n' "$(json_quote "$_reason")"
        printf '  "tick_id": %s,\n' "$(json_quote "$_tick")"
        printf '  "started_at": %s,\n' "$(json_quote "$_started")"
        printf '  "finished_at": %s,\n' "$(json_quote "$_finished")"
        printf '  "report_path": %s,\n' "$(json_quote "$_report")"
        printf '  "transcript_path": %s,\n' "$(json_quote "$_transcript")"
        printf '  "transport_verdict": %s,\n' "$(json_quote "$_transport")"
        printf '  "next_due": %s\n' "$(json_quote "$_next_due")"
        printf '}\n'
    } >"$_tmp"
    mv "$_tmp" "$STATUS_FILE"
}

iso_from_epoch() {
    date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf '%s' "$1"
}

classify_report() {
    _report_file=$1 _exit=$2
    TICK_OUTCOME=ready
    BLOCKED_REASON=""
    TRANSPORT_VERDICT=available
    if [ "$_exit" -ne 0 ]; then
        TICK_OUTCOME=tick_failure
        BLOCKED_REASON="codex_exit_${_exit}"
    elif [ ! -s "$_report_file" ]; then
        TICK_OUTCOME=report_missing
        BLOCKED_REASON=no_tick_report
        TRANSPORT_VERDICT=unknown
    elif grep -q 'no_slack_transport' "$_report_file"; then
        TICK_OUTCOME=transport_absent
        BLOCKED_REASON=no_slack_transport
        TRANSPORT_VERDICT=absent
    elif grep -Eq '(^|[[:space:]])(blocked|failed|[[:alnum:]_]+_failed|cadence_unreadable):' "$_report_file"; then
        TICK_OUTCOME=work_blocked
        BLOCKED_REASON=$(grep -E '(^|[[:space:]])(blocked|failed|[[:alnum:]_]+_failed|cadence_unreadable):' "$_report_file" | head -n 1 | tr '\n' ' ')
    fi
}

CURRENT_TICK=""
CURRENT_STARTED=""
CURRENT_REPORT=""
CURRENT_TRANSCRIPT=""
on_interrupt() {
    [ -n "$CURRENT_TICK" ] || exit 130
    _finished=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    write_status blocked interrupted signal "$CURRENT_TICK" "$CURRENT_STARTED" "$_finished" \
        "$CURRENT_REPORT" "$CURRENT_TRANSCRIPT" unknown ""
    exit 130
}
trap on_interrupt INT TERM

run_tick() {
    _stamp=$(date -u +%Y%m%dT%H%M%SZ)
    _out="${LOG_DIR}/${_stamp}.md"
    _transcript="${LOG_DIR}/${_stamp}.log"
    _started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    CURRENT_TICK=$_stamp CURRENT_STARTED=$_started CURRENT_REPORT=$_out CURRENT_TRANSCRIPT=$_transcript
    _prompt="Read ${TICK_PROMPT} in full and execute exactly one tick of the development loop as it specifies, applying its substitutions for an agent with no interval feature and no background subagents. Do not loop; end after one tick. Report the tick's own report block as your final message."
    if [ "$DRY_RUN" = true ]; then
        printf 'codex exec -C %s --dangerously-bypass-approvals-and-sandbox --output-last-message %s <prompt>\n' "$REPO_ROOT" "$_out"
        return 0
    fi
    write_status running running "" "$_stamp" "$_started" "" "$_out" "$_transcript" unknown ""
    if codex exec -C "$REPO_ROOT" --dangerously-bypass-approvals-and-sandbox \
        -c shell_environment_policy.inherit=all --output-last-message "$_out" "$_prompt" \
        >"$_transcript" 2>&1; then
        _exit=0
    else
        _exit=$?
    fi
    _finished_epoch=$(date -u +%s)
    _finished=$(iso_from_epoch "$_finished_epoch")
    _next_due=$(iso_from_epoch "$((_finished_epoch + INTERVAL))")
    classify_report "$_out" "$_exit"
    case "$TICK_OUTCOME" in ready) _state=sleeping ;; *) _state=blocked ;; esac
    write_status "$_state" "$TICK_OUTCOME" "$BLOCKED_REASON" "$_stamp" "$_started" \
        "$_finished" "$_out" "$_transcript" "$TRANSPORT_VERDICT" "$_next_due"
    printf 'codex tick: outcome=%s' "$TICK_OUTCOME"
    [ -z "$BLOCKED_REASON" ] || printf ' blocked_reason=%s' "$BLOCKED_REASON"
    printf ' report=%s next_due=%s\n' "$_out" "$_next_due"
    CURRENT_TICK=""
    [ "$_exit" -eq 0 ] || printf 'tick exited non-zero; the supervisor continues\n' >&2
    [ "$TICK_OUTCOME" = ready ]
}

LOCK="${LOG_DIR}/.supervisor.lock"
if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK"
    flock -n 9 || { printf 'another codex loop already holds %s\n' "$LOCK" >&2; exit 3; }
else
    printf 'flock is not installed: a second supervisor would not be refused\n' >&2
fi

_first=true
while :; do
    if run_tick; then
        _tick_ready=true
    else
        _tick_ready=false
    fi
    if [ "$_first" = true ]; then
        _first=false
        if [ "$_tick_ready" != true ]; then
            printf 'codex loop readiness refused; use --status for the recorded reason\n' >&2
            exit 6
        fi
        printf 'codex loop: ready interval=%ss once=%s env=%s log=%s\n' \
            "$INTERVAL" "$ONCE" "$ENV_SOURCE" "$LOG_DIR" >&2
    fi
    [ "$ONCE" = true ] && break
    sleep "$INTERVAL"
done
