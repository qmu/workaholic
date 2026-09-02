#!/bin/sh -eu
# A mission whose work was never RECORDED, because the branch that would have recorded it was
# closed unmerged.
#
# WHY THIS IS NOT `closable-missions` (2026-09-02, ticket
# `20260902065500-close-a-mission-whose-work-landed-by-another-route`). That step's proof is
# ARITHMETIC — `checked == total`, `unlinked == 0`, an empty queue — and these missions are its
# exact photographic negative: acceptance `0/N`, nothing ticked, the queue still full. Measured
# 2026-09-01/02: three missions read `status: active` with `0/3` acceptance and **17 queued
# tickets** between them, the `/implement` survey offered all three, and the behaviour each of
# them asked for was already on `main` — put there by a person's own single commit while the
# loop's own pull request was closed unmerged (#790/#789, #801/#800, #802/#800). Only the
# BOOKKEEPING is missing: no branch archived the tickets, so no seam ticked the acceptance and
# `close.sh` was never reached. Drivability is derived from *active area + plan + queued
# tickets*, and all three terms still hold — so the loop is queued to re-implement `main`.
#
# IT ASKS AND CLOSES NOTHING (the shape ruled in the ticket's own step 1, and it is the whole
# design). The reading available is *the acceptance is unticked and the queued tickets describe
# behaviour the base already has*, whose second half is a JUDGEMENT ABOUT BEHAVIOUR rather than
# a file test — and `list-stranded-publications.sh`'s own history records that a survey-side
# *already implemented* test was refused by name for exactly that reason. So this step names no
# act: `close.sh` writes `abandoned` and `carried` on a person's intent alone, and an automatic
# exclusion would hide a mission whose work genuinely still needs driving.
#
# FOUR TREE TERMS AND ONE BOUNDED READ. Active; acceptance entirely unticked; the mission's own
# `## Changelog` records no archived ticket; the queue is non-empty. Only a mission passing all
# four costs one `branch-pull-request-state.sh` read, and only `closed_unmerged` is a candidate
# — `merged` and `open` are each COUNTED and named by nothing, because the first is work that
# landed and the second is a unit still being driven.
#
# HOW THE BRANCH IS RESOLVED, AND WHY IT IS TWO SOURCES (measured while driving this ticket).
# The ticket says *the mission's recorded `claim:` branch*, and `claim.sh` does write that field
# — ON THE CLAIM BRANCH. A branch closed unmerged never reaches the base, so for precisely the
# missions this step is about, `main`'s copy carries no `claim:` line at all: all three measured
# missions read `status: active` with no `claim:` field. So the field is read first and the claim
# oracle's own row for the unit (`list-claims.sh`, keyed on the `Claim <unit>` commit) is read
# second. When NEITHER resolves — the branch was closed unmerged AND has since been deleted,
# which is what CI's own retirement now does — the mission is counted `claim_branch_unresolved`
# and asked about by nobody. That is a NAMED ABSENCE, never a candidate: this step may not name
# a mission whose pull request it never read.
#
# A DEGRADED READ IS NAMED, NEVER AN EMPTY SET. An unreadable pull request is counted as
# unreadable and never as *nothing to close* — the asymmetry `branch-pull-request-state.sh`
# spends its own longest comment on, applied one caller up.
#
# Usage: step-unrecorded-missions.sh --tick <id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"

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

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it.
# Empty means nothing happened here, and the renderer then emits no line at all.
emit() {
    printf '{"step": "unrecorded-missions", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

summary_sh="${MISSION_SCRIPTS}/summary.sh"
progress_sh="${MISSION_SCRIPTS}/progress.sh"
queuesize_sh="${MISSION_SCRIPTS}/queue-size.sh"
for _s in "$summary_sh" "$progress_sh" "$queuesize_sh"; do
    [ -f "$_s" ] || emit degraded no_mission_reader "$(basename "$_s") is not present beside this skill"
done
pr_reader="${DRIVE_SCRIPTS}/branch-pull-request-state.sh"
[ -f "$pr_reader" ] || emit degraded no_pull_request_reader \
    "branch-pull-request-state.sh is not present beside this skill; what a mission's branch became could not be read"

out=$( ( cd "$ROOT" && sh "$summary_sh" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded missions_unreadable "summary.sh produced no output"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded missions_unparseable "summary.sh produced output this step could not parse"

# The claim oracle, read ONCE for the whole step — the second of the two branch sources. A scan
# that could not reach the remote yields no rows and is not a degradation of this step: the
# `claim:` field still resolves, and a mission neither source answers for is counted by name.
claims_out=""
lister="${DRIVE_SCRIPTS}/list-claims.sh"
[ -f "$lister" ] && claims_out=$( ( cd "$ROOT" && sh "$lister" ) 2>/dev/null || true )

slugs=$(printf '%s' "$out" | jq -r '.[]?.slug' 2>/dev/null || true)

rows=""
rsep=""
n=0
scanned=0
skipped_progress=0
unresolved=0
unreadable=0
landed=0
in_flight=0
for slug in $slugs; do
    [ -n "$slug" ] || continue
    scanned=$((scanned + 1))

    prog=$( ( cd "$ROOT" && sh "$progress_sh" "$slug" ) 2>/dev/null || true )
    qsz=$( ( cd "$ROOT" && sh "$queuesize_sh" "$slug" ) 2>/dev/null || true )
    checked=$(printf '%s' "$prog" | sed -n 's/.*"checked": *\([0-9][0-9]*\).*/\1/p')
    total=$(printf '%s' "$prog" | sed -n 's/.*"total": *\([0-9][0-9]*\).*/\1/p')
    todo=$(printf '%s' "$qsz" | sed -n 's/.*"todo": *\([0-9][0-9]*\).*/\1/p')
    if [ -z "$checked" ] || [ -z "$total" ] || [ -z "$todo" ]; then
        skipped_progress=$((skipped_progress + 1))
        continue
    fi

    # Term 1+2: acceptance entirely unticked, and there is acceptance to tick.
    [ "$total" -gt 0 ] && [ "$checked" -eq 0 ] || continue
    # Term 3: there is still queued work, which is what makes this a live problem rather than a
    # closable mission. A drained one is `closable-missions`' candidate or nobody's.
    [ "$todo" -gt 0 ] || continue

    path=$(printf '%s' "$out" | jq -r --arg s "$slug" '.[] | select(.slug == $s) | .path' 2>/dev/null || printf '')
    [ -n "$path" ] || continue
    # Term 4: the mission's own changelog records no archived ticket. A seam that archived
    # anything would have appended a line, so this is *nothing was ever recorded here*.
    if grep -q -- '— ticket archived —' "${ROOT}/${path}" 2>/dev/null; then
        continue
    fi

    # The branch, from the mission's own recorded field first and the claim oracle second.
    branch=$(sed -n 's/^claim:[ \t]*\([^ \t]*\)[ \t]*$/\1/p' "${ROOT}/${path}" 2>/dev/null | head -1)
    if [ -z "$branch" ] && [ -n "$claims_out" ]; then
        branch=$(printf '%s' "$claims_out" \
            | jq -r --arg s "$slug" '[.claims[]? | select(.unit == $s) | .branch] | first // ""' 2>/dev/null || printf '')
    fi
    if [ -z "$branch" ]; then
        unresolved=$((unresolved + 1))
        continue
    fi

    look=$( ( cd "$ROOT" && sh "$pr_reader" "$branch" ) 2>/dev/null || true )
    if [ -z "$look" ] || ! printf '%s' "$look" | jq -e '.ok // false' >/dev/null 2>&1; then
        unreadable=$((unreadable + 1))
        continue
    fi
    state=$(printf '%s' "$look" | jq -r '.state // ""' 2>/dev/null || printf '')
    case "$state" in
        merged) landed=$((landed + 1)); continue ;;
        open)   in_flight=$((in_flight + 1)); continue ;;
        closed_unmerged) ;;
        *) continue ;;
    esac

    number=$(printf '%s' "$look" | jq -r '.number // "null"' 2>/dev/null || printf 'null')
    case "$number" in ''|*[!0-9]*) number=null ;; esac
    assignee=$(printf '%s' "$out" | jq -r --arg s "$slug" '.[] | select(.slug == $s) | .assignee // ""' 2>/dev/null || printf '')
    row=$(jq -nc --arg slug "$slug" --arg branch "$branch" --arg assignee "$assignee" \
        --argjson number "$number" --argjson queued "$todo" --argjson total "$total" '
        {slug: $slug, branch: $branch, assignee: (if $assignee == "" then "unknown" else $assignee end),
         pull_request: $number, queued: $queued, acceptance_total: $total,
         key: ("unrecorded-mission:" + $slug)}' 2>/dev/null || printf '')
    [ -n "$row" ] || continue
    rows="${rows}${rsep}${row}"
    rsep=","
    n=$((n + 1))
done
rows="[${rows}]"

summary="${scanned} active mission(s) scanned; ${n} whose pull request was closed unmerged with nothing recorded"
[ "$landed" -eq 0 ] || summary="${summary}; ${landed} whose pull request merged"
[ "$in_flight" -eq 0 ] || summary="${summary}; ${in_flight} still being driven"
[ "$unresolved" -eq 0 ] || summary="${summary}; ${unresolved} whose claim branch neither the mission nor the claim scan names"
[ "$unreadable" -eq 0 ] || summary="${summary}; ${unreadable} whose pull request could not be read"
[ "$skipped_progress" -eq 0 ] || summary="${summary}; ${skipped_progress} unreadable"

# An unreadable pull request is not "nothing to close". The step still reports every candidate it
# DID prove — losing a question because a different mission was unreadable trades one silence for
# another, which is `cadence-lapse`'s own rule applied here.
if [ "$n" -eq 0 ]; then
    [ "$unreadable" -eq 0 ] || emit degraded pull_request_unreadable "$summary"
    emit ok "" "$summary"
fi

needs=$(printf '%s' "$rows" | jq -c '{action: "ask_the_mission_assignee_to_close_or_redrive_this_mission",
    bound: "one question per mission, addressed to its assignee, keyed on `key` so it is asked once; the tick closes nothing, excludes nothing, touches no claim and drives nothing itself",
    compose: "lead with what happened -- this mission'"'"'s pull request was closed without merging, so nothing recorded its work and its tickets are still queued -- then the slug, then the one act: close it, or drive it again. `queued` is how many tickets are still waiting and `acceptance_total` how many acceptance items were never ticked; neither is an age. Never say the work is undone: what is known is that nothing RECORDED it.",
    missions: .}' 2>/dev/null || echo '{}')

if [ "$n" -eq 1 ]; then
    event="a mission's pull request was closed without merging, so nothing recorded its work and its tickets are still queued"
else
    event="${n} missions had their pull requests closed without merging, so nothing recorded their work and their tickets are still queued"
fi

status=ok
reason=""
if [ "$unreadable" -ne 0 ]; then
    status=degraded
    reason=pull_request_unreadable
fi
emit "$status" "$reason" "$summary" "$needs" "$event"
