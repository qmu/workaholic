#!/bin/sh -eu
# The dedup set (docs/loop-engineering-workflow.md C4): the union of `feedback:`
# refs across EVERY mission - both areas, drafts included - one filename per
# line. Feedback already referenced by any mission never spawns a second
# proposal; combined with the cursor this makes the batch idempotent.
#
# Usage: list-proposed-refs.sh
# Output: zero or more feedback record filenames, one per line, de-duplicated.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic/missions"

[ -d "$ROOT" ] || exit 0

for md in "$ROOT"/active/*/mission.md "$ROOT"/archive/*/mission.md "$ROOT"/*/mission.md; do
    [ -f "$md" ] || continue
    sh "${SCRIPT_DIR}/read-feedback-relation.sh" "$md" 2>/dev/null || true
done | sort -u
