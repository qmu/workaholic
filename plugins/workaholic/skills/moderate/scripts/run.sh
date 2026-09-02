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
#      {"step","status","reason","summary","event","needs_agent":[...],
#       "needs_agent_count":n,"logged":true|false}, ...],
#    "counts": {"ok":n,"filed":n,"skipped":n,"degraded":n,"blocked":n},
#    "needs_agent": <total>,
#    "persist": {"status","reason","summary","persisted","logged"}}
#
# `status` is the tick log's closed vocabulary: ok | filed | skipped | degraded | blocked.
# `reason` is free-form but stable per cause (`not_implemented`, `budget`,
# `step_missing`, `step_error`, `no_output`, `bad_output`, `jq_compile_error`, ...).
#
# A STEP THAT COULD NOT COMPILE ITS OWN READING IS `degraded` HERE, IN ONE PLACE
# (2026-08-29, mission `make-a-direction-s-lifecycle-a-declared-stage`). Every reader in
# this skill carries `… | jq -c '…' 2>/dev/null || echo '[]'`, a fallback that is right for
# a data problem and catastrophic for our own: a jq program that does not COMPILE discards
# identically, so the step emits an empty finding and reports `ok`. `lib/jq-guard.sh`
# records the fact (jq's own exit status 3) and decides nothing; this loop is the one place
# that reads the record and reclassifies, beside the `step_missing` / `step_error` /
# `no_output` / `bad_output` it already owns — the same single derivation of "this step
# could not read".

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LOG_APPEND="${SCRIPT_DIR}/log-append.sh"
PERSIST_LOG="${SCRIPT_DIR}/persist-log.sh"

# The step list IS the contract (reference/workflow.md states each one's inputs,
# what it may write, and its abort reasons). Order is the ask's order, which is
# also cheapest-first: the log, then the reads, then the writes, then the ask.
STEPS='open-log blocked-tick inbound-sweep workload-logs merge-conflicts issue-triage stuck-prs doc-drift release-status note-cadence strategy-pace direction-health stalled-units raced-units undrivable-units standing-rulings undelivered-units handoff-units thread-reconcile stranded-publications operator-pulls retire-claims closable-missions unrecorded-missions base-health drill-health cadence-lapse strategy-digest question-answers unanswered-asks file-findings human-checkin'

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

# THE REPORT CARRIES THE ARRAY, NOT ITS LENGTH (2026-08-26). This once emitted the
# count, on the reasoning that "the report only needs its length" — and two readers
# needed the payload. `question-liveness.sh` matches a question's key as a string inside
# `needs_agent` to answer live/settled, so against a counted report it answered `settled`
# for every key by construction: the bounded re-ask could never fire, and the `✅ 解消を確認`
# confirmation would fire on every open question every tick. And the agent, which acts on
# `needs_agent` after the run returns, had to re-invoke every step to see what it had
# found — extra network and clock in a container nobody is watching, and a second reading
# of steps whose window shifts between invocations. Both are the same defect: a report
# that names how much there is and not what it is.
# `json_array_len` stays for `needs_agent_count`, a convenience beside the payload rather
# than a substitute for it. It counts top-level `{` between the array's brackets with a
# depth counter; a comma count would be wrong by however many fields an entry has —
# measured, on the first step that returned three entries and was reported as eleven.
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

# The array's own text, brackets excluded, carried through verbatim. A step's entries are
# already valid JSON — this script re-emits them rather than re-encoding them, so no step
# has to learn a second shape and no field is lost on the way to the agent.
json_array_raw() {
    printf '%s' "$2" | awk -v key="\"$1\":" '
        {
            i = index($0, key)
            if (i == 0) { print ""; exit }
            rest = substr($0, i + length(key))
            i = index(rest, "[")
            if (i == 0) { print ""; exit }
            depth = 0; out = ""
            for (j = i + 1; j <= length(rest); j++) {
                c = substr(rest, j, 1)
                if (c == "]" && depth == 0) break
                if (c == "{" || c == "[") depth++
                else if (c == "}" || c == "]") depth--
                out = out c
            }
            print out
        }'
}

rows=''
# WHERE A STEP'S jq COMPILE ERRORS LAND (2026-08-29, mission
# `make-a-direction-s-lifecycle-a-declared-stage`). `lib/jq-guard.sh`, sourced by every
# script here that embeds a jq program, appends one line per compile error; this loop
# truncates the file before each step and reads it after, so what it holds is always
# exactly the step that just ran. The same seam as the two files below — an environment
# variable rather than a fourth flag, so the step invocation stays uniform, and a mktemp
# path outside the repository, so the tick still writes nothing into the tree but its own
# log line. Unset (mktemp refused) means the guard is inert and the tick behaves exactly as
# it did before this existed.
JQERR_FILE=$(mktemp 2>/dev/null || printf '')
if [ -n "$JQERR_FILE" ]; then
    trap 'rm -f "$JQERR_FILE"' EXIT
    export WORKAHOLIC_JQ_COMPILE_ERRORS="$JQERR_FILE"
fi

# THE RUN'S OWN STEP REPORTS, READABLE BY A LATER STEP (2026-08-29). `file-findings` turns a
# REPAIRABLE finding into work, and its candidates are what the earlier steps of THIS tick
# reported — including each step's `event`, which is the honest "a repository event happened
# here" signal and is the one field the tick log does not carry (the log keeps `status` and the
# log-facing `summary`, by design). So the accumulated rows are written to a temp file and named
# in the environment every step inherits.
#
# AN ENVIRONMENT VARIABLE RATHER THAN AN ARGUMENT, deliberately: `run.sh` invokes every step
# with the same two flags, and a third passed to one step only would make the invocation
# non-uniform for one consumer. A step that does not read the variable is unaffected by it.
# The file lives outside the repository (mktemp), so the tick still writes nothing into the
# tree but its own log line.
REPORTS_FILE=$(mktemp 2>/dev/null || printf '')
if [ -n "$REPORTS_FILE" ]; then
    trap 'rm -f "$JQERR_FILE" "$REPORTS_FILE"' EXIT
    # Seeded EMPTY rather than left zero-length: a step that runs before any row exists —
    # `--only file-findings`, or the first step of a tick — must read "no rows yet" and not
    # "the reports could not be parsed". A degradation reported for an ordinary state is the
    # collapse every reader in this skill is written against.
    printf '{"steps": []}\n' > "$REPORTS_FILE"
    export WORKAHOLIC_TICK_REPORTS="$REPORTS_FILE"
fi

# THE OPEN PULL REQUESTS, RESOLVED ONCE FOR THE WHOLE TICK (2026-08-29, ticket
# `20260829092043`). `reference/workflow.md` has said "resolved once per tick, used twice" of
# step 6 since the reader shipped, and the implementation did not hold it: steps 4 and 6 each
# called `pulls-state.sh`, so a tick made two rounds of per-pull reads. Because GitHub computes
# `mergeable` LAZILY, the two rounds can disagree — measured on tick `20260829-085055` (issue
# #710), `merge-conflicts` reported `none conflicted` while `stuck-prs` named four conflicted
# pull requests over the same open set, with neither wrong about what it read.
#
# THE SAME SEAM AS THE REPORTS FILE, and for the same reason: an environment variable rather
# than a third flag, so the step invocation stays uniform and a step that does not read it is
# unaffected. `pulls-state.sh` — the ONE reader — is what consults it, so both steps stay
# byte-identical and "resolved once per tick" is a property of the reader rather than a
# sentence each caller must remember. The file lives outside the repository, so the tick still
# writes nothing into the tree but its own log line.
#
# A FAILED RESOLUTION IS NOT CACHED. `pulls-state.sh` reports its own degradation (`ok: false`
# with a reason), and serving that from a cache would make one transport hiccup the tick's
# answer for every consumer; an unset variable simply means each step resolves for itself,
# which is exactly the behaviour that existed before this.
#
# AND ONLY WHEN A CONSUMER WILL RUN. A tick narrowed with `--only` to a step that never reads
# the open pull requests must not pay for a read nobody uses, so the resolution is gated on the
# same `--only`/`--skip` arithmetic the loop below applies.
PULLS_WANTED=0
for _pw in merge-conflicts stuck-prs; do
    if [ -n "$ONLY" ] && ! in_list "$_pw" "$ONLY"; then continue; fi
    if [ -n "$SKIP" ] && in_list "$_pw" "$SKIP"; then continue; fi
    PULLS_WANTED=1
done

PULLS_FILE=''
if [ "$PULLS_WANTED" -eq 1 ]; then
    PULLS_FILE=$(mktemp 2>/dev/null || printf '')
fi
if [ -n "$PULLS_FILE" ]; then
    trap 'rm -f "$JQERR_FILE" "$REPORTS_FILE" "$PULLS_FILE"' EXIT
    if sh "${SCRIPT_DIR}/pulls-state.sh" > "$PULLS_FILE" 2>/dev/null \
       && grep -q '"ok": true' "$PULLS_FILE" 2>/dev/null; then
        export WORKAHOLIC_TICK_PULLS_STATE="$PULLS_FILE"
    else
        rm -f "$PULLS_FILE"
    fi
fi
# Derived, not parsed back out of the writer: `log_step` runs in a command
# substitution, so anything it assigned would be lost with its subshell.
DAY=$(printf '%s' "$TICK" | cut -c1-4)-$(printf '%s' "$TICK" | cut -c5-6)-$(printf '%s' "$TICK" | cut -c7-8)
log_file=''
ok=0; filed=0; skipped=0; degraded=0; blocked=0; needs_total=0

emit_row() {
    # $1 step  $2 status  $3 reason  $4 summary  $5 needs_agent array body  $6 logged
    # $7 event  $8 needs_agent count (the body's own, counted once by the caller)
    # `event` (2026-08-23) is the POST-facing phrase, carried beside the LOG-facing
    # `summary` and never instead of it. Two audiences: the log is an audit trail a
    # maintainer reads when the tick misbehaves, and it keeps every counter; the root is
    # read by a person scanning a channel, who needs the repository's events. The step
    # supplies it because the step knows what its finding MEANS and the renderer does not.
    # Empty means "nothing happened here" and renders no line at all.
    rows="$rows${rows:+, }{\"step\": \"$1\", \"status\": \"$2\", \"reason\": \"$(json_escape "$3")\", \"summary\": \"$(json_escape "$4")\", \"needs_agent\": [$5], \"needs_agent_count\": ${8:-0}, \"logged\": $6, \"event\": \"$(json_escape "${7:-}")\"}"
    case "$2" in
        ok)       ok=$((ok + 1)) ;;
        filed)    filed=$((filed + 1)) ;;
        skipped)  skipped=$((skipped + 1)) ;;
        degraded) degraded=$((degraded + 1)) ;;
        blocked)  blocked=$((blocked + 1)) ;;
    esac
    needs_total=$((needs_total + ${8:-0}))
    # Refreshed after every row so a later step reads exactly what the steps before it
    # reported — never a stale snapshot, and never the rows of a step that has not run.
    [ -n "$REPORTS_FILE" ] && printf '{"steps": [%s]}\n' "$rows" > "$REPORTS_FILE"
    return 0
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

# One persist, parsed one way. Both the opening and the closing call land here, so a
# persist that missed the base is named the same way whichever of the two made it.
# Sets: p_status / p_reason / p_summary / p_persisted.
run_persist() {
    p_status=degraded
    p_reason=no_output
    p_summary='the persist printed nothing'
    p_persisted=false
    pout=$(sh "$PERSIST_LOG" --tick "$TICK" --root "$ROOT" 2>/dev/null || true)
    pout=$(printf '%s' "$pout" | tail -n 1)
    [ -n "$pout" ] || return 0
    p_status=$(json_field status "$pout")
    p_reason=$(json_field reason "$pout")
    p_summary=$(json_field summary "$pout")
    case "$pout" in *'"persisted": true'*) p_persisted=true ;; *) p_persisted=false ;; esac
    case "$p_status" in
        ok|filed|skipped|degraded|blocked) ;;
        *) p_status=degraded; p_reason=bad_output; p_summary="the persist's status was not in the log vocabulary" ;;
    esac
    [ -n "$p_summary" ] || p_summary='(the persist reported no summary)'
}

# --- The opening act: put the tick's opening on the base before any step ------
# WHY (2026-08-31, mission `stop-an-unattended-tick-from-waiting-on-a-person`). The
# persist below is the tick's CLOSING act, so a tick that dies mid-run leaves nothing on
# the base at all: the record that would show it stopped is the record the stop prevents.
# Measured — three consecutive ticks sat at `requires_action` and the base carried no
# trace of any of them. One persist immediately after the log is opened makes a dead tick
# visible, and `step-blocked-tick.sh` is what reads for it.
#
# IT NEEDS NO CHANGE TO THE WRITER'S CONTRACT. `persist-log.sh` is already idempotent and
# already unions by `(tick, step)`, so the closing persist adds every later line into the
# same section without rewriting this one. Every prohibition holds unchanged: no `work-*`
# branch, no claim, no pull request, no merge, and the caller's checkout byte-identical.
#
# IT IS NEVER FATAL. A miss is reported `degraded` by name under its own `opening_persist`
# key and its own log step id, exactly as the closing one reports itself, and the tick runs
# on — a tick that could not put its opening on the base has still got nineteen steps to do.
#
# NOT PER STEP. Thirty commits an hour for a log is the noise the pull-request-per-tick
# design was refused for. Two bound the loss to whatever a dead tick had done since it
# opened, which is the fact that matters. The stated price is two commits an hour instead
# of one on an active repository, which is small beside thirty.
#
# A TICK KILLED **BEFORE** ITS FIRST STEP STILL LEAVES NOTHING, and that case is genuinely
# outside this seam rather than papered over: there is no opening to persist yet.
open_persist_status=skipped
open_persist_reason=disabled
open_persist_summary='the caller kept the log local'
open_persist_persisted=false

for step in $STEPS; do
    if [ -n "$ONLY" ] && ! in_list "$step" "$ONLY"; then
        continue
    fi
    if [ -n "$SKIP" ] && in_list "$step" "$SKIP"; then
        summary='skipped by the caller'
        logged=$(log_step "$step" skipped "$summary")
        emit_row "$step" skipped requested "$summary" "" "$logged" "" 0
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
        emit_row "$step" skipped budget "$summary" "" "$logged" "" 0
        continue
    fi

    script="${SCRIPT_DIR}/step-${step}.sh"
    if [ ! -f "$script" ]; then
        summary="no step script at step-${step}.sh"
        logged=$(log_step "$step" degraded "$summary")
        emit_row "$step" degraded step_missing "$summary" "" "$logged" "" 0
        continue
    fi

    # Emptied before the step, read after it, so the record names this step and no other.
    if [ -n "$JQERR_FILE" ]; then : > "$JQERR_FILE"; fi

    if ! out=$(sh "$script" --tick "$TICK" --root "$ROOT" 2>/dev/null); then
        summary="the step exited non-zero"
        logged=$(log_step "$step" degraded "$summary")
        emit_row "$step" degraded step_error "$summary" "" "$logged" "" 0
        continue
    fi
    out=$(printf '%s' "$out" | tail -n 1)
    if [ -z "$out" ]; then
        summary='the step printed nothing'
        logged=$(log_step "$step" degraded "$summary")
        emit_row "$step" degraded no_output "$summary" "" "$logged" "" 0
        continue
    fi

    status=$(json_field status "$out")
    reason=$(json_field reason "$out")
    summary=$(json_field summary "$out")
    event=$(json_field event "$out")
    needs=$(json_array_raw needs_agent "$out")
    needs_n=$(json_array_len needs_agent "$out")
    [ -n "$needs_n" ] || needs_n=0

    case "$status" in
        ok|filed|skipped|degraded|blocked) ;;
        *)
            summary="the step's status was not in the log vocabulary: '${status}'"
            status=degraded
            reason=bad_output
            needs=''
            needs_n=0
            ;;
    esac
    [ -n "$summary" ] || summary="(the step reported no summary)"

    # A COMPILE ERROR OUTRANKS WHATEVER THE STEP SAID ABOUT ITSELF. The step cannot know:
    # its fallback already turned the failure into an empty answer, which is precisely why
    # it reported `ok`. `needs_agent` is deliberately LEFT ALONE rather than zeroed like
    # `bad_output` does — a step's other readings may have compiled fine, and dropping a
    # question a person is owed to punish a defect elsewhere in the same script trades one
    # silence for another. What the reclassification buys is that the tick log, the report
    # and `file-findings` all name the step as degraded instead of counting it `ok`.
    if [ -n "$JQERR_FILE" ] && [ -s "$JQERR_FILE" ]; then
        n_jqerr=$(grep -c '' "$JQERR_FILE" 2>/dev/null || printf 0)
        jqerr_in=$(sed -n '1p' "$JQERR_FILE" 2>/dev/null || printf '')
        status=degraded
        reason=jq_compile_error
        summary="${n_jqerr} embedded jq program(s) did not compile (first in ${jqerr_in:-the step}); this step's reading is not a reading"
    fi

    logged=$(log_step "$step" "$status" "$summary")
    emit_row "$step" "$status" "$reason" "$summary" "$needs" "$logged" "$event" "$needs_n"

    # The opening is on the base before anything else runs. Keyed on the first step in
    # `STEPS` rather than on a loop counter, so a caller that narrowed the run with
    # `--only`/`--skip` and never opened a log does not persist an opening it does not have.
    if [ "$step" = open-log ] && [ "$DO_LOG" -eq 1 ] && [ "$DO_PERSIST" -eq 1 ]; then
        run_persist
        open_persist_status="$p_status"
        open_persist_reason="$p_reason"
        open_persist_summary="$p_summary"
        open_persist_persisted="$p_persisted"
        # Logged under its own step id: the log is idempotent per `(tick, step)`, so
        # sharing `persist-log` with the closing act would make the second a duplicate and
        # lose its outcome. This line reaches the base on the closing persist, like every
        # other line written after the opening one.
        log_step persist-log-opening "$open_persist_status" "$open_persist_summary" >/dev/null
    fi
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
        run_persist
        persist_status="$p_status"
        persist_reason="$p_reason"
        persist_summary="$p_summary"
        persist_persisted="$p_persisted"
    fi
    persist_logged=$(log_step persist-log "$persist_status" "$persist_summary")
fi

printf '{"tick": "%s", "log": "%s", "steps": [%s], "counts": {"ok": %s, "filed": %s, "skipped": %s, "degraded": %s, "blocked": %s}, "needs_agent": %s, "opening_persist": {"status": "%s", "reason": "%s", "summary": "%s", "persisted": %s}, "persist": {"status": "%s", "reason": "%s", "summary": "%s", "persisted": %s, "logged": %s}}\n' \
    "$TICK" "$(json_escape "$log_file")" "$rows" "$ok" "$filed" "$skipped" "$degraded" "$blocked" "$needs_total" \
    "$open_persist_status" "$(json_escape "$open_persist_reason")" "$(json_escape "$open_persist_summary")" "$open_persist_persisted" \
    "$persist_status" "$(json_escape "$persist_reason")" "$(json_escape "$persist_summary")" "$persist_persisted" "$persist_logged"
