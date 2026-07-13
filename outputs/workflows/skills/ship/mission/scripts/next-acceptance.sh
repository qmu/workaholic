#!/bin/sh -eu
# Emit the display text of a mission's FIRST unchecked "## Acceptance" item -- the
# next criterion to satisfy on the road to achievement. Scoped to the ## Acceptance
# section with the same convention as progress.sh (a checklist item is a line whose
# first non-blank content is "- [ ]"/"- [x]"/"- [X]"; any "## " heading ends the
# section). The trailing "(#<filename>)" marker is stripped so the text reads as a
# plain next-step line for the mission lens. Prints nothing when every item is
# checked or the section is empty.
#
# Usage: next-acceptance.sh <mission-file-or-slug>
# Output: the next unchecked item's text on stdout (empty when none)

set -eu

ARG="${1:-}"
[ -n "$ARG" ] || { echo '{"error": "no_mission"}' >&2; exit 1; }

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
missions_migrate_layout
FILE=$(mission_resolve "$ARG")
[ -f "$FILE" ] || { printf '{"error": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

# The bracket sub-pattern uses alternation ("\[ \]") rather than a nested character
# class so the source never contains a literal "[[" that the POSIX lint would
# misread as a bash test (same guard progress.sh documents).
awk '
    /^## / { in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/) ; next }
    in_acc && /^[ \t]*-[ \t]+\[ \]/ {
        line = $0
        sub(/^[ \t]*-[ \t]+\[ \][ \t]*/, "", line)   # drop the "- [ ] " prefix
        sub(/[ \t]*\(#[^)]*\)[ \t]*$/, "", line)      # drop the trailing (#file) marker
        print line
        exit
    }
' "$FILE"
