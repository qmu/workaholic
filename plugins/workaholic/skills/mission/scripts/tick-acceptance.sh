#!/bin/sh -eu
# Flip the ## Acceptance checklist item that references <artifact-filename> from
# "- [ ]" to "- [x]". The item is matched by its trailing "(#<artifact-filename>)"
# marker (the stable acceptance-to-artifact link defined by the mission schema).
# Idempotent: an already-checked item, or no matching item, is a no-op. Scoped to
# the ## Acceptance section, so a bullet elsewhere is never flipped. Progress stays
# derived — this only changes checklist state; progress.sh computes checked/total.
# The mission file is git-staged so the calling seam's commit carries the change.
#
# Usage: tick-acceptance.sh <mission-slug-or-file> <artifact-filename>
# Output: JSON {ticked, path[, reason]}

set -eu

ARG="${1:-}"
ARTIFACT="${2:-}"
if [ -z "$ARG" ] || [ -z "$ARTIFACT" ]; then
    echo '{"ticked": false, "reason": "missing_args"}' >&2
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"ticked": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

TMP="${FILE}.$$.tmp"

# Within ## Acceptance, flip an unchecked item whose (#<artifact>) marker matches.
# The unchecked-box pattern is written as "\[ \]" (no nested character class) so the
# source never contains a literal "[[" the POSIX lint would misread as a bash test.
CHANGED=$(awk -v artifact="$ARTIFACT" -v tmp="$TMP" '
    BEGIN { in_acc = 0; changed = 0; marker = "(#" artifact ")" }
    /^## / { in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/) }
    {
        if (in_acc && index($0, marker) > 0 && $0 ~ /^[ \t]*-[ \t]+\[ \]/) {
            sub(/\[ \]/, "[x]")
            changed = 1
        }
        print > tmp
    }
    END { print changed }
' "$FILE")

if [ "$CHANGED" = "1" ]; then
    mv "$TMP" "$FILE"
    git add "$FILE" 2>/dev/null || true
    printf '{"ticked": true, "path": "%s"}\n' "$FILE"
else
    rm -f "$TMP"
    printf '{"ticked": false, "reason": "no_unchecked_match", "path": "%s"}\n' "$FILE"
fi
