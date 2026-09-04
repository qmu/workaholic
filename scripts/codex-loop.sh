#!/bin/sh -eu
# The development loop, on the Codex CLI. This script IS the clock — the piece Claude Code
# supplies as `/loop 5m <command>` and Codex CLI/IDE have no equivalent for. The ChatGPT
# desktop app does: use a chat-bound Scheduled task there (`workaholic:work`). This script is
# deliberately the fallback for a CLI-only environment, not the preferred desktop clock.
#
# WHY IT EXISTS (2026-09-03). `/work` invokes Claude Code's `loop` skill and the tick spawns
# `propose`, `implement` and `moderate` as BACKGROUND subagents it never waits for. Diagnosed
# with the Codex CLI itself (`codex-cli 0.149.1`), four of those mechanisms have no Codex
# equivalent: the in-process recurring timer, `commands/*.md` as slash commands (both
# `.codex-plugin/plugin.json` manifests expose `"skills"` and nothing else, so `/work` and
# `/infinite-development` are not reachable there at all), `ListAgents` as a concurrency
# registry, and a DETACHED subagent whose parent ends while it keeps running — Codex has
# concurrent subagents, but the parent collects their results.
#
# SO THE LOOP IS SEQUENTIAL HERE, AND THAT IS THE ONE REAL DIFFERENCE. One `codex exec` per
# tick, each running to completion before the next starts. THE COST IS STATED RATHER THAN
# HIDDEN: under Claude Code a person's Slack message is answered within five minutes whatever
# the work is doing, because the work is detached. Here the answer comes at the TOP of each
# tick (the Slack turn is the tick's first act), so the worst case is one tick's own work
# duration, not the interval. Splitting it into a second concurrently-scheduled loop was
# refused by name: this repository retired exactly that shape on 2026-09-03 — three loops meant
# three places to look and no place that held the whole loop.
#
# CONCURRENCY IS STRUCTURAL, NOT A REGISTRY. Ticks run one after another in this process, so
# two ticks cannot overlap; `flock` on the repository's own lock file stops two SUPERVISORS.
# Nothing here reads or writes a live-agent listing, because Codex has none across `exec` runs.
#
# THE CADENCES ARE THE SAME READERS THE CLAUDE TICK USES and are read INSIDE the tick, not
# here: `moderate/scripts/log-read.sh --step-prefix loop-finish-<name> --latest-tick` over the
# git-ignored tick log. That machinery never depended on an agent listing, which is why the
# port needs no second store, cursor or field.
#
# THE ENVIRONMENT IS EXPORTED HERE because Codex does not read `.claude/settings.json`. Its
# `env` block is this repository's one declaration of `WORKAHOLIC_*` values, so the supervisor
# reads that same block and exports it — one declaration, two agents, no drift. An absent or
# unparseable file exports nothing and says so; every variable already in the environment WINS,
# so a caller can override any of them on the command line.
#
# Usage: sh scripts/codex-loop.sh [--interval <seconds>] [--once] [--dry-run] [--status] [--log <dir>]
#   --interval  seconds between the END of one tick and the START of the next (default 300)
#   --once      run exactly one tick and exit (what a cron or systemd timer wants)
#   --dry-run   print the command that would run, execute nothing
#   --status    read the current durable loop status; start no process
#   --log       directory for per-tick transcripts (default <repo>/.codex-loop, git-ignored)
#
# Stop it with Ctrl-C, or `pkill -f codex-loop.sh`. A tick already running finishes first.

INTERVAL=300
ONCE=false
DRY_RUN=false
STATUS_ONLY=false
LOG_DIR=""

while [ $# -gt 0 ]; do
    case "$1" in
        --interval) INTERVAL="${2:-300}"; shift 2 ;;
        --once)     ONCE=true; shift ;;
        --dry-run)  DRY_RUN=true; shift ;;
        --status)   STATUS_ONLY=true; shift ;;
        --log)      LOG_DIR="${2:-}"; shift 2 ;;
        -h|--help)  sed -n '2,50p' "$0"; exit 0 ;;
        *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done

case "$INTERVAL" in ''|*[!0-9]*) printf 'interval must be whole seconds\n' >&2; exit 2 ;; esac

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$REPO_ROOT" ] || { printf 'not inside a git repository\n' >&2; exit 2; }
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

command -v codex >/dev/null 2>&1 || { printf 'the codex CLI is not on PATH\n' >&2; exit 2; }

TICK_PROMPT="${REPO_ROOT}/plugins/workaholic/skills/work/SKILL.md"
[ -f "$TICK_PROMPT" ] || { printf 'the work skill is missing: %s\n' "$TICK_PROMPT" >&2; exit 2; }

# ── The declared environment, read from the repository's one declaration ──────────────
# Already-set values win, so `WORKAHOLIC_WIP_LIMIT=0 sh scripts/codex-loop.sh` overrides.
SETTINGS="${REPO_ROOT}/.claude/settings.json"
ENV_SOURCE="none"
if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
    if _pairs=$(jq -r '(.env // {}) | to_entries[] | "\(.key)=\(.value)"' "$SETTINGS" 2>/dev/null); then
        ENV_SOURCE="settings"
        for _pair in $_pairs; do
            _k=${_pair%%=*}
            _v=${_pair#*=}
            case "$_k" in
                # Claude-Code-only knobs mean nothing to Codex and are not exported.
                CLAUDE_*) continue ;;
            esac
            # `eval` on a name we matched against a safe shape, never on the value.
            case "$_k" in
                [A-Za-z_][A-Za-z0-9_]*) ;;
                *) continue ;;
            esac
            eval "_cur=\${${_k}:-}"
            [ -n "${_cur}" ] || { export "${_k}=${_v}"; }
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
    # THE PROMPT IS A POINTER, NEVER A COPY OF THE CONTRACT. `workaholic:work` is the one
    # place the loop is written down and BOTH agents read it -- Claude Code through `/work`,
    # every other agent as a published skill. A prompt that restated it would be a second,
    # drifting ceiling, which is the same reason a routine's prompt here is a thin pointer.
    _prompt="Read ${TICK_PROMPT} in full and execute exactly one tick of the development loop as it specifies, applying its substitutions for an agent with no interval feature and no background subagents. Do not loop; end after one tick. Report the tick's own report block as your final message."
    if [ "$DRY_RUN" = true ]; then
        printf 'codex exec -C %s --dangerously-bypass-approvals-and-sandbox --output-last-message %s <prompt>\n' \
            "$REPO_ROOT" "$_out"
        return 0
    fi
    write_status running running "" "$_stamp" "$_started" "" "$_out" "$_transcript" unknown ""
    # `--dangerously-bypass-approvals-and-sandbox` is the Codex equivalent of the loop
    # session's own `--dangerously-skip-permissions`, and it is required rather than
    # convenient: an unattended run never waits for a person, the tick pushes branches and
    # calls `gh`, and `workspace-write` refuses both. The bound is the same one the Claude
    # loop accepts — this runs on a machine the operator owns.
    if codex exec \
          -C "$REPO_ROOT" \
          --dangerously-bypass-approvals-and-sandbox \
          -c shell_environment_policy.inherit=all \
          --output-last-message "$_out" \
          "$_prompt" >"$_transcript" 2>&1; then
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

# ── The lock: one supervisor per repository ──────────────────────────────────────────
# Held for the LIFE OF THE SUPERVISOR rather than of a tick, because what it prevents is a
# SECOND CLOCK — two ticks overlapping is already impossible, since this process runs them one
# after another. Taken on a file descriptor so the lock is released by the process exiting and
# needs no teardown path of its own. Without `flock` installed the loop still runs and SAYS SO;
# refusing there would park the loop over a reading rather than over a fact.
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
