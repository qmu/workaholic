#!/bin/sh -eu
# Step 11 — what is claimed, and how long it has not moved.
#
# WHY THIS STEP EXISTS (2026-08-23, issue #584 / the report filed as osbrjp/coop-csnet#83).
# A consuming repository's loop stopped for eleven consecutive ticks. Every tick ran,
# reported `blocked` correctly, and spent agent-hours; the only outbound signal was a
# mention-less reply inside a feedback thread written the previous day. Slack notified
# nobody, channel level showed nothing, and the developer found the stall by noticing the
# channel had not moved in ten hours.
#
# There was no path from *the loop is stuck* to *a person is asked*. `/implement` cannot
# ask — no `AskUserQuestion` anywhere, at any step — and this tick's check-in, the one
# surface in this plugin that names a person and therefore notifies them, asked only about
# what its own steps had found. No step read the state of claimed work, so the surface that
# could ask never learned there was anything to ask about.
#
# THE COUPLING IS A READER, NOT A HANDOFF — the same shape as `strategy-pace` beside it.
# A `/implement` run writes nothing into the tree about its own blockers and its container
# is discarded, so it could not leave a finding here even if it wanted to. This step calls
# the claim oracle itself: `drive/scripts/list-claims.sh`, a pure read over unmerged remote
# branches, which is already the only thing in this plugin allowed to answer "what is
# claimed". Two readers of one script is not two sources of truth.
#
# THE AGE COMES FROM THE CLAIM BRANCH TIP AND NOWHERE ELSE. The heartbeat already advances
# that tip (`drive/scripts/heartbeat.sh`), so "how long since this unit moved" is already
# recorded by the protocol. Deriving a second notion of last activity — a file, a stored
# cursor, a mission field — would give the claim protocol two clocks, and the one that
# drifted would be believed.
#
# IT REPORTS EVERY CLAIM AND NARROWS ONLY WHAT IT ASKS ABOUT. The summary counts every
# claimed unit; only the `needs_agent` candidates are filtered. Nothing is dropped from the
# reading — a reader who wants the whole picture gets it, and the narrowing is visible in the
# same line as the total.
#
# THREE FILTERS, NOT ONE. The threshold below, and two verdicts:
#
#   `superseded` (2026-08-26) — a claim whose work already reached the base is FINISHED, so
#   there is nothing for a person to look at and nothing for them to decide. Asking anyway is
#   the question layer crying wolf, and it is not free: the asked-once ledger means the one real
#   stalled unit then arrives inside a stream a person has learned to skip. Measured: three
#   merged pull requests were each being asked about.
#
#   `awaiting_verification` (2026-08-27, mission
#   `ask-for-the-one-act-a-declared-handoff-is-waiting-on`) — the same argument one verdict over.
#   Such a unit is not stalled by accident: it was DECLARED unverifiable in an unattended
#   environment at creation, and §6 left its pull request open and its claim standing on purpose.
#   "A claimed unit has not moved for a day or more" sends the person to look at a claim when
#   what they need is the one act it waits on, and `handoff-units` now asks in the vocabulary of
#   that act. Left here it would be worse than redundant: the real question would arrive beside a
#   differently-worded one about the same unit, which is exactly the cost the first filter exists
#   to prevent. ONE STEP ASKS AND THE OTHER FILTERS is the invariant, and either half alone is a
#   defect — the mission's pin keeps the pair honest.
#
# Both are counted in the summary as findings instead, which is where a fact belongs. The filter
# is NOT widened to "any non-resumable verdict": `queue_drained` and `report_undelivered` are
# different states with different owners, and a blanket filter would silently drop a class
# nobody covers.
#
# THE SUMMARY CARRIES NO AGE, AND THAT IS A CORRECTNESS REQUIREMENT (2026-08-26). The
# moderation root calls a step changed when its summary differs from the same step's an hour
# ago, and `render-tick-post.sh` normalises out a timestamp, a bare hex object name and a clock
# time — and ONLY those. `oldest stopped 27h` increments every tick, so it made this step
# changed HOURLY by construction and the root restated the same stalled units four times in one
# day: exactly the shape `📦 Release Preparation` was retired for. The age is still
# computed and still reaches the person, in the question that names the unit.
#
# IT READS, AND IT HANDS THE STALE ONES TO THE CHECK-IN TO ASK ABOUT. The reading shipped
# inert first; the asking is the second half, and it is the whole point of the step.
#
# THE THRESHOLD IS THE CLAIM PROTOCOL'S OWN `stale`, and none of the three options the
# ticket listed (ruled 2026-08-23 while driving it; the ticket required an explicit ruling).
# `lib/claims.sh` already decides when a claim branch has not moved long enough that a human
# should look — `WORKAHOLIC_CLAIM_STALE_HOURS`, default 24 — and its header states the
# meaning in the exact words this step needs: *a tip older than the threshold says "look at
# this", not "take it"*. Asking a person to look IS that, so the reuse is principled rather
# than convenient, and it beats each listed option on that option's own cost:
#
#   (a) a fixed tick count — refused: it invents an arbitrary constant beside one that
#       already exists, already has a justification, and is already configurable.
#   (b) across a working-day boundary — refused: it composes a boundary this plugin owns,
#       which is right, but a unit stalling at 09:05 then waits nearly a full day before
#       anyone hears, and the measured failure WAS a day of silence. `stale` is 24 hours
#       from the stall rather than 24 hours to the next boundary, so it has that option's
#       shape without its cliff. The working-week half of (b) is not lost either: it lives
#       downstream in `step-human-checkin.sh`, which holds a question over the weekend
#       already, so this threshold does not need to know about days at all.
#   (c) two ticks plus an unresolved Open Decision — refused: fast, but it names one blocker
#       class. A missing credential and a failing gate stall a unit exactly as hard and need
#       a person exactly as much.
#
# IT ASKS; IT NEVER CLAIMS, DRIVES OR RESOLVES. The candidate goes to the check-in as
# `needs_agent` and nothing else happens here — no claim is touched, no branch is written,
# no blocker is cleared. The tick has no second route into work.
#
# THE ALERT SHAPES ARE UNCHANGED, DELIBERATELY. `🔴 Blocked` and `↳ still failing` still
# carry no mention token. They are the run's record of an outcome; this question is a demand
# on a person's attention. Two speech acts, and making the record louder is the direction
# this repository has already retired twice — the failure was never volume, it was that
# nothing addressed anybody.
#
# A DEGRADED READ IS NAMED, NEVER RENDERED AS CALM. `fetched: false` means the claim scan
# could not reach the remote, and unmerged remote branches are the *only* claim oracle — so
# a local-only scan does not mean nothing is stalled, it means nothing could be read.
# `shallow: true` means the history was truncated and a merged unit can look claimed. Both
# report `degraded` with the reason, exactly as every other reader in this tick does.
#
# Usage: step-stalled-units.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...]}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/read-age.sh"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"
# The claim library, for `claims_unit_resolution` alone — the raced-unit filter below reads the
# library's own single derivation rather than a second implementation of "two live claims".
CLAIMS_LIB_DIR="${DRIVE_SCRIPTS}/lib"
[ -f "${CLAIMS_LIB_DIR}/claims.sh" ] && . "${CLAIMS_LIB_DIR}/claims.sh"
. "${SCRIPT_DIR}/lib/raced-units.sh"

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

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it
# (2026-08-23). Two audiences: the log is an audit trail a maintainer reads when the tick
# misbehaves and keeps every counter; the root is read by a person scanning a channel, who
# needs the repository's event. This step supplies it because it knows what its finding means.
# **Empty means nothing happened here** — the renderer then emits no line at all, independently
# of the change diff.
emit() {
    printf '{"step": "stalled-units", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

lister="${DRIVE_SCRIPTS}/list-claims.sh"
[ -f "$lister" ] || emit degraded no_claim_reader "list-claims.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$lister" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded claims_unreadable "list-claims.sh produced no output"

printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded claims_unparseable "list-claims.sh produced output this step could not parse"

fetched=$(printf '%s' "$out" | jq -r '.fetched // false')
shallow=$(printf '%s' "$out" | jq -r '.shallow // false')

# Unmerged remote branches are the ONLY claim oracle, so a scan that could not reach the
# remote has not found "no stalled units" — it has found nothing at all.
[ "$fetched" = "true" ] || emit degraded origin_unreachable \
    "the claim scan could not reach the remote; what is claimed could not be read this tick"
[ "$shallow" = "true" ] && emit degraded shallow_history \
    "the claim scan ran over truncated history; a merged unit is indistinguishable from a held one"

# Per claim: the unit, its branch, who holds it, how long since the branch last moved, and
# whether it ever reached a pull request. `reported` is the claim oracle's own offline
# signal (the branch carries the story file `/story` commits when it opens the PR) — this
# step does not ask GitHub, so a tick with no network still answers.
#
# THE AGE IS COMPUTED WITH `date`, NOT WITH jq's `fromdateiso8601`. That builtin accepts
# only the `Z` form, and the claim oracle emits `%cI` — a git committer date, which carries
# the committing machine's offset (`+09:00` here). Parsing those in jq reported five of
# seven live claims as "unknown age" on the first run of this step, which is precisely the
# reading a stalled-unit reader must never get wrong.
now=$(date +%s)
rows='[]'
tsv=$(printf '%s' "$out" | jq -r '.claims[]? | [.unit, .branch, (.author // "unknown"), (.last_commit_at // ""), (.reported // false), (.resume_reason // ""), (.stale // false)] | @tsv' 2>/dev/null || true)
if [ -n "$tsv" ]; then
    rows=$(
        printf '%s\n' "$tsv" | while IFS='	' read -r u b o at rep rr st; do
            [ -n "$u" ] || continue
            hours=null
            if [ -n "$at" ] && [ "$at" != "unknown" ]; then
                epoch=$(date -d "$at" +%s 2>/dev/null || true)
                [ -n "$epoch" ] && hours=$(( (now - epoch) / 3600 ))
            fi
            printf '%s\n' "$u" "$b" "$o" "$at" "$rep" "$rr" "$st" \
                | jq -Rn --argjson h "$hours" '
                    [inputs] as $f
                    | {unit: $f[0], branch: $f[1], owner: $f[2],
                       last_commit_at: (if $f[3] == "" then "unknown" else $f[3] end),
                       stalled_hours: $h,
                       has_pull_request: ($f[4] == "true"),
                       resume_reason: $f[5],
                       stale: ($f[6] == "true"),
                       key: ("stalled-unit:" + $f[0])}'
        done | jq -sc '.'
    )
fi
[ -n "$rows" ] || rows='[]'

count=$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)
[ "$count" -eq 0 ] && emit ok "" "nothing is claimed; no unit is stopped"

# An age the tip could not date is reported as unknown rather than as zero: a claim whose
# timestamp is unreadable is exactly the one a reader must not call fresh.
unknown_age=$(printf '%s' "$rows" | jq '[.[] | select(.stalled_hours == null)] | length')
oldest=$(printf '%s' "$rows" | jq '[.[] | .stalled_hours // 0] | max // 0')
with_pr=$(printf '%s' "$rows" | jq '[.[] | select(.has_pull_request)] | length')

# THE THRESHOLD IS `stale`, THE CLAIM PROTOCOL'S OWN (see the header): a branch that has not
# moved for `WORKAHOLIC_CLAIM_STALE_HOURS` (default 24) is already the protocol's way of
# saying "look at this". The content key is `stalled-unit:<unit>` — stable across ticks, which
# is what makes `ask-question.sh`'s already-asked ledger able to ask exactly once.
# A `superseded` CLAIM IS A FACT, NOT A QUESTION (2026-08-26). Its work already reached the
# base, so there is nothing for the person to look at and nothing for them to decide —
# asking them to is the question layer crying wolf, and the asked-once ledger then delivers
# the REAL stalled unit inside a stream a person has learned to skip. Measured: three merged
# pull requests were each being asked about. They stay in the log as a counted finding, which
# is where a fact belongs.
# AND A `awaiting_verification` CLAIM IS A FACT WITH ANOTHER STEP'S QUESTION ON IT (2026-08-27).
# It was DECLARED unverifiable here at creation, so the honest question names the declared act,
# which `handoff-units` asks. Filtered in the SAME expression as `superseded` — one rule with two
# verdicts, not two mechanisms — and counted here, so nothing is dropped from the reading.
# AND A RACED UNIT IS A FACT WITH ANOTHER STEP'S QUESTION ON IT (2026-08-30, mission
# `stop-two-runs-from-claiming-and-driving-one-unit`). A unit held by two live claims is not a
# unit that has stopped — it is one two runs are driving at once — so "a claimed unit has not
# moved for a day or more" sends a person to look at one claim when the honest question names
# both. `raced-units` asks it; this step filters and COUNTS, the same half of the same rule
# `superseded` and `awaiting_verification` already follow. The set comes from the library's own
# `claims_unit_resolution` over the scan this step already made, so no second walk and no second
# definition of a race exists; an unreadable claims payload yields an empty set and filters
# nothing, which is the safe direction.
raced_set=$(raced_units "$out" 2>/dev/null || true)

finished=$(printf '%s' "$rows" | jq -c '[.[] | select(.resume_reason == "superseded")]')
n_finished=$(printf '%s' "$finished" | jq 'length')
declared=$(printf '%s' "$rows" | jq -c '[.[] | select(.resume_reason == "awaiting_verification")]')
n_declared=$(printf '%s' "$declared" | jq 'length')
stalled=$(printf '%s' "$rows" | jq -c '[.[] | select(.stale)
    | select(.resume_reason != "superseded" and .resume_reason != "awaiting_verification")]')
n_raced=0
if [ -n "$raced_set" ]; then
    raced_json=$(printf '%s\n' "$raced_set" | jq -Rsc 'split("\n") | map(select(length > 0))')
    n_raced=$(printf '%s' "$stalled" | jq --argjson r "$raced_json" '[.[] | select(.unit as $u | $r | index($u))] | length')
    stalled=$(printf '%s' "$stalled" | jq -c --argjson r "$raced_json" '[.[] | select(.unit as $u | ($r | index($u)) | not)]')
fi
n_stalled=$(printf '%s' "$stalled" | jq 'length')

# THE AGE IS DELIBERATELY ABSENT FROM THE SUMMARY (2026-08-26). The moderation root calls a
# step changed when its summary differs from the same step's an hour ago, and
# `render-tick-post.sh` normalises out a timestamp, a bare hex object name and a clock time —
# and ONLY those. `oldest stopped 27h` increments every tick, so it made this step changed
# hourly BY CONSTRUCTION and the root restated the same stalled units four times in one day:
# exactly the shape `📦 Release Preparation` was retired for. What the maintainer needs from
# the age is in the question, which names the unit; what the diff needs is a summary that
# moves only when the finding does.
summary="${count} claimed unit(s); ${with_pr} at a pull request, ${unknown_age} of unknown age; ${n_finished} finished (superseded), ${n_declared} awaiting a declared verification, ${n_raced} held by two live claims, ${n_stalled} past the claim protocol's staleness threshold"

if [ "$n_stalled" -eq 0 ]; then
    # A finished claim never earns a root line either, and neither does a declared handoff:
    # nothing happened TO the repository here, and a step with no event renders no line. The
    # standing handoff's own event belongs to `handoff-units`, which owns its question too.
    emit ok "" "$summary"
fi

# HOW LONG THIS UNIT HAS BEEN ASKED ABOUT, beside the claim tip's own staleness (2026-08-30,
# mission `say-how-long-the-loop-has-been-stuck`). TWO AGES, TWO SOURCES, NEVER BLENDED: the tip
# answers *how long has this not moved*, the question ledger answers *how long have we been
# asking*, and a unit stalled for a day that nobody has been told about is a different situation
# from one a person was asked about a week ago. `drive/reference/claims.md`'s source table records
# which question reads which, and the rule it exists for — NOTHING DERIVES AN AGE TWICE.
#
# Keyed on the `stalled-unit:<unit>` key the row already carries, so no key moves and
# `already_asked` is byte-identical. The SUMMARY is untouched, for the reason this file's own
# header records at length.
stalled=$(
    printf '%s' "$stalled" | jq -c '.[]?' 2>/dev/null | while IFS= read -r row; do
        [ -n "$row" ] || continue
        key=$(printf '%s' "$row" | jq -r '.key // ""' 2>/dev/null || printf '')
        age=$(read_age "$key" "$ROOT")
        printf '%s' "$row" | jq -c --argjson a "$age" '. + {age: $a}' 2>/dev/null || printf '%s' "$row"
    done | jq -sc '.' 2>/dev/null || printf '%s' "$stalled"
)

needs=$(printf '%s' "$stalled" | jq -c '{action: "ask_the_owner_whether_this_stalled_unit_still_needs_them",
    bound: "one question per unit, addressed to the claim holder, keyed on `key` so it is asked once; the tick asks and never claims, drives, or resolves the blocker itself",
    compose: "name what is stuck and what the run could not decide — a signature is not a problem — and say the answer is given in this session, through the link on the question. TWO AGES ride this candidate and they are two facts with two sources: `stalled_hours` is how long the CLAIM TIP has not moved, `age` is how long the unit has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`). Name them as two, never blended into one number, and say nothing about the log age when `age.first_seen` is null and the reading is readable — that is the first time anybody is being asked. When `age.readable` is false, name it as an age we could not read, by its `age.reason`, never as a condition that just started.",
    stalled: .}' 2>/dev/null || echo '{}')

# THE EVENT NAMES THE REPOSITORY EVENT AND CARRIES NO AGE, for the reason above: the root is
# read by a person scanning a channel, and `N units have not moved for a day or more` is the
# event; `oldest stopped 27h` is bookkeeping that would make every hour look like news.
if [ "$n_stalled" -eq 1 ]; then
    event="a claimed unit has not moved for a day or more"
else
    event="${n_stalled} claimed units have not moved for a day or more"
fi

emit ok "" "$summary" "$needs" "$event"
