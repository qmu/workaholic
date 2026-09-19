#!/bin/sh -eu
# Step 33 — reclaim the worktrees the reaper proves are finished with, and say what is held.
#
# WHY THIS STEP EXISTS (2026-09-19, issue #1212). `../../branching/scripts/reap-worktrees.sh`
# was built after a 53 GB incident and NEVER GIVEN A CALLER: walking the tracked tree, it
# appeared outside its own body in exactly four places — two documentation rows and two test
# fixtures. No command body, no skill workflow step, no entry in this registry, no
# `.github/workflows/*.yml` and no routine prompt invoked it, and `survey-worktrees.sh`'s only
# non-test caller was the reaper itself. The one script written to catch what teardown
# structurally cannot was reachable only by a person who already knew its name.
#
# WHY /moderate AND NOT A TEARDOWN (the fork, closed on the ticket rather than left open).
# `/drive`'s teardown was rejected for the reason the reaper's own header gives: teardown exists
# three times over and each is correct, but all three share one precondition — SOMEBODY'S RUN
# HAS TO REACH THE END — and a worktree whose run died, whose branch was hand-driven, or whose
# caller was killed is nobody's teardown, which is precisely the set that accumulates. A fourth
# teardown call would be a fourth instance of the same precondition. `/workaholify`'s converge
# seam was rejected because it runs when an operator invokes it, so the sweep would stay
# person-triggered, which is the defect. This tick runs hourly and unattended, its charter is
# finding what has gone stale, and `step-retire-claims.sh` beside it is the standing precedent
# for a step that ACTS on a proof — including the precedent that a LOCAL WORKTREE REAP IS NOT A
# TREE WRITE, so the tick's *writes nothing but its own log line* contract is intact.
#
# THE PROOF IS EXACTLY TWO TERMS AND THIS STEP OWNS NEITHER. `reclaimable == true`, re-derived
# by the reaper from a FRESH `survey-worktrees.sh` at the moment of the act — merged AND clean
# AND no open publication transaction AND not the main tree, `.publish/`, or the current
# worktree — plus `git worktree remove` WITHOUT `--force`, a second, independent gate git itself
# holds. Probed in a throwaway repository 2026-09-19: removing a clean worktree whose branch
# holds commits the base lacks is allowed and leaves `refs/heads/<branch>` present with its
# commit reachable — a removal destroys a CHECKOUT, never a branch and never a commit — while a
# worktree holding an untracked file is refused by git with *contains modified or untracked
# files, use --force to delete it*. Nothing else. No branch is deleted, no ref is written and
# nothing is pushed.
#
# IT DERIVES NO PREDICATE OF ITS OWN AND PASSES NO SURVEY IN. The reaper re-derives the proof
# from its own fresh survey; a step that handed it a cached reading would break exactly that
# property, which is the one that makes the act safe.
#
# AND IT ADDS NO CLAIM-LIVENESS TERM, by construction rather than by a second check. A live
# claim always carries at least its own `Claim <unit-id>` commit on the branch, so `ahead >= 1`,
# `merged` is false and the worktree cannot be a candidate. The reaper's header forbids a second
# safety authority beside `reclaimable` by name, and a second one is exactly how the reader a
# human consults and the writer that acts start disagreeing.
#
# THE PREDICATE IS NOT LOOSENED HERE, AND THAT IS THE OPERATOR'S OWN RULING (issue #1212,
# verbatim: *"`reclaimable` is merged AND clean, which is the right predicate and I am not
# proposing to loosen it"*). The consequence is stated rather than hidden: `merged` is `ahead ==
# 0` against `origin/<base>` — ANCESTRY — and every pull request this loop merges is
# squash-merged (2026-09-01), so a landed branch is never an ancestor of the base and `ahead`
# never returns to zero. A landed branch is therefore PERMANENTLY `merged: false`, the same
# misreading `superseded` was repaired for in issue #788: ancestry cannot answer *did this work
# land* and the tree can. Measured on this repository the day this shipped: 4 worktrees, 191.7 M
# held, `reclaimable_bytes: 0`, every one `unmerged`. THE FIRST SWEEP HERE FREES ZERO BYTES AND
# REMOVES NONE OF THEM, and that is the correct outcome, not a failure. It still ships: the same
# sweep run once on a consuming repository removed 44 worktrees and freed 5.4 GB with zero
# failures, because the merged-and-clean case does occur wherever a run reaches its end normally.
#
# THE SUMMARY SAYS WHAT IS HELD, NOT ONLY WHAT WAS FREED — the ask's second finding. `0 B
# reclaimable` beside 191.7 M held is a state no reader can explain from the outside, and a
# repository holding worktrees none of which can ever be freed used to read as a clean tick. The
# summary is the log-facing field AND the root's change key, so every term is a function of THE
# WORKTREE SET AND ITS SKIP REASONS ALONE — two ticks over an unchanged set render byte-identical
# summaries, so a held backlog produces no root line while a newly held worktree moves the set
# and is visible the hour it appears. That is `step-retire-claims.sh`'s stability rule applied
# here unchanged.
#
# BYTE TOTALS ARE DELIBERATELY EXCLUDED FROM THE SUMMARY AND THE EVENT. `du` output moves
# between ticks, so a byte count in the diff key would render a root line every hour for a
# backlog that had not changed — the noise this repository has retired two keyed roots for. A
# reader who wants the bytes runs `survey-worktrees.sh`, which is where they live.
#
# `needs_agent` IS EMPTY, for `step-retire-claims.sh`'s own reason: a merged-and-clean worktree
# is PROVED finished, so there is no judgement for a person to make. ESCALATING THE
# UNRECLAIMABLE BACKLOG TO A PERSON IS AN EXPLICIT NON-GOAL — it would need a size or an age
# threshold, and this repository does not add a constant without a home for it. The reading is
# shipped; whether a number should provoke a question is a later, separable decision, and the
# log now carries the evidence either way.
#
# AN `event` ONLY FOR AN ACTUAL REMOVAL, naming HOW MANY and never WHICH — the 2026-09-01 rule
# that a root line carries counts and a question carries identifiers. A sweep that removed
# nothing supplies an empty `event` and so renders no root line at all.
#
# A DEGRADED READING SWEEPS NOTHING. A missing reaper, empty output, or output this step cannot
# parse is `degraded` with its own reason word and nothing removed — `step-retire-claims.sh`'s
# *a degraded read retires nothing*. An absent `.worktrees/` directory and a repository with no
# linked worktrees are the ordinary `ok` case, not a degradation.
#
# IT MUST RUN FROM THE MAIN CHECKOUT, and that is an assumption stated rather than left
# implicit: `reap-worktrees.sh` resolves `here` from `git rev-parse --show-toplevel` and skips
# the current worktree, so a sweep invoked from inside a linked worktree would silently exclude
# that one. `/moderate` runs in the main checkout.
#
# Usage: step-worktree-sweep.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
BRANCHING_SCRIPTS="${SCRIPT_DIR}/../../branching/scripts"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done
: "${TICK:?}"

emit() {
    printf '{"step": "worktree-sweep", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

reaper="${BRANCHING_SCRIPTS}/reap-worktrees.sh"
[ -f "$reaper" ] || emit degraded no_reaper "reap-worktrees.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$reaper" --apply ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded reaper_unreadable "reap-worktrees.sh produced no output; nothing was swept"

printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded reaper_unparseable "reap-worktrees.sh produced output this step could not parse; nothing was swept"

removed=$(printf '%s' "$out" | jq '[.removed[]?] | length')
skipped=$(printf '%s' "$out" | jq '[.skipped[]?] | length')
failed=$(printf '%s' "$out" | jq '[.failed[]?] | length')

# `reclaimable` is what the predicate admitted: every one of those was either removed or refused
# by git's own second gate. It is read off the act's own envelope rather than re-derived, so this
# step still owns no predicate.
reclaimable=$((removed + failed))
total=$((removed + skipped + failed))

# THE SKIP-REASON BREAKDOWN IS THE HELD BACKLOG, RENDERED. Counts come from the reasons the
# reaper actually emitted, so a reason word added there appears here with no second vocabulary
# to keep in step; the four named below are ordered so the string is stable across ticks.
breakdown=$(printf '%s' "$out" | jq -r '
    ([.skipped[]?.reason] | group_by(.) | map({key: .[0], value: length}) | from_entries) as $c
    | ["unmerged", "dirty", "unmerged_and_dirty", "publication_transaction"] as $named
    | (($named | map("\(($c[.] // 0)) \(.)"))
       + ([$c | keys[] | select(. as $k | $named | index($k) | not)] | sort
          | map("\($c[.]) \(.)")))
    | join(", ")' 2>/dev/null || printf '')

summary="${total} worktree(s); ${reclaimable} reclaimable, ${removed} removed, ${skipped} skipped"
[ -z "$breakdown" ] || summary="${summary} — ${breakdown}"
[ "$failed" -eq 0 ] || summary="${summary}; ${failed} refused by git"

# THE EVENT NAMES THE COUNT AND NOTHING ELSE. A removal is a repository fact; which worktree it
# was is nobody's task, because nothing is left to act on — the checkout is gone and its branch
# and commits are untouched.
event=""
if [ "$removed" -eq 1 ]; then
    event="a worktree proved finished with was reclaimed — its branch and commits are untouched"
elif [ "$removed" -gt 1 ]; then
    event="${removed} worktrees proved finished with were reclaimed — their branches and commits are untouched"
fi

emit ok "" "$summary" "" "$event"
