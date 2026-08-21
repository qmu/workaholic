#!/bin/sh -eu
# Run one `/moderate` tick: every step in order, one log line each, one report.
#
# WHY IT EXISTS (2026-08-17, issue #471). Nine steps in an hourly unattended run
# is a long tick, and the failure that matters is not a step going wrong — it is a
# step going quiet. So the orchestration is a script rather than prose: the step
# list is fixed here, every step is invoked, and every step contributes exactly one
# line to the report and one line to the tick log, including the ones that did not
# run. A step that is missing, crashes, or prints nothing is reported `degraded`
# with the reason — never dropped from the list, which is what would make a
# half-run tick read like a clean one.
#
# ONE WRITER. Step scripts print their verdict and write nothing to the log; this
# script logs. Two writers would race on (tick, step) and make the log's
# idempotence a property of the caller's discipline instead of the code's.
#
# WHAT A STEP MAY NOT DO HERE. A step script is non-interactive and composes no
# prose: it probes, decides, and — where the action is mechanical — files through
# an existing seam. Anything needing composition or a human surface is returned in
# `needs_agent`, and the agent acts on it afterwards through the seam the SKILL
# names, recording what it did as `<step>-filed` (a distinct fact from what the
# probe found, and a distinct log key, so neither overwrites the other).
#
# STEP SCRIPTS ARE FLAT (`step-<slug>.sh`, not `steps/<slug>.sh`). A skill's
# scripts live exactly one directory below the skill, because that is the depth the
# build's cross-skill reference form encodes (`${SCRIPT_DIR}/../../<skill>/scripts/`,
# `scripts/build-plugins/script-ref-patterns.mjs`). A nested directory would make
# every reference to another skill one `../` deeper than the build can detect, and
# the build would ship a broken closure rather than fail — so the nesting bends to
# the guard rather than the guard to the nesting.
#
# THE DEADLINE IS REPORTED, NEVER SILENT. `--deadline-seconds` bounds the tick;
# steps not reached are logged `skipped` with reason `budget`, by name. The
# Consideration this answers: "the report should name the steps that did not run
# for lack of time as clearly as the ones that failed."
#
# THE PERSIST IS THE CLOSING ACT, NOT A TENTH STEP. `persist-log.sh` puts the
# log on the base after every step has had its turn, so a tick that dies half-way
# still persists what it recorded on its next run. It is deliberately NOT in
# `STEPS`: the nine are the ask's contract and the log's step keys, while this is
# the run's own bookkeeping — it reports under the top-level `persist` key and
# logs under the step id `persist-log`. `--no-log` implies no persist (there is
# nothing to put anywhere), and `--no-persist` keeps the log local.
#
# Usage:
#   run.sh [--tick <YYYYMMDD-HHMMSS>] [--root <repo-root>] [--only <slug>[,<slug>]...]
#          [--skip <slug>[,<slug>]...] [--deadline-seconds <n>] [--no-log]
#          [--no-persist]
#
# Output: one JSON line
#   {"tick": "...", "log": "<path>|", "steps": [
#      {"step","status","reason","summary","needs_agent":[...],"logged":true|false}, ...],
#    "counts": {"ok":n,"filed":n,"skipped":n,"degraded":n,"blocked":n},
#    "needs_agent": <total>,
#    "persist": {"status","reason","summary","persisted","logged"}}
#
# `status` is the tick log's closed vocabulary: ok | filed | skipped | degraded | blocked.
# `reason` is free-form but stable per cause (`not_implemented`, `budget`,
# `step_missing`, `step_error`, `no_output`, `bad_output`, ...).

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LOG_APPEND="${SCRIPT_DIR}/log-append.sh"
PERSIST_LOG="${SCRIPT_DIR}/persist-log.sh"

# The step list IS the contract (reference/workflow.md states each one's inputs,
# what it may write, and its abort reasons). Order is the ask's order, which is
# also cheapest-first: the log, then the reads, then the writes, then the ask.
STEPS='open-log inbound-sweep workload-logs merge-conflicts issue-triage stuck-prs doc-drift release-status note-cadence human-checkin'

TICK=''
ROOT='.'
ONLY=''
SKIP=''
DEADLINE=0
DO_LOG=1
DO_PERSIST=1

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)             TICK="${2:-}"; shift 2 ;;
        --root)             ROOT="${2:-}"; shift 2 ;;
        --only)             ONLY=$(printf '%s' "${2:-}" | tr ',' ' '); shift 2 ;;
        --skip)             SKIP=$(printf '%s' "${2:-}" | tr ',' ' '); shift 2 ;;
        --deadline-seconds) DEADLINE="${2:-0}"; shift 2 ;;
        --no-log)           DO_LOG=0; shift ;;
        --no-persist)       DO_PERSIST=0; shift ;;
        *) printf '{"tick": "", "error": "unknown_argument", "argument": "%s"}\n' "$1"; exit 1 ;;
    esac
done

[ -n "$TICK" ] || TICK=$(sh "${SCRIPT_DIR}/tick-id.sh" | sed 's/.*"tick": "//; s/".*//')

started=$(date -u +%s)

in_list() {
    # $1 needle, $2 space-separated haystack
    found=1
    for item in $2; do
        if [ "$item" = "$1" ]; then
            found=0
        fi
    done
    return $found
}

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Read a scalar string field out of a step's one-line JSON. Deliberately small: a
# step's output is written by this repository, so a tolerant reader that reports
# `bad_output` beats a JSON dependency in a POSIX sh script.
json_field() {
    printf '%s' "$2" | awk -v key="\"$1\":" '
        {
            i = index($0, key)
            if (i == 0) exit
            rest = substr($0, i + length(key))
            sub(/^[ \t]+/, "", rest)
            if (substr(rest, 1, 1) != "\"") exit
            rest = substr(rest, 2)
            out = ""
            while (length(rest) > 0) {
                c = substr(rest, 1, 1)
                if (c == "\\") { out = out substr(rest, 1, 2); rest = substr(rest, 3); continue }
                if (c == "\"") break
                out = out c; rest = substr(rest, 2)
            }
            print out
        }'
}

# `needs_agent` is an array of flat objects; the report only needs its length, so
# this counts top-level `{` between the array's brackets with a depth counter. A
# comma count would be wrong by a factor of however many fields an entry has —
# measured, on the first step that returned three entries and was reported as
# eleven.
json_array_len() {
    printf '%s' "$2" | awk -v key="\"$1\":" '
        {
            i = index($0, key)
            if (i == 0) { print 0; exit }
            rest = substr($0, i + length(key))
            i = index(rest, "[")
            if (i == 0) { print 0; exit }
            depth = 0; n = 0
            for (j = i + 1; j <= length(rest); j++) {
                c = substr(rest, j, 1)
                if (c == "{") { if (depth == 0) n++; depth++ }
                else if (c == "}") depth--
                else if (c == "]" && depth == 0) break
            }
            print n
        }'
}

rows=''
# Derived, not parsed back out of the writer: `log_step` runs in a command
# substitution, so anything it assigned would be lost with its subshell.
DAY=$(printf '%s' "$TICK" | cut -c1-4)-$(printf '%s' "$TICK" | cut -c5-6)-$(printf '%s' "$TICK" | cut -c7-8)
log_file=''
ok=0; filed=0; skipped=0; degraded=0; blocked=0; needs_total=0

emit_row() {
    # $1 step  $2 status  $3 reason  $4 summary  $5 needs_agent count  $6 logged
    rows="$rows${rows:+, }{\"step\": \"$1\", \"status\": \"$2\", \"reason\": \"$(json_escape "$3")\", \"summary\": \"$(json_escape "$4")\", \"needs_agent\": $5, \"logged\": $6}"
    case "$2" in
        ok)       ok=$((ok + 1)) ;;
        filed)    filed=$((filed + 1)) ;;
        skipped)  skipped=$((skipped + 1)) ;;
        degraded) degraded=$((degraded + 1)) ;;
        blocked)  blocked=$((blocked + 1)) ;;
    esac
    needs_total=$((needs_total + $5))
}

log_step() {
    # $1 step  $2 status  $3 summary -> prints "true"/"false"
    if [ "$DO_LOG" -eq 0 ]; then
        printf 'false'
        return 0
    fi
    out=$(sh "$LOG_APPEND" --root "$ROOT" --tick "$TICK" --step "$1" --status "$2" --summary "$3" 2>/dev/null || true)
    case "$out" in
        *'"logged": true'*|*'"duplicate": true'*) printf 'true' ;;
        *) printf 'false' ;;
    esac
}

for step in $STEPS; do
    if [ -n "$ONLY" ] && ! in_list "$step" "$ONLY"; then
        continue
    fi
    if [ -n "$SKIP" ] && in_list "$step" "$SKIP"; then
        summary='skipped by the caller'
        logged=$(log_step "$step" skipped "$summary")
        emit_row "$step" skipped requested "$summary" 0 "$logged"
        continue
    fi
    # THE TICK'S VOICE IS NEVER STARVED (2026-08-21). The deadline cuts steps in order and
    # `human-checkin` is last, so a slow tick used to read nine things, log them, and say
    # nothing to anybody — the one step whose absence nobody can see was the first to go.
    # It is exempt: by the time it runs the other steps have already handed it their
    # findings, and asking with nine of them is strictly better than asking with none.
    if [ "$step" != "human-checkin" ] \
       && [ "$DEADLINE" -gt 0 ] && [ $(( $(date -u +%s) - started )) -ge "$DEADLINE" ]; then
        summary="not reached within the tick's ${DEADLINE}s budget"
        logged=$(log_step "$step" skipped "$summary")
        emit_row "$step" skipped budget "$summary" 0 "$logged"
        continue
    fi

    script="${SCRIPT_DIR}/step-${step}.sh"
    if [ ! -f "$script" ]; then
        summary="no step script at step-${step}.sh"
        logged=$(log_step "$step" degraded "$summary")
        emit_row "$step" degraded step_missing "$summary" 0 "$logged"
        continue
    fi

    if ! out=$(sh "$script" --tick "$TICK" --root "$ROOT" 2>/dev/null); then
        summary="the step exited non-zero"
        logged=$(log_step "$step" degraded "$summary")
        emit_row "$step" degraded step_error "$summary" 0 "$logged"
        continue
    fi
    out=$(printf '%s' "$out" | tail -n 1)
    if [ -z "$out" ]; then
        summary='the step printed nothing'
        logged=$(log_step "$step" degraded "$summary")
        emit_row "$step" degraded no_output "$summary" 0 "$logged"
        continue
    fi

    status=$(json_field status "$out")
    reason=$(json_field reason "$out")
    summary=$(json_field summary "$out")
    needs=$(json_array_len needs_agent "$out")
    [ -n "$needs" ] || needs=0

    case "$status" in
        ok|filed|skipped|degraded|blocked) ;;
        *)
            summary="the step's status was not in the log vocabulary: '${status}'"
            status=degraded
            reason=bad_output
            needs=0
            ;;
    esac
    [ -n "$summary" ] || summary="(the step reported no summary)"

    logged=$(log_step "$step" "$status" "$summary")
    emit_row "$step" "$status" "$reason" "$summary" "$needs" "$logged"
done

if [ "$DO_LOG" -eq 1 ] && [ -f "$ROOT/.workaholic/moderations/$DAY.md" ]; then
    log_file="$ROOT/.workaholic/moderations/$DAY.md"
fi

# --- The closing act: put the log where the next tick can read it -------------
# A routine's container is discarded after the run, so a log that stayed in the
# checkout would leave every dedup blind and the tick with no audit trail
# (`persist-log.sh`'s header). Its outcome is reported and logged like any other
# fact this tick establishes — a persist that did not reach the base says so by
# name rather than reading as a clean tick.
persist_status=skipped
persist_reason=disabled
persist_summary='the caller kept the log local'
persist_persisted=false
persist_logged=false

if [ "$DO_LOG" -eq 1 ] && [ "$DO_PERSIST" -eq 1 ]; then
    if [ -z "$log_file" ]; then
        persist_reason=no_log
        persist_summary='the tick wrote no log, so there is nothing to persist'
    else
        pout=$(sh "$PERSIST_LOG" --tick "$TICK" --root "$ROOT" 2>/dev/null || true)
        pout=$(printf '%s' "$pout" | tail -n 1)
        if [ -z "$pout" ]; then
            persist_status=degraded
            persist_reason=no_output
            persist_summary='the persist printed nothing'
        else
            persist_status=$(json_field status "$pout")
            persist_reason=$(json_field reason "$pout")
            persist_summary=$(json_field summary "$pout")
            case "$pout" in *'"persisted": true'*) persist_persisted=true ;; *) persist_persisted=false ;; esac
            case "$persist_status" in
                ok|filed|skipped|degraded|blocked) ;;
                *) persist_status=degraded; persist_reason=bad_output; persist_summary="the persist's status was not in the log vocabulary" ;;
            esac
            [ -n "$persist_summary" ] || persist_summary='(the persist reported no summary)'
        fi
    fi
    persist_logged=$(log_step persist-log "$persist_status" "$persist_summary")
fi

printf '{"tick": "%s", "log": "%s", "steps": [%s], "counts": {"ok": %s, "filed": %s, "skipped": %s, "degraded": %s, "blocked": %s}, "needs_agent": %s, "persist": {"status": "%s", "reason": "%s", "summary": "%s", "persisted": %s, "logged": %s}}\n' \
    "$TICK" "$(json_escape "$log_file")" "$rows" "$ok" "$filed" "$skipped" "$degraded" "$blocked" "$needs_total" \
    "$persist_status" "$(json_escape "$persist_reason")" "$(json_escape "$persist_summary")" "$persist_persisted" "$persist_logged"
