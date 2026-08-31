#!/bin/sh -eu
# Step — the publication the loop opened, could not merge, and must not settle itself.
#
# WHY THIS STEP EXISTS (2026-08-31, mission
# `repair-a-mechanically-resolvable-conflict-instead-of-reporting-it`). Once
# `settle-stranded-publication.sh` settles what a generator can settle, what is left is a
# conflict that genuinely needs a person — and the measured failure is that nobody was told,
# for a day, while the hourly tick reported the blockage to nobody in particular.
# `catchup-blocked` asks about a `content` conflict on a REPORTED CLAIM only, and a publication
# is not a claim: it has no claim commit, so the oracle gives it no row and it reached no
# question at all.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS:
#
#   whose question           `catchup-blocked`'s. The publication's AUTHOR opened it and is the
#                            person who knows which side of the collision keeps its meaning.
#   running identity         Never consulted. A publication that no longer merges is a fact
#                            about the repository, so an hourly question that depended on which
#                            container asked it would answer differently per account.
#   what it may read         `catchup-blocked`'s. `list-stranded-publications.sh` is a pure
#                            read; `plan-units.sh` is REFUSED, because the survey reaches the
#                            mission readers, which carry the living migrations and STAGE what
#                            they converge.
#
# ═══ THE TWO CANDIDATE SETS ARE DISJOINT BY CONSTRUCTION, AND NO FILTER IS ADDED ═════
# The ticket asked for the `retire-claims` / `stalled-units` division — one step asks, the
# other filters and counts. It does not apply here, and recording why is worth more than a
# counter that can only ever be zero (`step-catchup-blocked.sh`'s own header sets the
# precedent, for the widening whose honest outcome was a finding and no change):
#
#   * `catchup-blocked`'s candidates come from `list-claims.sh`, whose rows are branches
#     carrying a `Claim …` COMMIT. A publication carries none — that is what makes it a
#     publication — so it can never be a row there, and there is nothing to subtract.
#   * This step's own reader applies the term in the other direction too: a branch the claim
#     oracle names is dropped by `list-stranded-publications.sh` before anything else. So the
#     sets cannot overlap from either side, and a branch cannot draw both questions.
# `scripts/test-workflow-scripts.mjs` pins the disjointness rather than leaving it to a reading
# of two headers.
#
# ═══ ONLY `content` DRAWS A QUESTION ═════════════════════════════════════════════════
# `mechanical` is the loop's own work — `/implement` settles it, and asking about it would ask
# a person for the act the machinery is about to take. `clean` needs no catch-up at all.
# `unanswerable` is the ABSENCE of a reading, never actable and never a question addressed to
# somebody who can do nothing with it; it is COUNTED in the summary instead, so a reading that
# could not be made stays visible in the log rather than vanishing.
#
# THE COLLIDED FILES RIDE THE HEADING. A question that cannot name what collided does not say
# what to look at, and the reader already carries `mergeability_content_files` verbatim from
# `claim-mergeability.sh` — read here, never derived a second time.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason
# `step-stalled-units.sh`'s header records: an incrementing summary makes the step "changed"
# hourly by construction and the root restates the same publications all day.
#
# IT ASKS AND NOTHING ELSE: no merge, no catch-up, no push, no close, no claim touched, no gate
# lifted, and nothing written anywhere but its own tick-log line.
#
# Usage: step-stranded-publications.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/read-age.sh"
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
    printf '{"step": "stranded-publications", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

reader="${BRANCHING_SCRIPTS}/list-stranded-publications.sh"
[ -f "$reader" ] || emit degraded no_publication_reader \
    "list-stranded-publications.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$reader" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded publications_unreadable \
    "list-stranded-publications.sh produced no output"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded publications_unparseable \
        "list-stranded-publications.sh produced output this step could not parse"

# A DEGRADED READ IS NAMED, NEVER RENDERED AS *nothing stranded*. The reader carries its own
# reason and a null count for exactly this, so the step repeats its word rather than inventing
# one of its own.
if ! printf '%s' "$out" | jq -e '.ok // false' >/dev/null 2>&1; then
    why=$(printf '%s' "$out" | jq -r '.reason // "unknown"' 2>/dev/null || printf 'unknown')
    emit degraded "$why" \
        "the open publications could not be read (${why}); a stranded publication is indistinguishable from none this tick"
fi

total=$(printf '%s' "$out" | jq '.count // 0')
candidates=$(printf '%s' "$out" | jq -c '[.publications[]? | select(.mergeability == "content")]')
unreadable=$(printf '%s' "$out" | jq '[.publications[]? | select(.mergeability == "unanswerable")] | length')
settleable=$(printf '%s' "$out" | jq '[.publications[]? | select(.mergeability == "mechanical")] | length')
n=$(printf '%s' "$candidates" | jq 'length')

summary="${total} open publication(s); ${n} colliding on content"
[ "$settleable" -eq 0 ] || summary="${summary}; ${settleable} settleable by the loop itself"
[ "$unreadable" -eq 0 ] || summary="${summary}; ${unreadable} whose mergeability could not be read"
[ "$n" -eq 0 ] && emit ok "" "$summary"

rows=""
rsep=""
for number in $(printf '%s' "$candidates" | jq -r '.[].number'); do
    age=$(read_age "stranded-publication:${number}")
    row=$(printf '%s' "$candidates" | jq -c --argjson num "$number" --argjson age "$age" '
        .[] | select(.number == $num)
        | {number, branch, url, title,
           author: (if (.author // "") == "" then "unknown" else .author end),
           conflicted_files: (.mergeability_content_files // []),
           age: $age,
           key: ("stranded-publication:" + (.number | tostring))}' 2>/dev/null || printf '')
    [ -n "$row" ] || continue
    rows="${rows}${rsep}${row}"
    rsep=","
done
rows="[${rows}]"

needs=$(printf '%s' "$rows" | jq -c '{action: "ask_the_publication_author_to_resolve_the_conflict_the_loop_must_not_resolve",
    bound: "one question per pull request, addressed to its author, keyed on `key` so it is asked once; the tick asks and never merges, catches up, pushes or closes anything",
    compose: "lead with what happened in words a reader outside the repository understands -- an artifact the loop published is waiting because its change and the base changed the same lines -- then the pull request, then the files both sides changed. Say the loop already brought back everything a generator could settle and stopped here because only a person can judge this collision, and name the one act asked of them: resolve it on the pull request. `age` is how long this has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`) and never how long the pull request has been open; say nothing about it when `age.first_seen` is null and the reading is readable, and when `age.readable` is false name it as an age we could not read, by its `age.reason`.",
    stranded: .}' 2>/dev/null || echo '{}')

if [ "$n" -eq 1 ]; then
    event="a published artifact is waiting on a person — the loop brought back everything a generator could settle and stopped at a collision only somebody can judge"
else
    event="${n} published artifacts are waiting on a person — the loop brought back everything a generator could settle and stopped at collisions only somebody can judge"
fi

emit ok "" "$summary" "$needs" "$event"
