#!/bin/sh -eu
# Plugin-owned external clock for Codex CLI/IDE. Repository entrypoints are thin shims.

INTERVAL=300
ONCE=false
DRY_RUN=false
STATUS_ONLY=false
RELAY=false
ACK_FILE=""
LOG_DIR=""
DISPATCH_ROLE=""
WORKER_ROLE=""
ROLES="implement propose moderate"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --interval) INTERVAL="${2:-300}"; shift 2 ;;
        --once) ONCE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --status) STATUS_ONLY=true; shift ;;
        --relay) RELAY=true; shift ;;
        --dispatch) DISPATCH_ROLE="${2:-}"; shift 2 ;;
        --worker) WORKER_ROLE="${2:-}"; shift 2 ;;
        --ack) ACK_FILE="${2:-}"; shift 2 ;;
        --log) LOG_DIR="${2:-}"; shift 2 ;;
        -h|--help)
            printf '%s\n' \
                'Usage: sh <installed-launcher> [--interval <seconds>] [--once] [--dry-run] [--status] [--relay] [--ack <file>] [--log <dir>]' \
                '  --interval  seconds between completed ticks (default 300)' \
                '  --once      execute one tick and exit' \
                '  --dry-run   print the command without executing it' \
                '  --status    read current state without starting a tick' \
                '  --relay     return credential-free Slack intents for an owning chat' \
                '  --dispatch  start one background worker (implement|propose|moderate) and return' \
                '  --worker    run one worker in this process; refuses a role already running' \
                '  --ack       validate a parent acknowledgement against the current envelope' \
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
RELAY_CONTRACT="${SCRIPT_DIR}/relay-contract.sh"

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
RELAY_STATE="none"

# THE COORDINATOR NEVER WAITS FOR THE WORK (2026-09-05, issues #984 and #985). A role is
# dispatched as a detached process holding its own lock, so a run lasting longer than the
# interval cannot delay the next channel turn, and a role already running is refused by name
# rather than started twice.
role_known() {
    for _r in $ROLES; do [ "$_r" = "$1" ] && return 0; done
    return 1
}
role_lock() { printf '%s/worker-%s.lock' "$LOG_DIR" "$1"; }
role_pidfile() { printf '%s/worker-%s.pid' "$LOG_DIR" "$1"; }

# `running` / `idle`. flock is the authority where it exists; a pid file is the fallback, and
# a pid file naming a dead process is idle rather than an unreadable state.
role_state() {
    _lock=$(role_lock "$1")
    if command -v flock >/dev/null 2>&1; then
        if [ -e "$_lock" ] && ! ( exec 8>"$_lock"; flock -n 8 ) 2>/dev/null; then
            printf 'running'; return 0
        fi
        printf 'idle'; return 0
    fi
    _pf=$(role_pidfile "$1")
    if [ -s "$_pf" ] && kill -0 "$(cat "$_pf" 2>/dev/null)" 2>/dev/null; then
        printf 'running'; return 0
    fi
    printf 'idle'
}
RELAY_ENVELOPE=""
RELAY_ACK=""

show_status() {
    if [ ! -f "$STATUS_FILE" ]; then
        printf 'codex loop status: absent (%s)\n' "$STATUS_FILE"
        return 4
    fi
    if command -v jq >/dev/null 2>&1 && jq -e . "$STATUS_FILE" >/dev/null 2>&1; then
        jq -r '"codex loop status: state=\(.state) outcome=\(.outcome)" +
          (if .blocked_reason == "" then "" else " blocked_reason=\(.blocked_reason)" end) +
          (if .next_due == "" then "" else " next_due=\(.next_due)" end) +
          (if (.relay_state // "none") == "none" then "" else " relay=\(.relay_state)" end) +
          (if .report_path == "" then "" else " report=\(.report_path)" end)' "$STATUS_FILE"
        return 0
    fi
    printf 'codex loop status: unreadable (%s)\n' "$STATUS_FILE"
    return 5
}

show_workers() {
    for _r in $ROLES; do printf 'codex worker %s: %s\n' "$_r" "$(role_state "$_r")"; done
}

if [ -n "$ACK_FILE" ]; then
    [ -s "$STATUS_FILE" ] || { printf 'relay_status_missing: %s\n' "$STATUS_FILE" >&2; exit 4; }
    RELAY_ENVELOPE=$(jq -r '.relay_envelope_path // ""' "$STATUS_FILE" 2>/dev/null || true)
    [ -n "$RELAY_ENVELOPE" ] || { printf 'relay_envelope_missing\n' >&2; exit 5; }
    sh "$RELAY_CONTRACT" acknowledgement "$RELAY_ENVELOPE" "$ACK_FILE" >/dev/null
    _relay=$(sh "$RELAY_CONTRACT" reconcile "$RELAY_ENVELOPE" "$ACK_FILE" | jq -r '.relay')
    _tmp="${STATUS_FILE}.tmp.$$"
    jq --arg relay "$_relay" --arg ack "$ACK_FILE" '
      .relay_state=$relay | .relay_ack_path=$ack |
      if $relay == "delivered" then
        .state="sleeping" | .outcome="ready" | .blocked_reason="" |
        .transport_verdict="parent_connector"
      else
        .state="blocked" | .outcome="relay_incomplete" |
        .blocked_reason="undelivered_relay_intents"
      end' "$STATUS_FILE" >"$_tmp"
    mv "$_tmp" "$STATUS_FILE"
    show_status
    exit 0
fi

if [ "$STATUS_ONLY" = true ]; then
    show_status
    _status_exit=$?
    show_workers
    exit "$_status_exit"
fi

if [ -n "$DISPATCH_ROLE" ] || [ -n "$WORKER_ROLE" ]; then
    _role="${DISPATCH_ROLE}${WORKER_ROLE}"
    role_known "$_role" || { printf 'bad_role: %s (known: %s)\n' "$_role" "$ROLES" >&2; exit 2; }
    ROLE_BODY="${PLUGIN_ROOT}/commands/${_role}.md"
    [ -f "$ROLE_BODY" ] || {
        printf 'plugin_command_missing: %s\n' "$ROLE_BODY" >&2
        printf 'Update or reinstall the Workaholic plugin; its %s command body is incomplete.\n' "$_role" >&2
        exit 2; }
    mkdir -p "$LOG_DIR"
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
        printf '  "relay_state": %s,\n' "$(json_quote "$RELAY_STATE")"
        printf '  "relay_envelope_path": %s,\n' "$(json_quote "$RELAY_ENVELOPE")"
        printf '  "relay_ack_path": %s,\n' "$(json_quote "$RELAY_ACK")"
        printf '  "next_due": %s\n' "$(json_quote "$_next_due")"
        printf '}\n'
    } >"$_tmp"
    mv "$_tmp" "$STATUS_FILE"
}

# THE CADENCE IS MEASURED FROM STARTUP, NOT FROM THE PREVIOUS TICK'S FINISH (2026-09-05,
# issue #984). Sleeping a whole interval after a completed tick makes the real period
# `tick duration + interval`: a tick still running six minutes in pushed the next channel turn
# past the eleventh minute. The boundary is the first `anchor + k*interval` strictly after the
# given moment, so a slow tick costs the boundaries it overran and never shifts the phase.
next_boundary() {
    _from=$1
    [ "$INTERVAL" -gt 0 ] || { printf '%s' "$_from"; return 0; }
    _k=$(( (_from - LOOP_ANCHOR) / INTERVAL + 1 ))
    printf '%s' "$(( LOOP_ANCHOR + _k * INTERVAL ))"
}

iso_from_epoch() {
    date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf '%s' "$1"
}

classify_report() {
    _report_file=$1 _exit=$2
    TICK_OUTCOME=ready
    BLOCKED_REASON=""
    TRANSPORT_VERDICT=available
    RELAY_STATE=none
    RELAY_ENVELOPE=""
    RELAY_ACK=""
    if [ "$_exit" -ne 0 ]; then
        TICK_OUTCOME=tick_failure
        BLOCKED_REASON="codex_exit_${_exit}"
    elif [ "$RELAY" = true ]; then
        if ! sh "$RELAY_CONTRACT" envelope "$_report_file" >/dev/null 2>&1; then
            TICK_OUTCOME=relay_malformed
            BLOCKED_REASON=invalid_relay_envelope
            TRANSPORT_VERDICT=unknown
            RELAY_STATE=malformed
        else
            RELAY_ENVELOPE="$_report_file"
            _intent_count=$(jq '.slack_intents | length' "$_report_file")
            _worker_outcome=$(jq -r '.outcome' "$_report_file")
            if [ "$_worker_outcome" = blocked ]; then
                TICK_OUTCOME=work_blocked
                BLOCKED_REASON=worker_reported_blocked
                TRANSPORT_VERDICT=pending_parent
                RELAY_STATE=pending
            elif [ "$_intent_count" -gt 0 ]; then
                TICK_OUTCOME=relay_pending
                BLOCKED_REASON=awaiting_parent_ack
                TRANSPORT_VERDICT=pending_parent
                RELAY_STATE=pending
            else
                TRANSPORT_VERDICT=parent_not_needed
                RELAY_STATE=delivered
            fi
        fi
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
    _prompt="Read ${TICK_PROMPT} in full and execute exactly one tick of the development loop as it specifies, applying its substitutions for an agent with no interval feature. You are the coordinator: answer the inbound channel yourself, then start each DUE work run in the background with 'sh ${SCRIPT_DIR}/codex-loop.sh --dispatch <implement|propose|moderate>', which returns at once and refuses a role already running. Never run that work inline and never wait for a dispatched worker. Do not loop; end after one tick. Report the tick's own report block as your final message."
    if [ "$RELAY" = true ]; then
        _prompt="${_prompt} You are a connector-less worker with a connector-owning parent waiting for this result. Read ${PLUGIN_ROOT}/skills/work/reference/codex-slack-relay.md and return only one workaholic.codex-slack-relay/v1 JSON envelope. Represent every earned Slack action as an ordered intent; call no connector, include no credential, and never claim an intent was delivered."
    fi
    if [ "$DRY_RUN" = true ]; then
        printf 'codex exec -C %s --dangerously-bypass-approvals-and-sandbox --output-last-message %s %s\n' "$REPO_ROOT" "$_out" "$_prompt"
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
    _next_due=$(iso_from_epoch "$(next_boundary "$_finished_epoch")")
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

record_worker_finish() {
    # The cadence readers are the tick log's, unchanged: a finish is recorded even for a run
    # that failed, because the cadence measures WHEN WE LAST TRIED.
    _tick_id_sh="${SCRIPT_DIR}/../../moderate/scripts/tick-id.sh"
    _log_append_sh="${SCRIPT_DIR}/../../moderate/scripts/log-append.sh"
    [ -f "$_tick_id_sh" ] && [ -f "$_log_append_sh" ] || return 0
    _tick=$(sh "$_tick_id_sh" 2>/dev/null || true)
    [ -n "$_tick" ] || return 0
    sh "$_log_append_sh" --tick "$_tick" --step "loop-finish-$1" \
        --status ok --summary "$1 finished (exit $2)" >/dev/null 2>&1 || true
}

run_worker() {
    _role=$1
    _wstamp=$(date -u +%Y%m%dT%H%M%SZ)
    _wout="${LOG_DIR}/${_wstamp}-${_role}.md"
    _wlog="${LOG_DIR}/${_wstamp}-${_role}.log"
    _wprompt="Read ${ROLE_BODY} in full and execute it exactly once in this repository, applying the substitutions in ${PLUGIN_ROOT}/skills/work/SKILL.md for an agent with no background subagents. Do not loop, do not start another worker, and do not read or answer the inbound channel — the coordinator owns that. Report the run's own report block as your final message."
    if [ "$DRY_RUN" = true ]; then
        printf 'codex exec -C %s --dangerously-bypass-approvals-and-sandbox --output-last-message %s %s\n' \
            "$REPO_ROOT" "$_wout" "$_wprompt"
        return 0
    fi
    if codex exec -C "$REPO_ROOT" --dangerously-bypass-approvals-and-sandbox \
        -c shell_environment_policy.inherit=all --output-last-message "$_wout" "$_wprompt" \
        >"$_wlog" 2>&1; then _wexit=0; else _wexit=$?; fi
    record_worker_finish "$_role" "$_wexit"
    printf 'codex worker %s: exit=%s report=%s\n' "$_role" "$_wexit" "$_wout"
    return 0
}

if [ -n "$WORKER_ROLE" ]; then
    if command -v flock >/dev/null 2>&1; then
        exec 8>"$(role_lock "$WORKER_ROLE")"
        flock -n 8 || { printf 'already_running: %s\n' "$WORKER_ROLE" >&2; exit 3; }
    else
        [ "$(role_state "$WORKER_ROLE")" = idle ] || { printf 'already_running: %s\n' "$WORKER_ROLE" >&2; exit 3; }
        WORKER_PIDFILE=$(role_pidfile "$WORKER_ROLE")
        printf '%s\n' "$$" >"$WORKER_PIDFILE"
        trap 'rm -f "$WORKER_PIDFILE"' EXIT
    fi
    run_worker "$WORKER_ROLE"
    exit 0
fi

if [ -n "$DISPATCH_ROLE" ]; then
    # THE ONE REFUSAL THAT REPLACES `ListAgents`: a role already running is never started twice.
    if [ "$(role_state "$DISPATCH_ROLE")" = running ]; then
        printf 'codex dispatch %s: already_running\n' "$DISPATCH_ROLE"
        exit 0
    fi
    if [ "$DRY_RUN" = true ]; then
        printf 'codex dispatch %s: would start a detached worker\n' "$DISPATCH_ROLE"
        exit 0
    fi
    _dlog="${LOG_DIR}/dispatch-${DISPATCH_ROLE}.log"
    if command -v setsid >/dev/null 2>&1; then
        setsid sh "${SCRIPT_DIR}/codex-loop.sh" --worker "$DISPATCH_ROLE" --log "$LOG_DIR" \
            >"$_dlog" 2>&1 &
    else
        nohup sh "${SCRIPT_DIR}/codex-loop.sh" --worker "$DISPATCH_ROLE" --log "$LOG_DIR" \
            >"$_dlog" 2>&1 &
    fi
    printf 'codex dispatch %s: started pid=%s log=%s\n' "$DISPATCH_ROLE" "$!" "$_dlog"
    exit 0
fi

LOCK="${LOG_DIR}/.supervisor.lock"
if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK"
    flock -n 9 || { printf 'another codex loop already holds %s\n' "$LOCK" >&2; exit 3; }
else
    printf 'flock is not installed: a second supervisor would not be refused\n' >&2
fi

# The anchor is the moment the supervisor started. Every boundary is measured from it, so the
# loop keeps its phase however long an individual tick takes.
LOOP_ANCHOR=$(date -u +%s)
_expected=$LOOP_ANCHOR
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
    _now=$(date -u +%s)
    _due=$(next_boundary "$_now")
    _skipped=$(( (_due - _expected) / INTERVAL - 1 ))
    if [ "$_skipped" -gt 0 ]; then
        printf 'codex loop: the tick overran %s boundary(ies); next turn at %s\n' \
            "$_skipped" "$(iso_from_epoch "$_due")" >&2
    fi
    _expected=$_due
    sleep "$((_due - _now))"
done
