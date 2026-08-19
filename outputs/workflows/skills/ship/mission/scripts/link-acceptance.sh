#!/bin/sh -eu
# Establish the acceptance-to-artifact link: stamp a "(#<artifact-filename>)" marker
# onto one ## Acceptance item, so the ticker can later flip exactly that item.
#
# THIS EXISTS BECAUSE AN ACCEPTANCE ITEM IS WRITTEN BEFORE ITS TICKET. A /specificate
# proposal states its criteria before any ticket file exists, so a markerless item is a
# valid intermediate state -- not a defect. The moment the ticket set IS emitted every
# filename exists at once, and that is the seam that calls this. Measured 2026-08-03:
# every one of the 37 acceptance items across the six proposal-scaffolded missions was
# unlinked and therefore untickable, against 19 of 19 linked on the interrogation-
# authored ones. See mission/reference/schema.md, "The link contract".
#
# THE PAIRING IS THE CALLER'S, NEVER INFERRED. The caller names the item explicitly and
# this script only writes it. Guessing which artifact satisfies which criterion -- by
# title similarity or by position -- would check a box the work may not have satisfied,
# and a false [x] is worse than a stuck [ ].
#
# Item text is preserved byte-for-byte; only the trailing marker is appended. The link
# is ITEM-scoped, so the marker lands at the end of the item's last line and a wrapped
# criterion links exactly like a one-line one.
#
# Idempotent: re-linking the same item to the same artifact is a no-op. Re-pointing it
# at a DIFFERENT artifact is refused (linked_to_other) -- a re-point is a plan change,
# which belongs in a replan where it is recorded, not in a mutator.
#
# Usage: link-acceptance.sh <mission-slug-or-file> <selector> <artifact-filename>
#   selector: the item's 1-based position in ## Acceptance ("3"), or a substring that
#             matches exactly one item's text
# Output: JSON {linked, path, index, artifact[, reason]}
#   Refusals print JSON on stdout and exit 1 (no_match, ambiguous, linked_to_other,
#   path_not_filename); already_linked is a no-op on stdout with exit 0; argument/file
#   errors go to stderr with exit 1, as in the sibling mutators.

set -eu

ARG="${1:-}"
SELECTOR="${2:-}"
ARTIFACT="${3:-}"
if [ -z "$ARG" ] || [ -z "$SELECTOR" ] || [ -z "$ARTIFACT" ]; then
    echo '{"linked": false, "reason": "missing_args"}' >&2
    exit 1
fi

# The marker is documented as "(#<artifact-filename>)" -- a bare filename, never a path.
# `tick-acceptance.sh` is handed a basename by every known caller (`archive.sh`'s
# `basename "$TICKET"`), so a path-shaped marker written here can never match at tick
# time and the acceptance item is silently stranded until every one of its member
# tickets has already landed (measured 2026-08-10, ticket `20260810203351`: a mission
# stuck at 0/3 after all three tickets archived, because its ARTIFACT arguments were
# full `.workaholic/tickets/todo/<file>.md` paths). Refuse at the write instead of
# discovering the mismatch at read time, once it is too late to relink cheaply.
case "$ARTIFACT" in
    */*)
        printf '{"linked": false, "reason": "path_not_filename", "artifact": "%s"}\n' "$ARTIFACT"
        exit 1
        ;;
esac

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"linked": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

TMP="${FILE}.$$.tmp"

# One pass: resolve the selection over the ## Acceptance items, write the (possibly
# modified) file to TMP, and report "<status> <index>" on stdout for the shell to act on.
# An item is its checklist line plus any indented continuation lines; a blank line, a new
# checklist line, an unindented line, or a "## " heading ends it. The unchecked/checked
# boxes are written with alternation ("\[( |x|X)\]") rather than a nested character class
# so the source never contains a literal "[[" the POSIX lint would misread as a bash test.
RESULT=$(awk -v selector="$SELECTOR" -v artifact="$ARTIFACT" -v tmp="$TMP" '
    BEGIN {
        in_acc = 0; n = 0; n_open = 0; matches = 0; target = 0
        selector_is_index = (selector ~ /^[0-9]+$/)
        marker = "(#" artifact ")"
    }
    {
        line[NR] = $0
        if ($0 ~ /^## /) { n_open = 0; in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/); next }
        if (!in_acc) next
        if ($0 ~ /^[ \t]*-[ \t]+\[( |x|X)\]/) { n++; text[n] = $0; last[n] = NR; n_open = 1; next }
        if (n_open && $0 ~ /^[ \t]+[^ \t]/) { text[n] = text[n] " " $0; last[n] = NR; next }
        n_open = 0
    }
    END {
        for (i = 1; i <= n; i++) {
            if (selector_is_index) { if (i == selector + 0) { matches++; target = i } }
            else if (index(text[i], selector) > 0) { matches++; target = i }
        }
        status = "ok"
        if (matches == 0) status = "no_match"
        else if (matches > 1) status = "ambiguous"
        else if (index(text[target], marker) > 0) status = "already_linked"
        else if (text[target] ~ /\(#[^)]+\)/) status = "linked_to_other"
        for (i = 1; i <= NR; i++) {
            out = line[i]
            if (status == "ok" && i == last[target]) out = out " " marker
            print out > tmp
        }
        printf "%s %d", status, (matches == 1 ? target : 0)
    }
' "$FILE")

STATUS=${RESULT% *}
INDEX=${RESULT#* }

if [ "$STATUS" = "ok" ]; then
    mv "$TMP" "$FILE"
    git add "$FILE" 2>/dev/null || true
    printf '{"linked": true, "path": "%s", "index": %d, "artifact": "%s"}\n' "$FILE" "$INDEX" "$ARTIFACT"
    exit 0
fi

rm -f "$TMP"
printf '{"linked": false, "reason": "%s", "path": "%s", "index": %d, "artifact": "%s"}\n' \
    "$STATUS" "$FILE" "$INDEX" "$ARTIFACT"
[ "$STATUS" = "already_linked" ] || exit 1
