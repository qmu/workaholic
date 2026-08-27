#!/bin/sh -eu
# Step — queued work nothing can drive, because its owner is an address nobody maps.
#
# WHY THIS STEP EXISTS (2026-08-26). `plan-units.sh` learned to say when it excluded its
# whole backlog, which makes the fact visible in a run report. A run report is read by
# nobody on the day it matters — the same reason `/propose`'s report was refused as the
# surface for `strategy-pace` — and `/implement` may not ask (no `AskUserQuestion`, at any
# step). So there was no path from *the loop cannot drive its own output* to *a person is
# told*: measured on this repository, ten units sat undrivable for five days while every
# hourly tick reported a clean, current survey.
#
# THE SHAPE IS `step-stalled-units.sh`'s, deliberately: a step reads pure readers, hands
# candidates to the check-in as questions addressed to a named person, keyed so each is
# asked exactly once.
#
# IT DOES NOT READ `plan-units.sh`, AND THE TICKET THAT ASKED FOR THIS NAMED IT AS "a pure
# read". It is not one: the survey reaches the mission readers, which carry this
# repository's living migrations and STAGE what they converge, and
# `step-closable-missions.sh` refused the same composition for the same reason — *a step
# whose contract is writes nothing may not reach it through something that writes*, measured
# by that step's own test, which caught the report leaving a modified mission in the index.
# So the candidate set is derived from the readers the survey itself uses for OWNERSHIP —
# `gather/scripts/owners.sh` (the field's one parser, with its legacy tiers) over
# `gather/scripts/identity.sh` (the mapping's one reader) — walking the two areas that hold
# queued work. No ownership rule is re-implemented here; only the enumeration is, and that
# is what keeps the step's stated contract true.
#
# THE FINDING IS ABOUT THE REPOSITORY, NOT ABOUT THE RUNNER, which is why the runner's own
# identity is never consulted. An owner no mapping entry names is undrivable by EVERY
# runner, so this tick — repository-scoped, one copy for the whole team — produces the same
# answer from any account. Keying it on `owns.sh`'s three-way answer would make an hourly
# repository-wide question depend on which container asked it.
#
# A COLLEAGUE'S QUEUE PRODUCES NO QUESTION, and that is the whole care in the step. Work
# owned by somebody the mapping names is a colleague's queue working exactly as designed;
# an hourly complaint about ordinary team ownership is muted within a day, and the one real
# finding then arrives inside a stream a person has learned to skip. The mapping is what
# tells the two apart, which is why this reads `identity.sh` rather than the raw address.
#
# IT ASKS AND NOTHING ELSE. It reassigns nothing, writes no artifact, touches no claim and
# lifts no gate. A reporting step that quietly becomes a writer is how the tick grows a
# second route into work; the repair for an uncovered address is a human's line in
# `.claude/git-identities`, which `/workaholify`'s coverage audit proposes.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, and that is a correctness requirement rather
# than a preference (`step-stalled-units.sh`'s header records the measurement). The
# moderation root calls a step changed when its summary differs from the same step's an hour
# ago, and `render-tick-post.sh` normalises out a timestamp, a bare hex object name and a
# clock time — and only those. A summary that moves every tick marks the step changed hourly
# by construction, which is exactly the shape `📦 Release Preparation` was retired for.
#
# IT COUNTS EVERY OWNED UNIT AND NARROWS ONLY WHAT IT ASKS ABOUT, so a reader gets the whole
# picture and the narrowing is visible in the same line as the total.
#
# A DEGRADED READ IS NAMED, NEVER RENDERED AS CALM: a tree whose queue could not be walked
# has not found "nothing undrivable", it has found nothing at all.
#
# Usage: step-undrivable-units.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"

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
    printf '{"step": "undrivable-units", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

[ -f "${GATHER_SCRIPTS}/owners.sh" ] && [ -f "${GATHER_SCRIPTS}/identity.sh" ] \
    || emit degraded no_ownership_readers "the ownership readers are not present beside this skill"

WORKAHOLIC="${ROOT}/.workaholic"
[ -d "$WORKAHOLIC" ] || emit ok "" "this repository holds no .workaholic tree; nothing is queued"

# The two areas that hold work a run could take: the queue, and the active missions that
# plan it. Enumerated directly rather than through the survey — see the header.
artifacts=$(
    { find "${WORKAHOLIC}/tickets/todo" -name '*.md' -type f 2>/dev/null || true
      find "${WORKAHOLIC}/missions/active" -name 'mission.md' -type f 2>/dev/null || true
    } | sort
)

n_owned=0
n_unmapped=0
candidates=""
c_sep=""

for file in $artifacts; do
    owners=$(sh "${GATHER_SCRIPTS}/owners.sh" "$file" 2>/dev/null || true)
    # Empty means TEAM-OWNED — claimable by anyone, the healthy state, never a candidate.
    [ -n "$owners" ] || continue
    n_owned=$((n_owned + 1))

    for owner in $owners; do
        answer=$(sh "${GATHER_SCRIPTS}/identity.sh" "$owner" "${ROOT}/.claude/git-identities" 2>/dev/null || true)
        resolved=$(printf '%s' "$answer" | sed -n 's/.*"resolved": *\([a-z]*\).*/\1/p')
        [ "$resolved" = "true" ] && continue

        n_unmapped=$((n_unmapped + 1))
        rel=$(printf '%s' "$file" | sed "s|^${ROOT}/||")
        candidates="${candidates}${c_sep}{\"artifact\": \"${rel}\", \"owner\": \"${owner}\", \"key\": \"undrivable-unit:${rel}\"}"
        c_sep=", "
        # One question per unit, whatever the size of its owner list.
        break
    done
done

summary="${n_owned} queued artifact(s) name an owner; ${n_unmapped} name an address the identity mapping does not"

if [ "$n_unmapped" -eq 0 ]; then
    # A queue every owner of which the mapping names is the healthy state: nothing happened
    # TO the repository, and a step with no event renders no root line at all.
    emit ok "" "$summary"
fi

needs=$(printf '%s' "[${candidates}]" | jq -c '{action: "ask_about_work_no_run_can_drive",
    bound: "one question per artifact, addressed to the direction'"'"'s assignee, keyed on `key` so it is asked once; the step asks and never reassigns, writes, or lifts a gate",
    compose: "name the artifact and the address no mapping entry names, and say the repair is one line in .claude/git-identities — /workaholify'"'"'s coverage audit proposes it with the address already filled in",
    undrivable: .}' 2>/dev/null || echo '{}')

if [ "$n_unmapped" -eq 1 ]; then
    event="a queued unit is owned by an address the identity mapping does not name"
else
    event="${n_unmapped} queued units are owned by addresses the identity mapping does not name"
fi

emit ok "" "$summary" "$needs" "$event"
