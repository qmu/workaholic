#!/bin/sh -eu
# Compute a mission's progress toward achievement as checked / total over its
# ## Acceptance checklist. Progress is always derived from the checklist state,
# never read from a stored number.
#
# `unlinked` rides alongside: how many UNCHECKED items carry no (#<filename>) link and so
# cannot be ticked by any artifact. A board reporting 0/8 says nothing about whether the
# work stalled or the board was never wired up; 0/8 with unlinked 8 says which. This is
# what keeps a stranded board from hiding — see reference/schema.md, "The link contract".
#
# Usage: progress.sh <mission-file-or-slug>
#   - a path to a mission.md, or a bare slug (resolved across active/ and archive/)
# Output: JSON {checked, total, unlinked}

set -eu

ARG="${1:-}"
[ -n "$ARG" ] || { echo '{"error": "no_mission"}' >&2; exit 1; }

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"error": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

# Count checklist items only within the "## Acceptance" section (a checklist item
# is a line whose first non-blank content is "- [ ]", "- [x]", or "- [X]"). Any
# "## " heading ends the section, so items under other headings are never counted.
# The bracket sub-patterns use alternation ("\[( |x|X)\]") rather than a nested
# character class so the source never contains a literal "[[" that the POSIX lint
# would misread as a bash test.
#
# The link is ITEM-scoped, so a wrapped item's marker may sit on a continuation line:
# an item stays "open" across its indented continuations while its link is looked for,
# exactly as tick-acceptance.sh matches it.
COUNTS=$(awk '
    /^## / { in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/) ; open = 0 ; next }
    !in_acc { next }
    /^[ \t]*-[ \t]+\[( |x|X)\]/ {
        total++
        open = 1
        item_checked = ($0 ~ /^[ \t]*-[ \t]+\[(x|X)\]/)
        if (item_checked) checked++
        pending = (!item_checked && $0 !~ /\(#[^)]+\)/)
        if (pending) unlinked++
        next
    }
    open && /^[ \t]+[^ \t]/ {
        if (pending && $0 ~ /\(#[^)]+\)/) { unlinked--; pending = 0 }
        next
    }
    { open = 0; pending = 0 }
    END { printf "%d %d %d", checked + 0, total + 0, unlinked + 0 }
' "$FILE")

CHECKED=$(printf '%s' "$COUNTS" | cut -d' ' -f1)
TOTAL=$(printf '%s' "$COUNTS" | cut -d' ' -f2)
UNLINKED=$(printf '%s' "$COUNTS" | cut -d' ' -f3)
printf '{"checked": %d, "total": %d, "unlinked": %d}\n' "$CHECKED" "$TOTAL" "$UNLINKED"
