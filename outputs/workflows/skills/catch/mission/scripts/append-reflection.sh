#!/bin/sh -eu
# Append one dated reflection entry to a mission's ## Reflection section, idempotently
# per run-id. A /monitor run writes, per driven mission, a 反省 (reflection): what
# stopped (or would have stopped) question-free autonomy this run, and what the next
# planning should front-load. The MODEL composes the three-bullet prose (on stdin);
# THIS SCRIPT owns placement and idempotency, so the artifact stays machine-readable
# even though the judgment is not.
#
# The section is created (after ## Changelog, at EOF) if absent. Append-only: existing
# entries are never altered. Idempotent per run-id — a run already reflected adds
# nothing, so an interrupted-then-resumed invocation is safe.
#
# The ## Reflection section is explicitly OUTSIDE progress.sh / next-acceptance.sh scope
# (any "## " heading ends the ## Acceptance section), so a checklist-looking line here
# never counts toward mission progress.
#
# Usage: append-reflection.sh <mission-slug-or-file> <run-id> [date]   (body on stdin)
#   Body is the three fixed bullets:
#     - blocked: <what stopped autonomy, or none>
#     - leaked questions: <judgment calls that surfaced mid-run, or none>
#     - front-load next: <what the next planning should pre-answer>
# Output: JSON {appended, run_id, path[, reason]}

set -eu

ARG="${1:-}"
RUNID="${2:-}"
DATE="${3:-$(date +%Y-%m-%d)}"
if [ -z "$ARG" ] || [ -z "$RUNID" ]; then
    echo '{"appended": false, "reason": "missing_args"}' >&2
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"appended": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

# Idempotent per run-id: an entry headed with this run-id already present adds nothing.
if grep -q "run ${RUNID}\$" "$FILE" 2>/dev/null; then
    printf '{"appended": false, "reason": "duplicate", "run_id": "%s", "path": "%s"}\n' "$RUNID" "$FILE"
    exit 0
fi

BODY=$(cat)

ENTRY="### ${DATE} run ${RUNID}
${BODY}"

TMP="${FILE}.$$.tmp"
if grep -q '^##[ \t]*Reflection[ \t]*$' "$FILE"; then
    # Append the entry at the end of the existing ## Reflection section (before the
    # next "## " heading, or EOF), separated by a blank line from the prior entry.
    awk -v entry="$ENTRY" '
        function flush() { if (inref && !done) { print ""; print entry; done = 1 } }
        /^## / {
            if ($0 ~ /^##[ \t]*Reflection[ \t]*$/) { print; inref = 1; next }
            flush(); inref = 0
        }
        { print }
        END { flush() }
    ' "$FILE" > "$TMP"
else
    # Create the section at EOF (## Changelog is the last schema section, so this
    # lands after it). One blank line before the heading.
    cp "$FILE" "$TMP"
    printf '\n## Reflection\n\n%s\n' "$ENTRY" >> "$TMP"
fi
mv "$TMP" "$FILE"

git add "$FILE" 2>/dev/null || true
printf '{"appended": true, "run_id": "%s", "path": "%s"}\n' "$RUNID" "$FILE"
