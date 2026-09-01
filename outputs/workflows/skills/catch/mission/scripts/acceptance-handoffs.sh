#!/bin/sh -eu
# Which of a mission's acceptance items are answered by a ticket that declared a
# verification handoff.
#
# Usage: acceptance-handoffs.sh <mission-slug-or-file>
# Output: JSON {"handoff": true|false, "tickets": ["<basename>", ...], "unresolved": [...]}
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
# AN UNRESOLVED LINK IS NOT A HANDOFF. An item naming a ticket no file can be found for
# is reported in `unresolved` and does NOT set `handoff`. The close it would otherwise
# block is already governed by `progress.sh`'s `unlinked` count, and a missing file is a
# different fault from a declared handoff -- conflating them would make this script the
# place a broken link silently becomes a refusal nobody can explain.
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts/"

ARG="${1:-}"
if [ -z "$ARG" ]; then
    echo '{"handoff": false, "tickets": [], "unresolved": [], "reason": "missing_args"}' >&2
    exit 1
fi

. "${SCRIPT_DIR}/lib/resolve.sh"

MISSION_ROOT=$(missions_root_from_artifact "$ARG")
MISSION_FILE=$(mission_resolve "$MISSION_ROOT" "$ARG")
[ -f "$MISSION_FILE" ] || {
    echo '{"handoff": false, "tickets": [], "unresolved": [], "reason": "no_such_mission"}' >&2
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
    if printf '%s' "$OUT" | grep -Eq '"handoff"[[:space:]]*:[[:space:]]*true'; then
        HANDOFF=true
        FOUND=$(append "$FOUND" "$BASENAME")
    fi
done

printf '{"handoff": %s, "tickets": [%s], "unresolved": [%s]}\n' "$HANDOFF" "$FOUND" "$UNRESOLVED"
