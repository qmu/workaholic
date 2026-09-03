#!/bin/sh -eu
# Step — the publication the loop opened, could not merge, and must not settle itself.
#
# WHY THIS STEP EXISTS (2026-08-31, mission
# `repair-a-mechanically-resolvable-conflict-instead-of-reporting-it`). Once
# `settle-stranded-publication.sh` settles what a generator can settle, what is left is a
# conflict that genuinely needs a person — and the measured failure is that nobody was told,
# for a day, while the hourly tick reported the blockage to nobody in particular.
# `catchup-blocked` (retired 2026-09-02) asked about a `content` conflict on a REPORTED CLAIM only, and a publication
# is not a claim: it has no claim commit, so the oracle gives it no row and it reached no
# question at all.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS:
#
#   whose question           the retired `catchup-blocked`'s. The publication's AUTHOR opened it and is the
#                            person who knows which side of the collision keeps its meaning.
#   running identity         Never consulted. A publication that no longer merges is a fact
#                            about the repository, so an hourly question that depended on which
#                            container asked it would answer differently per account.
#   what it may read         that step's. `list-stranded-publications.sh` is a pure
#                            read; `plan-units.sh` is REFUSED, because the survey reaches the
#                            mission readers, which carry the living migrations and STAGE what
#                            they converge.
#
# ═══ THE TWO CANDIDATE SETS ARE DISJOINT BY CONSTRUCTION, AND NO FILTER IS ADDED ═════
# The ticket asked for the `retire-claims` / `stalled-units` division — one step asks, the
# other filters and counts. It does not apply here, and recording why is worth more than a
# counter that can only ever be zero (the retired step's own header set the
# precedent, for the widening whose honest outcome was a finding and no change):
#
#   * the claim-side candidates come from `list-claims.sh`, whose rows are branches
#     carrying a `Claim …` COMMIT. A publication carries none — that is what makes it a
#     publication — so it can never be a row there, and there is nothing to subtract.
#   * This step's own reader applies the term in the other direction too: a branch the claim
#     oracle names is dropped by `list-stranded-publications.sh` before anything else. So the
#     sets cannot overlap from either side, and a branch cannot draw both questions.
# `scripts/test-workflow-scripts.mjs` pins the disjointness rather than leaving it to a reading
# of two headers.
#
# ═══ ONLY `content` DRAWS A QUESTION ═════════════════════════════════════════════════
# `mechanical` and `clean` are the loop's own work — `/implement` settles both through
# `settle-stranded-publication.sh`, and asking about either would ask a person for the act the
# machinery is about to take. `unanswerable` is the ABSENCE of a reading, never actable and
# never a question addressed to somebody who can do nothing with it; it is COUNTED in the
# summary instead, so a reading that could not be made stays visible in the log rather than
# vanishing.
#
# THE CANDIDATE SET DID NOT MOVE WHEN `clean` BECAME SETTLEABLE (2026-09-01, mission
# `deliver-a-stranded-publication-that-needs-nothing-but-a-merge`). `content` is still the whole
# of it, and for its own unchanged reason: only a person can judge a collision. What moved is
# the `settleable` COUNT below, which is a reader-facing number rather than a candidate set —
# leaving it at `mechanical` would have understated by four on the morning the class was
# widened, and a count that understates what the loop owns is how a reader stops trusting it.
# No question, key, cap, addressee or gate moved with it.
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
settleable=$(printf '%s' "$out" | jq '[.publications[]? | select(.mergeability == "mechanical" or .mergeability == "clean")] | length')
n=$(printf '%s' "$candidates" | jq 'length')

# ── THE SECOND CANDIDATE SET: SETTLEABLE, AND ALREADY STALE ──────────────────────────
# `publish-tree-pr.sh` auto-merges on opening, so a proposal is normally written and landed
# minutes apart; only one the transport refused stays open long enough for its PLAN to go
# stale. Measured 2026-09-01: five of six open publications were `clean`, the oldest six days
# old, and landing them queued roughly fifteen tickets for work the loop had already finished.
#
# IT DOES NOT HOLD THE ACT, and that is the whole design. `/implement` settles a `clean` or
# `mechanical` publication unconditionally, exactly as before this question existed — an age
# threshold on the act would strand precisely the publications the `clean` widening exists to
# deliver, and this repository has paid repeatedly for a reading that stops something and tells
# nobody. So the two run independently: usually the act wins the hour and the question is the
# record; when a person gets there first, they can close it. Either way nobody merges silently.
#
# IT IS DISJOINT FROM THE `content` SET BY CONSTRUCTION — that set is exactly `content` and this
# one is exactly `mechanical`/`clean` — so no publication ever draws both questions, the
# `retire-claims`/`stalled-units` division applied to one reader's rows.
#
# AN UNREADABLE AGE IS NOT A CANDIDATE. `age_hours` is null when the timestamp could not be
# parsed, and asking on an absence is the failure the three-valued readings exist to avoid.
STALE_HOURS="${WORKAHOLIC_PUBLICATION_STALE_HOURS:-48}"
stale=$(printf '%s' "$out" | jq -c --argjson h "$STALE_HOURS" '[.publications[]?
    | select(.mergeability == "mechanical" or .mergeability == "clean")
    | select((.age_hours|type) == "number" and .age_hours >= $h)]' 2>/dev/null || printf '[]')
sn=$(printf '%s' "$stale" | jq 'length' 2>/dev/null || printf 0)

summary="${total} open publication(s); ${n} colliding on content — settling them belongs to an [Implement] run, not to this tick, which asks nobody about them"
[ "$settleable" -eq 0 ] || summary="${summary}; ${settleable} settleable by the loop itself"
[ "$sn" -eq 0 ] || summary="${summary}; ${sn} of those open long enough for its plan to be stale"
[ "$unreadable" -eq 0 ] || summary="${summary}; ${unreadable} whose mergeability could not be read"
[ "$sn" -eq 0 ] && [ -z "${event:-}" ] && [ "$n" -eq 0 ] && emit ok "" "$summary"

# ── A `content` COLLISION IS COUNTED AND ASKED ABOUT BY NOBODY (2026-09-02, mission
# `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`) ─────────────────────────
# The operator's words about the step that did this: it "was never asked for and is not
# working; it must not be used". `/implement` now ATTEMPTS every class including `content`
# (`settle-stranded-publication.sh`), because the class is a *prediction* computed with the
# repository's `.gitattributes` out of reach while the writer merges in a real checkout where
# those drivers are in force. What the merge itself cannot settle is the ACT's residue, and it
# is reported where the act happened — `/implement`'s run report, `settle_refused:
# content_conflict`, with the colliding files — never handed to a publication's author who
# never comes. The COUNT stays in the summary below: a reading is not a deferral.
rows="[]"

stalerows=""
srsep=""
for number in $(printf '%s' "$stale" | jq -r '.[].number'); do
    age=$(read_age "stranded-publication-stale:${number}")
    row=$(printf '%s' "$stale" | jq -c --argjson num "$number" --argjson age "$age" '
        .[] | select(.number == $num)
        | {number, branch, url, title,
           author: (if (.author // "") == "" then "unknown" else .author end),
           open_hours: .age_hours,
           mergeability,
           age: $age,
           key: ("stranded-publication-stale:" + (.number | tostring))}' 2>/dev/null || printf '')
    [ -n "$row" ] || continue
    stalerows="${stalerows}${srsep}${row}"
    srsep=","
done
stalerows="[${stalerows}]"

staleneeds=$(printf '%s' "$stalerows" | jq -c '{action: "ask_the_publication_author_whether_the_plan_this_would_queue_is_still_wanted",
    bound: "one question per pull request, addressed to its author, keyed on `key` so it is asked once. The tick asks and NOTHING else: it does not hold, delay, close or merge the publication, and `/implement` may settle it this same hour — the question is the record that it was not landed silently, never a gate in front of it.",
    compose: "lead with what happened in words a reader outside the repository understands -- something the loop wrote days ago is about to be published, and what it plans may already be done -- then the pull request and how long it has been open (`open_hours`). Say that merging it queues the plan it carries, and name the one act asked of them: say whether that plan is still wanted, or close the pull request. `open_hours` is how long the PULL REQUEST has been open; `age` is how long this has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`) -- never conflate them, say nothing about `age` when `age.first_seen` is null and the reading is readable, and when `age.readable` is false name it as an age we could not read, by its `age.reason`.",
    stale: .}' 2>/dev/null || echo '{}')

# THE EVENT NAMES A REPOSITORY FACT, NOT A PERSON'S TASK. It used to read "waiting on a
# person", which was the deferral in the root's own voice; the next `[Implement]` tick attempts
# every one of these.
if [ "$n" -eq 1 ]; then
    event="a published artifact collides with the base"
elif [ "$n" -gt 1 ]; then
    event="${n} published artifacts collide with the base"
else
    event=""
fi
if [ "$sn" -gt 0 ]; then
    if [ "$sn" -eq 1 ]; then
        stale_event="a published artifact has been waiting long enough that what it plans may already be done"
    else
        stale_event="${sn} published artifacts have been waiting long enough that what they plan may already be done"
    fi
    if [ -n "$event" ]; then event="${event}; ${stale_event}"; else event="$stale_event"; fi
fi

all_needs=""
[ "$sn" -eq 0 ] || all_needs="$staleneeds"

emit ok "" "$summary" "$all_needs" "$event"
