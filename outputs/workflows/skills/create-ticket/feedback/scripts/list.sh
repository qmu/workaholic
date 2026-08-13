#!/bin/sh -eu
# List the feedback stream, newest first. Pure read: enumerates
# .workaholic/feedbacks/<ts>-<slug>.md (index.md excluded), reads each file's
# frontmatter, and emits one JSON object per record. Newest-first is the reverse
# of the filename sort — the timestamp prefix makes filenames chronological by
# construction (feedback/scripts/create.sh).
#
# Usage: list.sh
# Output: JSON array [{path, title, kind, source, subject, created_at, author, supersedes}],
#         `subject` is "" on a record predating the axis (2026-08-13) — the stream is
#         immutable, so history is read as it was written, never backfilled.
#         [] when the area does not exist or is empty.

set -eu

ROOT=".workaholic/feedbacks"

if [ ! -d "$ROOT" ]; then
    echo '[]'
    exit 0
fi

# JSON-escape a value (backslash and double-quote only; titles are plain text).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read a frontmatter field's value ("" when absent), from the frontmatter block only.
fm_field() {
    awk -v key="$2" '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        substr($0, 1, length(key) + 1) == key ":" {
            val = substr($0, length(key) + 2)
            gsub(/^[ \t]+|[ \t]+$/, "", val)
            print val
            exit
        }' "$1"
}

FILES=$(find "$ROOT" -maxdepth 1 -name '*.md' -type f ! -name 'index.md' 2>/dev/null | LC_ALL=C sort -r)

OUT="["
FIRST=1
for f in $FILES; do
    title=$(json_escape "$(fm_field "$f" title)")
    kind=$(json_escape "$(fm_field "$f" kind)")
    source=$(json_escape "$(fm_field "$f" source)")
    subject=$(json_escape "$(fm_field "$f" subject)")
    created_at=$(json_escape "$(fm_field "$f" created_at)")
    author=$(json_escape "$(fm_field "$f" author)")
    supersedes=$(json_escape "$(fm_field "$f" supersedes)")
    entry=$(printf '{"path": "%s", "title": "%s", "kind": "%s", "source": "%s", "subject": "%s", "created_at": "%s", "author": "%s", "supersedes": "%s"}' \
        "$f" "$title" "$kind" "$source" "$subject" "$created_at" "$author" "$supersedes")
    if [ "$FIRST" -eq 1 ]; then
        OUT="${OUT}${entry}"
        FIRST=0
    else
        OUT="${OUT}, ${entry}"
    fi
done
OUT="${OUT}]"

printf '%s\n' "$OUT"
