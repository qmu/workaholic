#!/bin/sh -eu
# Step 12 — missions that are finished and still open.
#
# WHY THIS STEP EXISTS (2026-08-23). Its sibling closes a mission at the archive gate, but
# that seam fires only when a run archives the mission's LAST ticket. It cannot catch a
# mission that reached full acceptance any other way — items ticked by a different seam, a
# mission whose tickets were archived before the seam shipped, one finished on a branch
# that never ran the gate. **Eleven such missions had accumulated and nobody was told.**
# They were found because the mission lens — the always-on hook retired on 2026-08-26,
# once this step owned the job — printed all of them on every prompt and the list had
# grown long enough to read as wrong. The gap is a reporting one: an accumulation must
# be visible before it is large.
#
# WHERE IT LIVES, AND WHY HERE RATHER THAN `/story` (ruled 2026-08-23 while driving it; the
# ticket required the home to be decided and recorded). `story/scripts/area-freshness.sh` is
# the exact precedent for a reporting-only upkeep seam and was the other candidate. This
# tick wins on audience and on shape:
#
#   - The residue accumulates over TIME, not at a merge. A per-merge report names it only
#     when somebody happens to merge something unrelated, which is how eleven went unseen.
#   - Closing a mission is the operator's act, and this tick is the surface that reaches an
#     operator hourly and keeps a dated log of what it saw.
#   - It is silent by construction when the set is empty: this contributes a report line,
#     never a question, and the tick posts only when it has a question to ask.
#
# IT REPORTS AND NEVER CLOSES, even though the arithmetic is identical to the sibling's.
# Two writers of an end state is exactly what `close.sh`'s single-writer rule exists to
# prevent, and the sibling owns the one case a machine may end.
#
# EVERY PART COMES FROM AN EXISTING READER, AND EVERY ONE OF THEM IS PURE. The active set
# and its `checked`/`total` come from `summary.sh`, `unlinked` from `progress.sh`, and the
# queue count from `queue-size.sh` — which is the reader `plan-units.sh` itself uses for that
# number, so this composes the survey's own queue read rather than a second one. No new
# parser of the `mission:` relation, which `read-relation.sh` owns and which is many-valued.
#
# `plan-units.sh` WAS THE OBVIOUS COMPOSITION AND IS REFUSED. Its `queue_drained` exclusion
# is exactly this candidate set, but the survey runs the living migrations and **stages**
# what they change — measured, by this step's own test: the report left
# `M .workaholic/missions/active/<slug>/mission.md` in the index. A step whose contract is
# *writes nothing* may not reach it through something that writes.
#
# THE ONE EXCEPTION TO "WRITES NOTHING", STATED RATHER THAN HIDDEN. The mission readers
# carry this repository's living migration for the mission layout and the status axis
# (`mission/scripts/lib/resolve.sh`), so on a NON-CONFORMANT tree — a mission outside
# `active/`/`archive/`, or one carrying a legacy `status:` — reading converges it and stages
# the change, exactly as any other mission-script touch does. That is the migration's
# contract, not this step's behaviour, and on a converged repository this step leaves the
# index byte-identical. It is named here because a reader that silently enlarged a caller's
# commit is a defect this project has already measured once (`migrate-concerns.sh`, which
# stages nothing for that reason).
#
# A DEGRADED READ IS NAMED, NEVER AN EMPTY SET. A survey that could not be read has not
# found "nothing waiting to be closed"; it has found nothing at all.
#
# THE NEAR MISS, ADDED 2026-09-01 (ticket
# `20260901123357-name-a-mission-at-full-acceptance-with-tickets-left`). The close above
# needs BOTH terms: acceptance fully checked AND the queue empty. A mission at FULL
# ACCEPTANCE WITH TICKETS STILL QUEUED fails the second, so it is closed by nobody and stays
# active indefinitely — measured on the day this was filed. Whether those leftovers are work
# that still matters, or work the mission's own landed changes have mooted, is a JUDGEMENT,
# so the loop may not close the mission and may not retire the tickets.
#
# SO IT IS A QUESTION, NOT A SECOND ACT. `close.sh` stays the only writer of an end state,
# `archive.sh` still closes only `achieved`, and the leftovers are named and left exactly
# where they are. Nothing here closes, retires, abandons, moves or ices anything: the two
# halves of this step are *close what is arithmetic* and *ask about what is not*, and the
# second half writes nothing at all.
#
# IT IS THE SAME SCAN, NOT A SECOND ONE. Both readings fall out of the one pass over
# `summary.sh`'s active set that this step already makes — the candidate differs from a
# closable mission in exactly one term — so no reader is added and nothing is walked twice.
# An unreadable `progress.sh` or `queue-size.sh` is not a proof and yields NEITHER a close
# NOR a question, which is the existing rule that an unreadable reader leaves the mission
# alone.
#
# Usage: step-closable-missions.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...]}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/read-age.sh"
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"

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
    printf '{"step": "closable-missions", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

summary="${MISSION_SCRIPTS}/summary.sh"
progress="${MISSION_SCRIPTS}/progress.sh"
queuesize="${MISSION_SCRIPTS}/queue-size.sh"
for _s in "$summary" "$progress" "$queuesize"; do
    [ -f "$_s" ] || emit degraded no_mission_reader "$(basename "$_s") is not present beside this skill"
done

out=$( ( cd "$ROOT" && sh "$summary" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded missions_unreadable "summary.sh produced no output"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded missions_unparseable "summary.sh produced output this step could not parse"

slugs=$(printf '%s' "$out" | jq -r '.[]?.slug' 2>/dev/null || true)

closable=''
leftover=''
n=0
n_leftover=0
scanned=0
for slug in $slugs; do
    [ -n "$slug" ] || continue
    scanned=$((scanned + 1))
    prog=$( ( cd "$ROOT" && sh "$progress" "$slug" ) 2>/dev/null || true )
    qsz=$( ( cd "$ROOT" && sh "$queuesize" "$slug" ) 2>/dev/null || true )
    checked=$(printf '%s' "$prog" | sed -n 's/.*"checked": *\([0-9][0-9]*\).*/\1/p')
    total=$(printf '%s' "$prog" | sed -n 's/.*"total": *\([0-9][0-9]*\).*/\1/p')
    unlinked=$(printf '%s' "$prog" | sed -n 's/.*"unlinked": *\([0-9][0-9]*\).*/\1/p')
    todo=$(printf '%s' "$qsz" | sed -n 's/.*"todo": *\([0-9][0-9]*\).*/\1/p')
    # An unreadable mission is skipped rather than reported as closable: this step names
    # what it can prove, and the scanned count says the rest. It yields NO near-miss
    # candidate either — an unreadable reader is not a proof of anything, in either
    # direction.
    [ -n "$checked" ] && [ -n "$total" ] && [ -n "$unlinked" ] && [ -n "$todo" ] || continue
    # Both readings share this one term. What separates them is the queue, and nothing else.
    [ "$total" -gt 0 ] && [ "$checked" -eq "$total" ] && [ "$unlinked" -eq 0 ] || continue
    if [ "$todo" -eq 0 ]; then
        n=$((n + 1))
        closable="${closable:+${closable},}$(printf '{"slug": "%s", "checked": %s, "total": %s, "queued": %s}' "$slug" "$checked" "$total" "$todo")"
    else
        # THE NEAR MISS: everything this mission promised is checked, and it still has work
        # queued. Whether that work still matters is the operator's ruling, so this is a
        # question and the mission is left exactly where it is.
        n_leftover=$((n_leftover + 1))
        key="mission-leftovers:${slug}"
        age=$(read_age "$key" "$ROOT")
        leftover="${leftover:+${leftover},}$(printf '{"slug": "%s", "checked": %s, "total": %s, "queued": %s, "key": "%s", "age": %s}' \
            "$slug" "$checked" "$total" "$todo" "$key" "$age")"
    fi
done

if [ "$n" -eq 0 ] && [ "$n_leftover" -eq 0 ]; then
    emit ok "" "no mission is waiting to be closed (${scanned} active mission(s) scanned)"
fi

# CLOSE, NOT ONLY TELL (2026-08-24, the developer's ruling — a mission the arithmetic
# proves finished is closed automatically). The single-writer rule holds: the agent
# re-proves each candidate in a publish tree and runs close.sh — the one writer — there,
# landing the closes through publish-tree-pr.sh. Only `achieved`, only on the re-proof;
# a candidate the re-proof rejects is reported, and abandoned/carried stay /mission-close's.
needs=''
if [ "$n" -gt 0 ]; then
    needs=$(printf '[%s]' "$closable" | jq -c '{action: "close_these_finished_missions_achieved",
        bound: "re-prove each in a publish tree (progress.sh checked==total unlinked==0, queue-size.sh todo==0), run close.sh <slug> achieved there, land via publish-tree-pr.sh; only achieved, never abandoned or carried; a rejected re-proof is reported not closed",
        closable: .}' 2>/dev/null || echo '{}')
fi

# THE SECOND ENTRY IS A QUESTION AND CARRIES NO ACT. It sits beside the close rather than
# inside it because the two are different kinds of thing: one is arithmetic a machine may
# perform, the other is a ruling only the mission's owner can make.
if [ "$n_leftover" -gt 0 ]; then
    ask=$(printf '[%s]' "$leftover" | jq -c '{action: "ask_the_owner_whether_these_leftover_tickets_still_matter",
        bound: "one question per mission, addressed to the mission owner, keyed on `key` so it is asked once. NOTHING is closed, retired, abandoned, iceboxed or moved: close.sh stays the only writer of an end state and the leftovers stay in the queue.",
        compose: "Lead with what happened in words a reader outside the repository understands — every acceptance item this mission promised is checked and it still has N tickets queued — then the slug. Name ONE act: rule whether those tickets still matter, or whether the work already landed has made them unnecessary. Never say the loop will close the mission or drop the tickets; it may not. `age` is how long this has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`); say nothing about it when `age.first_seen` is null and the reading is readable, and when `age.readable` is false name it as an age we could not read, by its `age.reason`, never as a condition that just started.",
        leftovers: .}' 2>/dev/null || echo '{}')
    needs="${needs:+${needs},}${ask}"
fi

summary="${n} mission(s) finished and still open, ${n_leftover} at full acceptance with tickets still queued, of ${scanned} active"

if [ "$n" -gt 0 ] && [ "$n_leftover" -gt 0 ]; then
    event="${n} mission(s) are finished and still open, and ${n_leftover} met their acceptance with work still queued"
elif [ "$n" -gt 0 ]; then
    event="${n} mission(s) are finished and still open"
else
    event="${n_leftover} mission(s) met their acceptance with work still queued"
fi

emit ok "" "$summary" "$needs" "$event"
