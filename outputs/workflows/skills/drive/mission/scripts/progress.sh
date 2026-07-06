#!/bin/sh -eu
# Compute a mission's progress toward achievement as checked / total over its
# ## Acceptance checklist. Progress is always derived from the checklist state,
# never read from a stored number.
#
# Usage: progress.sh <mission-file-or-slug>
#   - a path to a mission.md, or a bare slug (resolved to .workaholic/missions/<slug>/mission.md)
# Output: JSON {checked, total}

set -eu

ARG="${1:-}"
[ -n "$ARG" ] || { echo '{"error": "no_mission"}' >&2; exit 1; }

if [ -f "$ARG" ]; then
    FILE="$ARG"
else
    FILE=".workaholic/missions/${ARG}/mission.md"
fi
[ -f "$FILE" ] || { printf '{"error": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

# Count checklist items only within the "## Acceptance" section (a checklist item
# is a line whose first non-blank content is "- [ ]", "- [x]", or "- [X]"). Any
# "## " heading ends the section, so items under other headings are never counted.
# The bracket sub-patterns use alternation ("\[( |x|X)\]") rather than a nested
# character class so the source never contains a literal "[[" that the POSIX lint
# would misread as a bash test.
COUNTS=$(awk '
    /^## / { in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/) ; next }
    in_acc && /^[ \t]*-[ \t]+\[( |x|X)\]/ {
        total++
        if ($0 ~ /^[ \t]*-[ \t]+\[(x|X)\]/) checked++
    }
    END { printf "%d %d", checked + 0, total + 0 }
' "$FILE")

CHECKED=${COUNTS% *}
TOTAL=${COUNTS#* }
printf '{"checked": %d, "total": %d}\n' "$CHECKED" "$TOTAL"
