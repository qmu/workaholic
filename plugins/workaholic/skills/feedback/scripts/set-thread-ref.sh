#!/bin/sh -eu
# Persist a Slack thread pointer onto a feedback record's frontmatter at the moment its
# thread root is posted, so a later event finds the thread deterministically instead of
# re-deriving it by search (workaholic:notify, "One thread per feedback item").
#
# WHY THIS IS THE ONE SANCTIONED EXCEPTION TO IMMUTABILITY (feedback/SKILL.md,
# Immutability): a feedback record's CONTENT never changes after it is written, but the
# thread it lands in cannot be known until AFTER the write -- the Slack root's ts exists
# only once a routine has already posted it. thread_ref is additive (it names no new
# fact about the record's content, only where its own life is being narrated) and
# write-once: filled exactly once, at first-post time, never edited afterward. A second
# write attempt -- even to the identical value -- is refused rather than silently
# accepted, because write-once IS the safety property: an overwrite is indistinguishable
# from a lookup silently repointing an item's history onto a different thread.
#
# Usage: set-thread-ref.sh <feedback-path> <channel-id> <ts>
# Output: JSON {written, path[, thread_ref][, reason][, existing]}
#   Refusals (exit 1): missing_args, not_found, already_set (existing carried in the
#   reply so a caller can tell a duplicate-with-same-value apart from a genuine conflict
#   -- both are refused, since a second write is never legitimate either way).

set -eu

FILE="${1:-}"
CHANNEL="${2:-}"
TS="${3:-}"
if [ -z "$FILE" ] || [ -z "$CHANNEL" ] || [ -z "$TS" ]; then
    echo '{"written": false, "reason": "missing_args"}' >&2
    exit 1
fi
[ -f "$FILE" ] || { printf '{"written": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

REF="${CHANNEL}:${TS}"

EXISTING=$(awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && /^---[ \t]*$/ { exit }
    in_fm && /^thread_ref:/ { sub(/^thread_ref:[ \t]*/, ""); print; exit }
' "$FILE")
if [ -n "$EXISTING" ]; then
    printf '{"written": false, "reason": "already_set", "path": "%s", "existing": "%s"}\n' "$FILE" "$EXISTING"
    exit 1
fi

# Write thread_ref in the frontmatter block only; insert the key before the closing ---
# (every feedback record has the field absent until this script runs once, so there is
# no in-place-update branch to mirror record-run-hours.sh's -- the "already set" refusal
# above is what stands in for it).
TMP="${FILE}.$$.tmp"
awk -v v="$REF" '
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm && /^---[ \t]*$/ { print "thread_ref: " v; in_fm = 0; print; next }
    { print }
' "$FILE" > "$TMP"
mv "$TMP" "$FILE"

git add "$FILE" 2>/dev/null || true
printf '{"written": true, "path": "%s", "thread_ref": "%s"}\n' "$FILE" "$REF"
