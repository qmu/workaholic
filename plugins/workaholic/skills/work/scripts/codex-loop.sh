#!/bin/sh -eu
# Plugin-owned external clock for Codex CLI/IDE. Repository entrypoints are thin shims.

INTERVAL=300
ONCE=false
DRY_RUN=false
STATUS_ONLY=false
STATUS_JSON=false
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
        --json) STATUS_JSON=true; shift ;;
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
                '  --json      with --status, render the composed reading as JSON' \
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
WORKER_SCHEMA="${SCRIPT_DIR}/worker-result.schema.json"
# ONE SENTENCE, SHARED BY THE TICK AND EVERY WORKER, so the four facts are asked for in one
# wording. `executed` is the fact the exit status used to stand in for, and the run grades itself
# with the token its own command body derives rather than with a word of its choosing.
RESULT_CLAUSE="Return your result as a JSON object matching the supplied schema: \`executed\` true only if you actually read that command body and performed it, \`outcome\` the terminal token the command body itself derives, \`reason\` naming what stopped or withheld it (empty when the outcome is ok), and \`report\` carrying the run's own report block verbatim."

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
SUPERVISOR_FILE="${LOG_DIR}/supervisor.json"
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

# THE SUPERVISOR SAYS WHETHER IT EVER STARTED, FROM THE DIRECTORY ALONE (2026-09-06, mission
# `finish-the-codex-external-process-and-make-its-state-inspectable`). `write_status` runs first
# inside `run_tick`, so a supervisor killed during startup — or one whose `codex exec` never
# returned — left the directory exactly as empty as one that was never launched, and
# `show_status` printed `absent` for both. MEASURED on the operator's machine: `.codex-loop/`
# created at 09:31:48 with `mtime == Birth`, so nothing was ever written into it, while a
# supervisor was believed to be turning; it was in fact driving a different repository entirely.
#
# ABSENT MEANS NEVER STARTED, and that stays true: a directory with no supervisor record is
# byte-identical to one before this existed, so a repository that never runs the Codex path is
# unaffected.
#
# A PID IS NOT A PROOF ACROSS A REBOOT, so the record carries the boot id and the reading says
# what it cannot establish rather than claiming liveness. A pid that is gone proves the process
# is gone whatever the boot id says; a pid that is alive under a *different* boot id is a
# recycled number and the process is gone; a pid that is alive with no boot id readable on
# either side cannot be told from a recycled one, and that reads `unreadable:boot_unverifiable`
# — never `running`. This is the same rule every other three-valued reader here holds: an
# absence of a reading is never a healthy one.
json_quote() {
    if command -v jq >/dev/null 2>&1; then
        jq -Rn --arg value "$1" '$value'
    else
        printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/'
    fi
}

boot_id() {
    [ -r /proc/sys/kernel/random/boot_id ] || { printf ''; return 0; }
    tr -d '\n' </proc/sys/kernel/random/boot_id 2>/dev/null || printf ''
}

pid_alive() {
    case "$1" in ''|*[!0-9]*) return 1 ;; esac
    if [ -d /proc ]; then [ -d "/proc/$1" ]; return $?; fi
    kill -0 "$1" 2>/dev/null
}

# ONE DERIVATION OF *IS THE PROCESS THAT WROTE THIS RECORD STILL THE ONE RUNNING*, read by the
# supervisor record and by every per-role record. A second copy is how the two would come to
# disagree about what a live pid proves. The rungs are ordered so the sound one is taken first:
# a pid that is GONE proves the process is gone whatever the boot id says, while a pid that is
# ALIVE proves nothing without one — which is why a platform exposing no boot id degrades only
# in the ambiguous case rather than in every case.
#   alive | gone | reboot | unverifiable
liveness_reading() {
    _lv_pid=$1 _lv_boot=$2
    pid_alive "$_lv_pid" || { printf 'gone'; return 0; }
    _lv_now=$(boot_id)
    if [ -n "$_lv_boot" ] && [ -n "$_lv_now" ]; then
        [ "$_lv_boot" = "$_lv_now" ] && { printf 'alive'; return 0; }
        printf 'reboot'; return 0
    fi
    printf 'unverifiable'
}

# One word, derived from the file alone — no lock, no live probe of anything but the pid.
supervisor_reading() {
    [ -f "$SUPERVISOR_FILE" ] || { printf 'never_started'; return 0; }
    command -v jq >/dev/null 2>&1 || { printf 'unreadable:jq_missing'; return 0; }
    jq -e 'type == "object" and (.state | type == "string") and (.pid | type == "string")' \
        "$SUPERVISOR_FILE" >/dev/null 2>&1 || { printf 'unreadable:malformed'; return 0; }
    _sv_state=$(jq -r '.state' "$SUPERVISOR_FILE" 2>/dev/null || printf '')
    if [ "$_sv_state" = stopped ]; then
        _sv_reason=$(jq -r '.stopped_reason // ""' "$SUPERVISOR_FILE" 2>/dev/null || printf '')
        [ -n "$_sv_reason" ] || _sv_reason=unstated
        printf 'stopped:%s' "$_sv_reason"; return 0
    fi
    [ "$_sv_state" = running ] || { printf 'unreadable:unknown_state'; return 0; }
    _sv_pid=$(jq -r '.pid' "$SUPERVISOR_FILE" 2>/dev/null || printf '')
    _sv_boot=$(jq -r '.boot_id // ""' "$SUPERVISOR_FILE" 2>/dev/null || printf '')
    case "$(liveness_reading "$_sv_pid" "$_sv_boot")" in
        alive)  printf 'running' ;;
        gone)   printf 'stopped_unclean' ;;
        reboot) printf 'stopped_unclean:reboot' ;;
        *)      printf 'unreadable:boot_unverifiable' ;;
    esac
}

# THE WORKER'S STATE AND LAST OUTCOME ARE DATA IN THE DIRECTORY, NOT A LIVE LOCK PROBE
# (2026-09-06, mission `finish-the-codex-external-process-and-make-its-state-inspectable`).
# `role_state` answers only whether a lock is held **at this instant**, so *idle because it
# finished cleanly* and *idle because it failed forty minutes ago* were one word; and the outcome
# was read from the moderate tick log — `.workaholic/moderations/`, a different tree on a
# different path, written by whichever loop last ran — so a machine running the Claude loop
# reported the Claude loop's workers under `codex worker <role>`.
#
# THE LOCK REMAINS THE ONLY CONCURRENCY AUTHORITY. This record is evidence beside it: nothing
# refuses, starts or reaps a worker by reading it, and the dispatch refusal still reads
# `role_state` alone.
role_record() { printf '%s/worker-%s.json' "$LOG_DIR" "$1"; }

worker_reading() {
    _wr_file=$(role_record "$1")
    [ -f "$_wr_file" ] || { printf 'never_dispatched'; return 0; }
    command -v jq >/dev/null 2>&1 || { printf 'unreadable:jq_missing'; return 0; }
    jq -e 'type == "object" and (.state | type == "string") and (.pid | type == "string")' \
        "$_wr_file" >/dev/null 2>&1 || { printf 'unreadable:malformed'; return 0; }
    _wr_state=$(jq -r '.state' "$_wr_file" 2>/dev/null || printf '')
    if [ "$_wr_state" = finished ]; then
        _wr_out=$(jq -r '.outcome // ""' "$_wr_file" 2>/dev/null || printf '')
        [ -n "$_wr_out" ] || _wr_out=unreadable:unrecorded_outcome
        printf 'finished:%s' "$_wr_out"; return 0
    fi
    [ "$_wr_state" = running ] || { printf 'unreadable:unknown_state'; return 0; }
    _wr_pid=$(jq -r '.pid' "$_wr_file" 2>/dev/null || printf '')
    _wr_boot=$(jq -r '.boot_id // ""' "$_wr_file" 2>/dev/null || printf '')
    case "$(liveness_reading "$_wr_pid" "$_wr_boot")" in
        alive)  printf 'running' ;;
        gone)   printf 'died_unrecorded' ;;
        reboot) printf 'died_unrecorded:reboot' ;;
        *)      printf 'unreadable:boot_unverifiable' ;;
    esac
}

show_supervisor() {
    _sv_read=$(supervisor_reading)
    case "$_sv_read" in
        never_started)
            printf 'codex supervisor: never_started (%s)\n' "$SUPERVISOR_FILE" ;;
        *)
            _sv_detail=""
            if [ -f "$SUPERVISOR_FILE" ] && command -v jq >/dev/null 2>&1; then
                _sv_detail=$(jq -r '" pid=\(.pid // "") started_at=\(.started_at // "") interval=\(.interval // "")"' \
                    "$SUPERVISOR_FILE" 2>/dev/null || printf '')
            fi
            printf 'codex supervisor: %s%s\n' "$_sv_read" "$_sv_detail" ;;
    esac
}

# The last tick's own three-valued reading, derived ONCE and read by the human renderer and the
# composed one alike. `absent` and `unreadable:<reason>` are different facts and neither is a
# healthy tick.
tick_reading() {
    [ -f "$STATUS_FILE" ] || { printf 'absent'; return 0; }
    command -v jq >/dev/null 2>&1 || { printf 'unreadable:jq_missing'; return 0; }
    jq -e . "$STATUS_FILE" >/dev/null 2>&1 || { printf 'unreadable:malformed'; return 0; }
    printf 'readable'
}

show_status() {
    _ss_read=$(tick_reading)
    if [ "$_ss_read" = absent ]; then
        printf 'codex loop status: absent (%s)\n' "$STATUS_FILE"
        return 4
    fi
    if [ "$_ss_read" = readable ]; then
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

# A ROLE'S LINE CARRIES WHAT THE WORKER REPORTED, NOT WHAT THE COORDINATOR GUESSED (2026-09-06,
# mission `finish-the-backlog-without-handing-it-back-to-the-operator`). `role_state` answers only
# whether a process is holding the lock right now, which says nothing about whether the last run
# executed or what became of it — so the periodic report was composed from liveness alone. The
# outcome is read back from the tick log's own `loop-attempt-<role>` line, the record that keeps
# the four facts apart, and a role with **no** recorded attempt is named `unrecorded` rather than
# rendered as a healthy finish.
last_worker_outcome() {
    _lw_read="${SCRIPT_DIR}/../../moderate/scripts/log-read.sh"
    [ -f "$_lw_read" ] || { printf 'unreadable:no_log_reader'; return 0; }
    command -v jq >/dev/null 2>&1 || { printf 'unreadable:jq_missing'; return 0; }
    _lw_json=$(sh "$_lw_read" --step-prefix "loop-attempt-$1" --latest-tick 2>/dev/null || true)
    [ -n "$_lw_json" ] || { printf 'unreadable:no_log'; return 0; }
    printf '%s' "$_lw_json" | jq -e '.read == true' >/dev/null 2>&1 \
        || { printf 'unreadable:log_unreadable'; return 0; }
    [ "$(printf '%s' "$_lw_json" | jq -r '.entries | length' 2>/dev/null || printf 0)" -gt 0 ] \
        || { printf 'unrecorded'; return 0; }
    # The summary is `<role> attempted (<outcome>)`; the outcome is what is inside the brackets.
    _lw_out=$(printf '%s' "$_lw_json" \
        | jq -r '[.entries[].summary] | last // ""' 2>/dev/null \
        | sed -n 's/.*attempted (\([^)]*\)).*/\1/p')
    [ -n "$_lw_out" ] || _lw_out=unreadable:unparseable_attempt
    printf '%s' "$_lw_out"
}

# THREE SOURCES, KEPT VISIBLY APART. `lock` is the live concurrency authority, `record` is this
# role's own state and last outcome from the directory, and `last_outcome` is the moderate tick
# log the cadence readers use. They answer different questions and one word for all three is what
# made a failed run indistinguishable from a clean one.
show_workers() {
    for _r in $ROLES; do
        printf 'codex worker %s: %s record=%s last_outcome=%s\n' \
            "$_r" "$(role_state "$_r")" "$(worker_reading "$_r")" "$(last_worker_outcome "$_r")"
    done
    # WHERE A REPORT ARRIVES AND WHERE IT DOES NOT, named rather than left to be discovered. An
    # absent delivery path is never substituted for one that delivers somewhere else.
    printf 'codex loop reports: dir=%s chat_return=none\n' "$LOG_DIR"
}

# ONE QUESTION, ONE ANSWER, FROM THE DIRECTORY ALONE (2026-09-06, mission
# `finish-the-codex-external-process-and-make-its-state-inspectable`). `--status` gave two half
# answers from two sources — `show_status` read `status.json` and `show_workers` probed each
# role's lock live — so the supervisor's state and the workers' were neither composed nor
# readable by anything that was not this script. A later tick, `/moderate`, or a person with a
# shell and no `codex` CLI could not ask *is the Codex loop turning, and what is it doing* and
# get one answer.
#
# COMPOSED, NEVER RE-DERIVED. Every reading here belongs to a function above:
# `supervisor_reading`, `worker_reading`, `role_state`, `last_worker_outcome`, `tick_reading`.
# This adds no state and no second derivation of anything.
#
# EVERY PART NAMES ITS OWN DEGRADATION IN PLACE. A missing supervisor record, an unreadable role
# record and a malformed `status.json` are three distinct readings; none renders as healthy and
# none is silently omitted — an unreadable part carries its reason and **null** details, never a
# default that looks like a healthy value.
status_json_field() {
    # One field out of the tick's status file, or the empty string when it is not readable.
    [ "$1" = readable ] || { printf ''; return 0; }
    jq -r --arg k "$2" '.[$k] // ""' "$STATUS_FILE" 2>/dev/null || printf ''
}

json_or_null() {
    [ -n "$1" ] || { printf 'null'; return 0; }
    json_quote "$1"
}

show_status_json() {
    _sj_tick=$(tick_reading)
    _sj_sup=$(supervisor_reading)
    printf '{\n'
    printf '  "log_dir": %s,\n' "$(json_quote "$LOG_DIR")"
    printf '  "supervisor": {\n'
    printf '    "reading": %s,\n' "$(json_quote "$_sj_sup")"
    if [ -f "$SUPERVISOR_FILE" ] && command -v jq >/dev/null 2>&1; then
        printf '    "pid": %s,\n' "$(json_or_null "$(jq -r '.pid // ""' "$SUPERVISOR_FILE" 2>/dev/null || printf '')")"
        printf '    "started_at": %s,\n' "$(json_or_null "$(jq -r '.started_at // ""' "$SUPERVISOR_FILE" 2>/dev/null || printf '')")"
        printf '    "interval": %s\n' "$(json_or_null "$(jq -r '.interval // ""' "$SUPERVISOR_FILE" 2>/dev/null || printf '')")"
    else
        printf '    "pid": null,\n    "started_at": null,\n    "interval": null\n'
    fi
    printf '  },\n'
    printf '  "tick": {\n'
    printf '    "reading": %s,\n' "$(json_quote "$_sj_tick")"
    printf '    "tick_id": %s,\n' "$(json_or_null "$(status_json_field "$_sj_tick" tick_id)")"
    printf '    "state": %s,\n' "$(json_or_null "$(status_json_field "$_sj_tick" state)")"
    printf '    "outcome": %s,\n' "$(json_or_null "$(status_json_field "$_sj_tick" outcome)")"
    printf '    "blocked_reason": %s,\n' "$(json_or_null "$(status_json_field "$_sj_tick" blocked_reason)")"
    printf '    "finished_at": %s,\n' "$(json_or_null "$(status_json_field "$_sj_tick" finished_at)")"
    printf '    "next_due": %s,\n' "$(json_or_null "$(status_json_field "$_sj_tick" next_due)")"
    printf '    "report_path": %s\n' "$(json_or_null "$(status_json_field "$_sj_tick" report_path)")"
    printf '  },\n'
    printf '  "workers": [\n'
    _sj_first=true
    for _sj_r in $ROLES; do
        [ "$_sj_first" = true ] || printf ',\n'
        _sj_first=false
        printf '    {"role": %s, "lock": %s, "record": %s, "last_outcome": %s}' \
            "$(json_quote "$_sj_r")" "$(json_quote "$(role_state "$_sj_r")")" \
            "$(json_quote "$(worker_reading "$_sj_r")")" \
            "$(json_quote "$(last_worker_outcome "$_sj_r")")"
    done
    printf '\n  ],\n'
    printf '  "reports": {"dir": %s, "chat_return": "none"}\n' "$(json_quote "$LOG_DIR")"
    printf '}\n'
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
    # ONE INVOCATION, ONE ANSWER. `--json` renders the composed reading for a machine; without it
    # the human lines are unchanged. Either way this branch starts nothing, writes nothing, takes
    # no lock and requires no `codex` CLI — it returns before the presence check and before the
    # `mkdir`, and the exit status is the tick's own (0 / 4 / 5) on both surfaces.
    if [ "$STATUS_JSON" = true ]; then
        show_status_json
        case "$(tick_reading)" in
            absent) exit 4 ;;
            readable) exit 0 ;;
            *) exit 5 ;;
        esac
    fi
    show_supervisor
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

# A RUN THAT WRITES NOTHING CREATES NOTHING (2026-09-06, the diagnosis's rows 3 and 4). The
# state directory used to be created twice: once inside the dispatch/worker branch **before** the
# `codex` presence check, and once here. So `--dispatch <role> --dry-run` — which starts nothing —
# and a dispatch on a machine with no `codex` CLI — which cannot start anything — each left an
# EMPTY `.codex-loop/`, indistinguishable from a supervisor that never started. MEASURED: that is
# the exact state on the operator's machine, reproduced byte-for-byte by the first of the two.
# The earlier `mkdir` is gone, and a dry-run dispatch takes none at all. The supervisor's own
# `--dry-run` still creates the directory and takes the lock; that residue is recorded as a
# separate finding and is not repaired here.
if [ "$DRY_RUN" != true ] || [ -z "${DISPATCH_ROLE}${WORKER_ROLE}" ]; then
    mkdir -p "$LOG_DIR"
fi

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

# The same atomic tmp-then-mv shape `write_status` uses, on the supervisor's own record. `pid` is
# written as a string so `supervisor_reading`'s schema check is one type test.
SUPERVISOR_STARTED=""
SUPERVISOR_BOOT=""
write_supervisor() {
    _sv_w_state=$1 _sv_w_reason=$2
    _sv_w_tmp="${SUPERVISOR_FILE}.tmp.$$"
    {
        printf '{\n'
        printf '  "state": %s,\n' "$(json_quote "$_sv_w_state")"
        printf '  "stopped_reason": %s,\n' "$(json_quote "$_sv_w_reason")"
        printf '  "pid": %s,\n' "$(json_quote "$$")"
        printf '  "boot_id": %s,\n' "$(json_quote "$SUPERVISOR_BOOT")"
        printf '  "started_at": %s,\n' "$(json_quote "$SUPERVISOR_STARTED")"
        printf '  "interval": %s,\n' "$(json_quote "$INTERVAL")"
        printf '  "anchor": %s,\n' "$(json_quote "${LOOP_ANCHOR:-}")"
        printf '  "once": %s,\n' "$(json_quote "$ONCE")"
        printf '  "log_dir": %s\n' "$(json_quote "$LOG_DIR")"
        printf '}\n'
    } >"$_sv_w_tmp"
    mv "$_sv_w_tmp" "$SUPERVISOR_FILE"
}

# The same atomic shape again, per role. `exit_status` and `outcome` are recorded SEPARATELY and
# both are kept: a process that terminated and a role that did the work are two facts, and the
# exit status standing in for both is the defect this closes. `outcome` is `worker_outcome`'s own
# word, derived from the worker's report through the schema — never from the exit status alone
# and never from words grepped out of prose — so a report that cannot be read records
# `unreadable:<reason>` rather than inferring success.
write_worker_record() {
    _ww_role=$1 _ww_state=$2 _ww_tick=$3 _ww_started=$4 _ww_finished=$5
    _ww_exit=$6 _ww_outcome=$7 _ww_report=$8 _ww_transcript=$9
    _ww_file=$(role_record "$_ww_role")
    _ww_tmp="${_ww_file}.tmp.$$"
    {
        printf '{\n'
        printf '  "role": %s,\n' "$(json_quote "$_ww_role")"
        printf '  "state": %s,\n' "$(json_quote "$_ww_state")"
        printf '  "tick": %s,\n' "$(json_quote "$_ww_tick")"
        printf '  "started_at": %s,\n' "$(json_quote "$_ww_started")"
        printf '  "finished_at": %s,\n' "$(json_quote "$_ww_finished")"
        printf '  "exit_status": %s,\n' "$(json_quote "$_ww_exit")"
        printf '  "outcome": %s,\n' "$(json_quote "$_ww_outcome")"
        printf '  "report_path": %s,\n' "$(json_quote "$_ww_report")"
        printf '  "transcript_path": %s,\n' "$(json_quote "$_ww_transcript")"
        printf '  "pid": %s,\n' "$(json_quote "$$")"
        printf '  "boot_id": %s\n' "$(json_quote "$(boot_id)")"
        printf '}\n'
    } >"$_ww_tmp"
    mv "$_ww_tmp" "$_ww_file"
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
    else
        # THE DEFAULT IS A READING, NOT AN ASSUMPTION (2026-09-06, mission
        # `finish-the-backlog-without-handing-it-back-to-the-operator`). `ready` used to be what a
        # report got for matching none of the patterns above, so a report that said nothing this
        # function knows how to read — including one from a run that never executed — was graded a
        # healthy tick. The rungs above are UNCHANGED and still fire first; only the fall-through
        # moved, and it now asks the report itself through the same schema-constrained reading the
        # workers use. An absence of a reading is never a healthy run.
        _tick_outcome_word=$(worker_outcome "$_report_file" 0)
        case "$_tick_outcome_word" in
            ok) : ;;
            unreadable:*)
                TICK_OUTCOME=report_unreadable
                BLOCKED_REASON="$_tick_outcome_word"
                TRANSPORT_VERDICT=unknown ;;
            *)
                TICK_OUTCOME=work_blocked
                BLOCKED_REASON="$_tick_outcome_word" ;;
        esac
    fi
}

CURRENT_TICK=""
CURRENT_STARTED=""
CURRENT_REPORT=""
CURRENT_TRANSCRIPT=""
on_interrupt() {
    # THE STOP IS RECORDED BEFORE THE TICK GUARD, so an interrupt taken *outside* a tick — the
    # window between the lock and `run_tick`'s first `write_status`, and the window after a tick
    # cleared `CURRENT_TICK` — is a stop the directory can see. That window is collapse row 7 of
    # the diagnosis: it used to `exit 130` writing nothing at all.
    [ -z "$SUPERVISOR_STARTED" ] || write_supervisor stopped interrupted
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
    _prompt="Read ${TICK_PROMPT} in full and execute exactly one tick of the development loop as it specifies, applying its substitutions for an agent with no interval feature. You are the coordinator: answer the inbound channel yourself, then start each DUE work run in the background with 'sh ${SCRIPT_DIR}/codex-loop.sh --dispatch <implement|propose|moderate>', which returns at once and refuses a role already running. Never run that work inline and never wait for a dispatched worker. Do not loop; end after one tick. ${RESULT_CLAUSE}"
    if [ "$RELAY" = true ]; then
        _prompt="${_prompt} You are a connector-less worker with a connector-owning parent waiting for this result. Read ${PLUGIN_ROOT}/skills/work/reference/codex-slack-relay.md and return only one workaholic.codex-slack-relay/v1 JSON envelope. Represent every earned Slack action as an ordered intent; call no connector, include no credential, and never claim an intent was delivered."
    fi
    if [ "$DRY_RUN" = true ]; then
        printf 'codex exec -C %s --dangerously-bypass-approvals-and-sandbox --output-last-message %s %s\n' "$REPO_ROOT" "$_out" "$_prompt"
        return 0
    fi
    write_status running running "" "$_stamp" "$_started" "" "$_out" "$_transcript" unknown ""
    # The tick reports through the same schema its workers do, so `classify_report`'s default is
    # a reading rather than an assumption. The relay path keeps its own envelope and takes none.
    if [ "$RELAY" != true ] && [ -f "$WORKER_SCHEMA" ]; then
        set -- --output-schema "$WORKER_SCHEMA"
    else
        set --
    fi
    if codex exec -C "$REPO_ROOT" --dangerously-bypass-approvals-and-sandbox \
        -c shell_environment_policy.inherit=all "$@" --output-last-message "$_out" "$_prompt" \
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

# FOUR FACTS, FOUR PIECES OF EVIDENCE (2026-09-06, mission
# `finish-the-backlog-without-handing-it-back-to-the-operator`). The finish was written from the
# **process exit status** and nothing else, so a worker that exited zero while reporting it could
# not execute recorded a healthy finish and the cadence counted the role done — MEASURED by
# shimming exactly that worker. *The process terminated*, *the role was executed*, *the work
# completed* and *the notification was delivered* are four different facts, and one of them was
# standing in for all four.
#
# THE OUTCOME COMES FROM WHAT THE WORKER REPORTED, not from its exit status and not from words
# grepped out of prose. `codex exec --output-schema` constrains the final message to
# `worker-result.schema.json` — CONFIRMED against the installed CLI rather than assumed:
# `codex-cli 0.153.4` lists `--output-schema <FILE>`, `--output-last-message <FILE>` and `--json`.
# This extends the relay path's envelope validation rather than adding a second mechanism: the
# non-relay path had no structured result at all, and now it has one.
#
# AN ABSENCE OF A READING IS NEVER A HEALTHY RUN. A report that is missing, empty, not JSON or
# missing a required field reads `unreadable:<reason>` — never `ok` — the same rule every other
# three-valued reader in this repository holds.
worker_outcome() {
    _wo_report=$1 _wo_exit=$2
    [ "$_wo_exit" -eq 0 ] || { printf 'failed:codex_exit_%s' "$_wo_exit"; return 0; }
    [ -s "$_wo_report" ] || { printf 'unreadable:no_report'; return 0; }
    command -v jq >/dev/null 2>&1 || { printf 'unreadable:jq_missing'; return 0; }
    jq -e 'type == "object" and (.executed | type == "boolean")
           and (.outcome | type == "string") and (.report | type == "string")' \
        "$_wo_report" >/dev/null 2>&1 || { printf 'unreadable:unparseable_report'; return 0; }
    _wo_reason=$(jq -r '.reason // ""' "$_wo_report" 2>/dev/null || printf '')
    [ -n "$_wo_reason" ] || _wo_reason=unstated
    if [ "$(jq -r '.executed' "$_wo_report" 2>/dev/null || printf false)" != true ]; then
        printf 'not_executed:%s' "$_wo_reason"; return 0
    fi
    case "$(jq -r '.outcome' "$_wo_report" 2>/dev/null || printf '')" in
        ok|pending) printf 'ok' ;;
        blocked)    printf 'blocked:%s' "$_wo_reason" ;;
        failed)     printf 'failed:%s' "$_wo_reason" ;;
        *)          printf 'unreadable:unknown_outcome' ;;
    esac
}

# THE ATTEMPT AND THE OUTCOME ARE RECORDED SEPARATELY, AND THE LINE SAYS WHICH IT CARRIES.
# `loop-attempt-<role>` is written for EVERY run and says what became of it; `loop-finish-<role>`
# — the line the cadence reads, whose reader is untouched — is written only for a run that
# actually executed, so a worker that did nothing leaves its role DUE rather than counted done.
#
# THE RETRY IS BOUNDED HERE RATHER THAN AT THE CALL SITE, because a role left due by every failed
# attempt would otherwise retry on every tick forever. After `WORKAHOLIC_WORKER_ATTEMPT_MAX`
# consecutive unhealthy attempts (default **3**) the finish line IS written, naming the outcome,
# so the role falls back to its ordinary cadence instead of spinning. `0` means no bound — retry
# on every tick — and a non-numeric or negative value falls back to 3 rather than holding
# anything, the rule every declared number in this loop already follows.
#
# `log-append.sh` REMAINS THE ONE WRITER and its `(tick, step)` idempotence is untouched.
record_worker_finish() {
    _rw_role=$1 _rw_outcome=$2
    _tick_id_sh="${SCRIPT_DIR}/../../moderate/scripts/tick-id.sh"
    _log_append_sh="${SCRIPT_DIR}/../../moderate/scripts/log-append.sh"
    _log_read_sh="${SCRIPT_DIR}/../../moderate/scripts/log-read.sh"
    [ -f "$_tick_id_sh" ] && [ -f "$_log_append_sh" ] || return 0
    _tick=$(sh "$_tick_id_sh" 2>/dev/null || true)
    [ -n "$_tick" ] || return 0

    _rw_status=ok
    [ "$_rw_outcome" = ok ] || _rw_status=blocked
    sh "$_log_append_sh" --tick "$_tick" --step "loop-attempt-${_rw_role}" \
        --status "$_rw_status" --summary "${_rw_role} attempted (${_rw_outcome})" \
        >/dev/null 2>&1 || true

    if [ "$_rw_outcome" = ok ]; then
        sh "$_log_append_sh" --tick "$_tick" --step "loop-finish-${_rw_role}" \
            --status ok --summary "${_rw_role} finished (${_rw_outcome})" >/dev/null 2>&1 || true
        return 0
    fi

    _rw_max=${WORKAHOLIC_WORKER_ATTEMPT_MAX:-3}
    case "$_rw_max" in ''|*[!0-9]*) _rw_max=3 ;; esac
    [ "$_rw_max" -eq 0 ] && return 0
    [ -f "$_log_read_sh" ] || return 0
    _rw_seen=$(sh "$_log_read_sh" --step-prefix "loop-attempt-${_rw_role}" --status blocked \
        2>/dev/null | grep -c . || true)
    case "$_rw_seen" in ''|*[!0-9]*) _rw_seen=0 ;; esac
    if [ "$_rw_seen" -ge "$_rw_max" ]; then
        sh "$_log_append_sh" --tick "$_tick" --step "loop-finish-${_rw_role}" \
            --status blocked \
            --summary "${_rw_role} not executed ${_rw_seen} times (${_rw_outcome}); held to its ordinary cadence" \
            >/dev/null 2>&1 || true
    fi
}

# THE PROMPT IS PER ROLE, BECAUSE THE ROLES ARE NOT THE SAME JOB (2026-09-06, mission
# `finish-the-backlog-without-handing-it-back-to-the-operator`). One generic string named
# `commands/<role>.md` and forbade every worker from touching the channel, and both halves of
# that were wrong for a role. MEASURED, verbatim, from `--worker propose --dry-run`: the prompt
# named `commands/propose.md` and nothing else, so a dispatched `propose` opened or refused a
# proposal and **nothing ingested it** — the routine's own contract is propose **then**
# specificate. And the blanket ban disabled `/moderate`'s `question-answers` and
# `thread-reconcile`, which read a thread they already hold a coordinate or a resolved lookup
# for; that is not a channel turn, and banning it cost the tick two steps for nothing.
#
# THE BOUNDARY IS STATED IN ONE PLACE and cited here rather than re-argued:
# `skills/work/reference/other-agents.md`, *Who owns the channel*. The coordinator owns the
# channel **turn** — reading the window, answering a message in it, filing an inbound ask,
# posting a receipt — and no worker does any of those. Reading or replying to a thread a step
# already identified is a different act and belongs to the step that identified it.
#
# EACH CLAUSE IS DERIVED FROM THE COMMAND BODY IT NAMES, so there is one source and not two: a
# clause points the worker at a command body to read, and never paraphrases what that body says.
role_clause() {
    case "$1" in
        propose)
            printf 'This role is the propose-then-specificate sequence the routine contract names: when %s is done, read %s/commands/specificate.md in full and execute it once as well, so an ask this run opens is ingested in the same run. The `only_the_loop_spoke` reading is handed in by the coordinator; with none handed in, treat it as `unreadable` and never take it yourself.' \
                "$ROLE_BODY" "$PLUGIN_ROOT" ;;
        moderate)
            printf 'Your `question-answers` and `thread-reconcile` steps read and reply into a thread they already hold a coordinate or a resolved lookup for. That is not the channel turn and it is yours to perform, exactly as %s/commands/moderate.md specifies it.' \
                "$PLUGIN_ROOT" ;;
        implement)
            printf 'Your per-unit finish line resolves its own thread by the stateless lookup carried in %s/commands/implement.md and posts into it. That is not the channel turn and it is yours to perform.' \
                "$PLUGIN_ROOT" ;;
        *) printf '' ;;
    esac
}

# ONE COMPOSER, read by the worker and by the dispatch's dry run alike. A second copy of this
# string is how the two would come to disagree about what a worker was told.
worker_prompt() {
    printf 'Read %s in full and execute it exactly once in this repository, applying the substitutions in %s/skills/work/SKILL.md for an agent with no background subagents. %s Do not loop and do not start another worker. The coordinator owns the channel turn — do not read the inbound channel window, answer a message in it, file an inbound ask or post a receipt; the boundary is stated in %s/skills/work/reference/other-agents.md. %s' \
        "$ROLE_BODY" "$PLUGIN_ROOT" "$(role_clause "$1")" "$PLUGIN_ROOT" "$RESULT_CLAUSE"
}

run_worker() {
    _role=$1
    _wstamp=$(date -u +%Y%m%dT%H%M%SZ)
    _wout="${LOG_DIR}/${_wstamp}-${_role}.md"
    _wlog="${LOG_DIR}/${_wstamp}-${_role}.log"
    _wprompt=$(worker_prompt "$_role")
    if [ "$DRY_RUN" = true ]; then
        printf 'codex exec -C %s --dangerously-bypass-approvals-and-sandbox --output-last-message %s %s\n' \
            "$REPO_ROOT" "$_wout" "$_wprompt"
        return 0
    fi
    # The schema is passed when the file is present; without it the run still happens and its
    # unstructured report reads `unreadable:unparseable_report`, which is the honest word and
    # never `ok`.
    if [ -f "$WORKER_SCHEMA" ]; then
        set -- --output-schema "$WORKER_SCHEMA"
    else
        set --
    fi
    _wstarted=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    write_worker_record "$_role" running "$_wstamp" "$_wstarted" "" "" "" "$_wout" "$_wlog"
    if codex exec -C "$REPO_ROOT" --dangerously-bypass-approvals-and-sandbox \
        -c shell_environment_policy.inherit=all "$@" --output-last-message "$_wout" "$_wprompt" \
        >"$_wlog" 2>&1; then _wexit=0; else _wexit=$?; fi
    _woutcome=$(worker_outcome "$_wout" "$_wexit")
    write_worker_record "$_role" finished "$_wstamp" "$_wstarted" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$_wexit" "$_woutcome" "$_wout" "$_wlog"
    # UNTOUCHED: the tick-log write the cadence readers depend on. This record is a second
    # surface beside it, never a replacement.
    record_worker_finish "$_role" "$_woutcome"
    printf 'codex worker %s: exit=%s outcome=%s report=%s\n' "$_role" "$_wexit" "$_woutcome" "$_wout"
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
        # THE DRY RUN SHOWS THE PROMPT IT WOULD DISPATCH. It printed one line naming neither the
        # role body nor the clause, so the composed prompt — the thing a reader needs to check —
        # was visible only through `--worker <role> --dry-run`, one layer down and easy to run
        # for real by mistake. The dispatch starts nothing either way.
        printf 'codex dispatch %s: would start a detached worker\n' "$DISPATCH_ROLE"
        printf 'prompt: %s\n' "$(worker_prompt "$DISPATCH_ROLE")"
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
    # WHERE THE RESULT WILL AND WILL NOT ARRIVE, said at the moment the child is detached
    # (2026-09-06, mission `finish-the-backlog-without-handing-it-back-to-the-operator`). This
    # returns instantly and the child outlives it — the lifetime the port needed, and the exact
    # reason no result can come back through the process that returned.
    printf 'codex dispatch %s: report=%s chat_return=none\n' "$DISPATCH_ROLE" "$LOG_DIR"
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
# THE RECORD IS WRITTEN BEFORE THE FIRST TICK, which is the whole point: from here on, an
# absent record means never started and a present one means this supervisor got as far as
# owning the lock. `SUPERVISOR_STARTED` is also the flag `on_interrupt` reads to know whether
# there is a record to close.
SUPERVISOR_STARTED=$(iso_from_epoch "$LOOP_ANCHOR")
SUPERVISOR_BOOT=$(boot_id)
write_supervisor running ""
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
            write_supervisor stopped readiness_refused
            printf 'codex loop readiness refused; use --status for the recorded reason\n' >&2
            exit 6
        fi
        printf 'codex loop: ready interval=%ss once=%s env=%s log=%s\n' \
            "$INTERVAL" "$ONCE" "$ENV_SOURCE" "$LOG_DIR" >&2
    fi
    if [ "$ONCE" = true ]; then
        write_supervisor stopped completed_once
        break
    fi
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
