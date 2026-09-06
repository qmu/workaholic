#!/bin/sh -eu
# Which of a mission's acceptance items are answered by a ticket that declared a
# verification handoff.
#
# Usage: acceptance-handoffs.sh <mission-slug-or-file>
# Output: JSON {"handoff": true|false, "tickets": ["<basename>", ...],
#               "measurable_tickets": ["<basename>", ...], "unresolved": [...]}
#
# `tickets` names the declarations that HELD the close -- prose, and prose only.
# `measurable_tickets` names the `probe:` declarations that were found and did NOT hold,
# so the refusal can say which form it is refusing on and a reader can tell the two apart.
#
# WHY IT EXISTS. `archive.sh` closes a mission on ARITHMETIC -- every acceptance item
# ticked, none unlinked, the queue empty -- and that arithmetic cannot see the one fact
# that makes the sum a lie. A ticket declaring `verification_handoff` is archived as
# implemented, because the code IS written; the acceptance item naming it therefore
# ticks, and the mission closes `achieved` while the thing the item asserts was verified
# by nobody. Measured 2026-08-31 on
# `bring-the-theme-master-onto-the-one-master-seam-so-the-deployed-app-can-write-it`,
# whose second item -- create, update and delete working on the DEPLOYED screen -- was
# ticked by the archive of the very ticket that had declared no unattended runner could
# reach a deployment, and whose own Final Report says the round did not run.
#
# WHAT IT IS NOT. It is not a second reader of the declaration.
# `drive/scripts/verification-handoff.sh` is the one reader of `verification_handoff:`
# and this delegates to it, exactly as the ticket asking for this required: the archive
# gate becomes a second CONSUMER of that answer rather than a second derivation of it.
# What this script owns is the other half -- which tickets an acceptance item names --
# and it reads that with the same `(#<basename>)` marker `tick-acceptance.sh` matches.
#
# A MEASURABLE DECLARATION DOES NOT HOLD THE CLOSE (2026-09-06, ticket `20260906105853`,
# mission `finish-the-backlog-without-handing-it-back-to-the-operator`). The reader above
# answers on the PRESENCE of a `verification_handoff:` line -- including the `probe:` form,
# which exists precisely to be re-tested and which `/drive` §6 runs at claim time. MEASURED
# on this mission, by the run that archived its last ticket: the queue drained at 3/3 and
# this gate refused, naming a ticket whose declaration is `probe: command -v codex`, which
# `run-verification-probe.sh` had answered `clean` in that same run against an installed
# CLI. The verification was performed and the mission was held open for a person to repeat
# it -- the unfalsifiable-blocker failure that mission exists to end.
#
# IT IS THE CONSUMER THAT DISTINGUISHES, NOT THE READER. `verification-handoff.sh` keeps
# answering on presence: it is the one reader of the field and §6 depends on that answer to
# decide which route a unit takes. This is exactly the precedent
# `drive/scripts/lib/claims.sh`'s `claims_declared_handoff` set one layer down, where a
# measurable declaration stopped parking a claim `awaiting_verification` -- same field, same
# reader, the distinction made by each consumer for its own reason.
#
# THIS GATE DOES NOT RUN THE PROBE, AND THAT IS A DECISION RATHER THAN AN OMISSION. The
# hazard that kept the probe out of the offline claim scan does not transfer -- `archive.sh`
# runs inside a worktree at commit time -- so it was weighed on its own terms and refused for
# three others. (1) `run-verification-probe.sh` is the one runner and §6 is the one site that
# runs it; a second execution site is a second derivation of *is this blocking here*, and two
# derivations of one question eventually disagree. (2) This walk resolves EVERY acceptance
# item's ticket, including tickets driven by other units in other runs, so running them here
# would execute artifact-supplied commands for work this run never claimed. (3) The close is
# ARITHMETIC; making it depend on a command's exit status would make an unattended close turn
# on a reading designed to become false when re-run, which `archive.sh` already refuses by
# name for the drill verdict it prints beside the close.
#
# THE COST, STATED. A `probe:` declaration that would read `blocking` no longer holds this
# gate either, so a mission whose acceptance rests on such a ticket now closes `achieved` on
# the arithmetic the run already proved. That is bounded by where the probe IS read: §6 takes
# such a unit down the handoff route, its pull request stays open and its claim stays
# standing, so the work is still visibly unfinished where the loop looks for unfinished work.
# What is given up is a second, later refusal at the close.
#
# AN UNRESOLVED LINK IS NOT A HANDOFF. An item naming a ticket no file can be found for
# is reported in `unresolved` and does NOT set `handoff`. The close it would otherwise
# block is already governed by `progress.sh`'s `unlinked` count, and a missing file is a
# different fault from a declared handoff -- conflating them would make this script the
# place a broken link silently becomes a refusal nobody can explain.
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts/"

ARG="${1:-}"
if [ -z "$ARG" ]; then
    echo '{"handoff": false, "tickets": [], "measurable_tickets": [], "unresolved": [], "reason": "missing_args"}' >&2
    exit 1
fi

. "${SCRIPT_DIR}/lib/resolve.sh"

MISSION_ROOT=$(missions_root_from_artifact "$ARG")
MISSION_FILE=$(mission_resolve "$MISSION_ROOT" "$ARG")
[ -f "$MISSION_FILE" ] || {
    echo '{"handoff": false, "tickets": [], "measurable_tickets": [], "unresolved": [], "reason": "no_such_mission"}' >&2
    exit 1
}

# The repository root, from the mission file: `.workaholic/missions/<area>/<slug>/mission.md`.
REPO_ROOT=$(cd -- "$(dirname -- "$MISSION_FILE")/../../../.." && pwd)
TICKETS_DIR="${REPO_ROOT}/.workaholic/tickets"

# Every basename an acceptance item names, one per line. The marker is the one
# `tick-acceptance.sh` writes and matches, read here with the same scoping: inside
# `## Acceptance`, over a checklist item and the indented lines that continue it.
LINKED=$(awk '
    BEGIN { in_acc = 0; n_open = 0 }
    {
        if ($0 ~ /^## /) { n_open = 0; in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/); next }
        if (!in_acc) next
        if ($0 ~ /^[ \t]*-[ \t]+\[( |x|X)\]/) { n++; text[n] = $0; n_open = 1; next }
        if (n_open && $0 ~ /^[ \t]+[^ \t]/) { text[n] = text[n] " " $0; next }
        n_open = 0
    }
    END {
        for (i = 1; i <= n; i++) {
            line = text[i]
            while (match(line, /\(#[^)]+\)/)) {
                marker = substr(line, RSTART + 2, RLENGTH - 3)
                print marker
                line = substr(line, RSTART + RLENGTH)
            }
        }
    }
' "$MISSION_FILE")

HANDOFF=false
FOUND=""
MEASURABLE=""
UNRESOLVED=""

append() {
    # $1 list, $2 item -> echoes the list with the item appended as a JSON string.
    if [ -z "$1" ]; then printf '"%s"' "$2"; else printf '%s, "%s"' "$1" "$2"; fi
}

for BASENAME in $LINKED; do
    [ -n "$BASENAME" ] || continue
    # todo/ first, then the archive: a ticket still queued is the same statement about
    # the plan as one already archived, and looking only in the archive would miss a
    # mission whose handoff ticket has not been driven yet.
    TICKET=""
    if [ -f "${TICKETS_DIR}/todo/${BASENAME}" ]; then
        TICKET="${TICKETS_DIR}/todo/${BASENAME}"
    else
        TICKET=$(find "${TICKETS_DIR}/archive" -type f -name "$BASENAME" 2>/dev/null | head -n 1 || true)
    fi

    if [ -z "$TICKET" ] || [ ! -f "$TICKET" ]; then
        UNRESOLVED=$(append "$UNRESOLVED" "$BASENAME")
        continue
    fi

    OUT=$(sh "${DRIVE_SCRIPTS}/verification-handoff.sh" tickets "$TICKET" 2>/dev/null || true)
    printf '%s' "$OUT" | grep -Eq '"handoff"[[:space:]]*:[[:space:]]*true' || continue

    # A declaration the run can re-test is answered where it is already run (§6), not here.
    # An unreadable reading has no `"measurable": true` and therefore still holds -- an
    # absence is never a clean probe, the same direction every other reader takes.
    if printf '%s' "$OUT" | grep -Eq '"measurable"[[:space:]]*:[[:space:]]*true'; then
        MEASURABLE=$(append "$MEASURABLE" "$BASENAME")
        continue
    fi

    HANDOFF=true
    FOUND=$(append "$FOUND" "$BASENAME")
done

printf '{"handoff": %s, "tickets": [%s], "measurable_tickets": [%s], "unresolved": [%s]}\n' \
    "$HANDOFF" "$FOUND" "$MEASURABLE" "$UNRESOLVED"
