#!/bin/sh -eu
# What did the base's checks say about ONE commit? The single reader of a check run in this
# plugin, answering exactly that and nothing else.
#
# WHY IT EXISTS (2026-08-27, mission `read-whether-the-base-survived-what-the-loop-merged`).
# Nothing here read a check run. The loop merges its own work onto `main` every half hour
# and never learned what the base's checks then said, so a green base and a base nobody
# looked at were one reading. The single approximation was `moderate/scripts/pulls-state.sh`,
# which infers `blocked_by: checks` from one PULL REQUEST's `mergeable_state == unstable` —
# a different question, asked of a different object, and unanswerable for a commit that is
# already on the base.
#
# IT IS THREE-VALUED, AND THE THIRD VALUE IS THE POINT. `green` and `red` are facts about
# the repository; `unanswerable` is a fact about US — no `gh`, a refused transport, a rate
# limit, a response we could not parse, a commit nothing has checked, checks still running.
# Collapsing any of those into `green` is the one failure this reader exists to prevent: a
# base nobody looked at would then read exactly like a base that passed. `claim-merged.sh`
# is the precedent and this copies its shape deliberately.
#
# A COMMIT WITH NO CHECKS IS NOT A GREEN COMMIT. It is `unanswerable` (`no_checks`) — the
# reading was not made, and the most likely causes are that CI has not started yet or does
# not run on this ref at all.
#
# A STILL-RUNNING CHECK IS `unanswerable` (`checks_pending`), NOT GREEN. The base has not
# finished answering. The one exception is a check that has ALREADY concluded in failure:
# `red` wins over `checks_pending`, because a completed failure is a reading we DID make and
# a later check cannot un-fail it.
#
# IT READS CHECK RUNS ONLY, never the legacy combined-status endpoint. Two calls per commit
# would double the cost of the attribution walk that composes this reader, and GitHub Actions
# — which is what this repository and its consumers run — reports check runs. The limit is
# stated rather than hidden: a repository whose CI reports ONLY legacy commit statuses reads
# `no_checks`, hence `unanswerable`, and never `green`. That is the honest degradation; add
# the second call when a repository that needs it is measured, not before.
#
# IT EXITS 0 IN EVERY CASE, INCLUDING EVERY DEGRADATION. A non-zero exit turns a degraded
# read into a failed one for every caller downstream, and the callers here (a `/moderate`
# step, a driving run's report) must be able to say what they could not read rather than
# stop.
#
# WHY IT SITS IN `scripts/` RATHER THAN `lib/`, though a shell library would read naturally:
# the bundle build detects a cross-skill closure only by the literal form
# `${SCRIPT_DIR}/../../<skill>/scripts/`, which is only writable from `scripts/`. From inside
# `lib/` the same reference needs a third `../` and `verify.mjs` reports it as undetectable —
# so a reader in `lib/` would ship to every non-Claude agent with its transport missing. The
# convention bends to the build, and the build's rule is the one with a failure mode.
#
# NOTHING MAY ACT ON WHAT THIS ANSWERS, WITH ONE ENUMERATED EXCEPTION. All three words are
# JUDGEMENTS, not proofs — a re-run can turn a red check green and a green one red, which is
# precisely the property a proof must not have (`drive/reference/claims.md`, *Proofs and
# judgements*). Report it, ask about it; never revert, re-run or hold work on it.
#
# THE EXCEPTION IS THE PRE-MERGE GATE (2026-09-03), and it is the rule's own bounded shape
# rather than a hole in it: `branch-checks.sh` composes this reader on a pull request's HEAD
# commit, re-derives it at the moment of the merge, refuses `checks_red` and `checks_pending`
# by their own words with nothing attempted, and PROCEEDS on every absence — which is what a
# GATING act must do (`claims.md`, *When a bounded act may read a judgement*, and *Two shapes,
# one rule*). Its consumers are enumerated there and the suite pins the table in both
# directions. Nothing else may gate, and this reader still gates nothing itself.
#
# WHY THE EXCEPTION EXISTS. Without it the loop merged its own branches without ever reading
# their checks: MEASURED 2026-09-03, PR #957 merged three and a half minutes BEFORE its own
# `Loop Drills` run completed, and it was red; `main` then carried a red drill suite for four
# hours with six further merges landing on it.
#
# A SUITE THAT NEVER RAN IS NOT A SUITE THAT PASSED (2026-09-03, mission
# `make-a-red-base-impossible-for-the-loop-to-miss`). Everything above answers from the
# verdicts the commit CARRIES, so a declared workflow that did not fire leaves no verdict and
# the reading is taken over whatever else is there. MEASURED: a path-filtered workflow did not
# run on a commit that broke the suite it guards, the newest verdict on that commit was a
# different, green one, and the base read `green` for about an hour while the loop merged into
# it.
#
# So `--declared` adds `unverified[]`: the declared suites with NO run on this commit. It rides
# BESIDE the state and is never folded into it -- a tip can carry a green verdict and an
# unverified suite at once, and collapsing them loses exactly the fact that was missed. `green`,
# `red` and every `unanswerable` reason are byte-identical with and without the flag.
#
# WHAT COUNTS AS DECLARED, and this is the judgement the ticket asked to be made out loud: a
# workflow under `.github/workflows/` whose `on:` declares `push`. A PATH-FILTERED workflow IS
# declared -- its filter is the reason it did not run, and *it did not run here* is precisely
# the fact worth reporting; exempting it would exempt the measured defect. What is exempt is a
# workflow that structurally CANNOT run on a base commit (schedule-only, `workflow_dispatch`
# only, `pull_request` only), which would otherwise read unverified forever.
#
# IT IS OPT-IN because it costs a second REST call. `attribute-base-red.sh` walks commit after
# commit and passes no flag, so the attribution walk's cost does not move; the tip's own reading
# passes it once.
#
# A DEGRADED DECLARED-READ SAYS SO. `unverified_readable: false` with a named reason and a
# **null** `unverified`, never an empty array -- an empty array means *every declared suite ran*,
# which is the opposite of *we could not tell*.
#
# Usage: read-base-checks.sh <commit-sha> [--declared]
# Output: one JSON line
#   {"ok": bool, "commit", "state": "green|red|unanswerable", "reason",
#    "failing": [{"name", "conclusion"}],
#    "unverified": [<workflow name>] | null, "unverified_readable": bool, "unverified_reason"}
#
#   ok       false exactly when `state` is `unanswerable`; a reading we could not make.
#   failing  non-empty only on `red`, naming every completed check that failed.
#   unverified  present only with `--declared`; null when the declared read was degraded.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts//gh-rest.sh"

COMMIT=""
DECLARED=false
while [ $# -gt 0 ]; do
    case "$1" in
        --declared) DECLARED=true; shift ;;
        --) shift ;;
        *) [ -n "$COMMIT" ] || COMMIT="$1"; shift ;;
    esac
done

# The declared-suite reading is computed lazily, at the one emit, so every early `unanswerable`
# exit above costs nothing extra and stays byte-identical.
UNVERIFIED_JSON="null"
UNVERIFIED_READABLE="true"
UNVERIFIED_REASON=""
# Declared here because an early `unanswerable` emit runs before the slug is resolved, and the
# lazy reader must be able to say it had no transport rather than fail under `set -u`.
slug=""

read_declared() {
    [ "$DECLARED" = "true" ] || { UNVERIFIED_READABLE="false"; UNVERIFIED_REASON="not_requested"; return 0; }

    _root=$(git rev-parse --show-toplevel 2>/dev/null || true)
    _dir="${_root:-.}/.github/workflows"
    [ -d "$_dir" ] || { UNVERIFIED_READABLE="false"; UNVERIFIED_REASON="no_workflows_dir"; return 0; }

    # DECLARED = an `on:` block containing `push`. Read with awk over the `on:` block alone, so a
    # `push` appearing in a job's prose or a step's name is never mistaken for a trigger.
    _declared=""
    for _wf in "$_dir"/*.yml "$_dir"/*.yaml; do
        [ -f "$_wf" ] || continue
        _has_push=$(awk '
            /^on:/ { inon=1; next }
            inon && /^[A-Za-z_]+:/ { inon=0 }
            inon && /^[[:space:]]+push:/ { print "yes"; exit }
        ' "$_wf" 2>/dev/null || true)
        [ "$_has_push" = "yes" ] || continue
        _name=$(sed -n 's/^name:[[:space:]]*//p' "$_wf" | head -1)
        [ -n "$_name" ] || _name=$(basename "$_wf")
        _declared="${_declared}${_name}
"
    done
    [ -n "$_declared" ] || { UNVERIFIED_JSON="[]"; return 0; }

    case "$slug" in
        */*) ;;
        *) UNVERIFIED_READABLE="false"; UNVERIFIED_REASON="slug_unresolved"; return 0 ;;
    esac
    [ -n "$COMMIT" ] || { UNVERIFIED_READABLE="false"; UNVERIFIED_REASON="no_commit"; return 0; }

    if ! _runs_body=$(sh "$GH_REST" api \
            "repos/${slug}/actions/runs?head_sha=${COMMIT}&per_page=100" 2>&1); then
        UNVERIFIED_READABLE="false"; UNVERIFIED_REASON="runs_unreadable"; return 0
    fi
    printf '%s' "$_runs_body" | jq -e '.workflow_runs | type == "array"' >/dev/null 2>&1 \
        || { UNVERIFIED_READABLE="false"; UNVERIFIED_REASON="unparseable_runs"; return 0; }
    _ran=$(printf '%s' "$_runs_body" | jq -r '.workflow_runs[].name // empty' 2>/dev/null || true)

    UNVERIFIED_JSON=$(printf '%s' "$_declared" | RAN="$_ran" python3 -c '
import json, os, sys
ran = set(l.strip() for l in os.environ.get("RAN", "").splitlines() if l.strip())
out = [l.strip() for l in sys.stdin.read().splitlines() if l.strip() and l.strip() not in ran]
print(json.dumps(sorted(set(out))))
' 2>/dev/null || printf '')
    [ -n "$UNVERIFIED_JSON" ] || { UNVERIFIED_JSON="null"; UNVERIFIED_READABLE="false"; UNVERIFIED_REASON="compare_failed"; }
}

# $1 state, $2 reason, $3 failing (JSON array). `ok` is derived from the state rather than
# passed, so no call site can report a degradation as a successful read by forgetting a flag.
emit() {
    _ok=true
    if [ "$1" = "unanswerable" ]; then _ok=false; fi
    read_declared
    printf '{"ok": %s, "commit": "%s", "state": "%s", "reason": "%s", "failing": %s, "unverified": %s, "unverified_readable": %s, "unverified_reason": "%s"}\n' \
        "$_ok" "$COMMIT" "$1" "${2:-}" "${3:-[]}" \
        "$UNVERIFIED_JSON" "$UNVERIFIED_READABLE" "$UNVERIFIED_REASON"
    exit 0
}

[ -n "$COMMIT" ] || emit unanswerable no_commit
[ -f "$GH_REST" ] || emit unanswerable no_transport_script

# NO SEPARATE AVAILABILITY PROBE, for `claim-merged.sh`'s reason: the probe would spend a
# round trip to learn what the call itself reports, and this reader runs once per commit in a
# walk. The failure of the one call is classified instead.
slug=$(sh "$GH_REST" slug 2>/dev/null || true)
case "$slug" in
    */*) ;;
    *) emit unanswerable slug_unresolved ;;
esac

# REPOSITORY-SCOPED REST, never `gh pr`/`gh issue`/`gh repo` (GraphQL-backed, and a web
# session may 403 them mid-run — `rules/shell.md`). `search/*` is refused outright to a bound
# session, so nothing here searches.
if ! body=$(sh "$GH_REST" api \
        "repos/${slug}/commits/${COMMIT}/check-runs?per_page=100" 2>&1); then
    case "$body" in
        *"not on PATH"*) emit unanswerable gh_unavailable ;;
        *"rate limit"*|*"rate_limit"*|*"API rate"*) emit unanswerable rate_limited ;;
        *"not enabled for this session"*|*"not permitted for this session"*)
            emit unanswerable session_refused ;;
        *"Not Found"*|*"404"*) emit unanswerable commit_not_found ;;
        *) emit unanswerable transport_error ;;
    esac
fi

# An unparseable body is ours too: it is never evidence that the checks passed.
printf '%s' "$body" | jq -e 'type == "object" and (.check_runs | type == "array")' \
    >/dev/null 2>&1 || emit unanswerable unparseable_response

runs=$(printf '%s' "$body" | jq '.check_runs | length' 2>/dev/null || echo "")
case "$runs" in ''|*[!0-9]*) emit unanswerable unparseable_response ;; esac

total=$(printf '%s' "$body" | jq '.total_count // (.check_runs | length)' 2>/dev/null || echo "")
case "$total" in ''|*[!0-9]*) total="$runs" ;; esac

# WHAT COUNTS AS A FAILURE. `neutral` and `skipped` are successes for this purpose — a check
# that deliberately did not apply says nothing bad about the commit — while `cancelled`,
# `timed_out`, `action_required` and `stale` are named beside `failure` because each of them
# means the check did not pass and a person would call the base broken.
failing=$(printf '%s' "$body" | jq -c '
    [ .check_runs[]
      | select(.status == "completed")
      | select(.conclusion == "failure" or .conclusion == "timed_out"
               or .conclusion == "cancelled" or .conclusion == "action_required"
               or .conclusion == "stale")
      | {name: (.name // ""), conclusion: (.conclusion // "")} ]' 2>/dev/null || true)
[ -n "$failing" ] || emit unanswerable unparseable_response

failing_count=$(printf '%s' "$failing" | jq 'length' 2>/dev/null || echo "")
case "$failing_count" in ''|*[!0-9]*) emit unanswerable unparseable_response ;; esac

# RED FIRST, and deliberately: a completed failure is a reading we made, and neither a
# pending sibling check nor a truncated page can make it false.
if [ "$failing_count" -gt 0 ]; then emit red "" "$failing"; fi

if [ "$runs" -eq 0 ]; then emit unanswerable no_checks; fi

pending=$(printf '%s' "$body" | jq '[.check_runs[] | select(.status != "completed")] | length' \
    2>/dev/null || echo "")
case "$pending" in ''|*[!0-9]*) emit unanswerable unparseable_response ;; esac
if [ "$pending" -gt 0 ]; then emit unanswerable checks_pending; fi

# A PAGE WE DID NOT SEE IS A READING WE DID NOT MAKE. One page holds a hundred check runs, so
# this is a corner — but a green derived from a partial set is exactly the confident wrong
# answer this reader exists to refuse.
if [ "$total" -gt "$runs" ]; then emit unanswerable checks_truncated; fi

emit green
