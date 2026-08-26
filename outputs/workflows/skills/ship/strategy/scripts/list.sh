#!/bin/sh -eu
# List every strategy with the three parts a reader needs to act: status, target
# date (the Schedule's bound) and assignees (the Assignee). Pure read — it never
# writes, and it degrades to an empty list in a tree with no strategies/ area.
#
# Usage: list.sh [--status active|achieved|abandoned] [workaholic-root]
# Output: JSON {count, strategies: [{slug, title, status, target_date, assignees}]}

set -eu

FILTER=""
if [ "${1:-}" = "--status" ]; then
    FILTER="${2:-}"
    shift 2
fi
ROOT="${1:-.workaholic}"
DIR="${ROOT}/strategies"

fm() {
    awk -v key="$2" '
        NR==1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        $0 ~ "^" key ":" { sub("^" key ":[ \t]*", ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$1" 2>/dev/null || true
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

COUNT=0
OUT=""
if [ -d "$DIR" ]; then
    for f in "$DIR"/*.md; do
        [ -f "$f" ] || continue
        base=$(basename "$f")
        case "$base" in index.md|README.md|README) continue ;; esac
        status=$(fm "$f" status)
        [ -n "$FILTER" ] && [ "$status" != "$FILTER" ] && continue
        slug=$(fm "$f" slug)
        [ -n "$slug" ] || slug="${base%.md}"
        title=$(fm "$f" title)
        target=$(fm "$f" target_date)
        assignees=$(fm "$f" assignees | sed -e 's/^\[//' -e 's/\]$//')
        [ -n "$OUT" ] && OUT="${OUT},"
        OUT="${OUT}{\"slug\": \"$(json_escape "$slug")\", \"title\": \"$(json_escape "$title")\", \"status\": \"$(json_escape "$status")\", \"target_date\": \"$(json_escape "$target")\", \"assignees\": \"$(json_escape "$assignees")\"}"
        COUNT=$((COUNT + 1))
    done
fi

printf '{"count": %s, "strategies": [%s]}\n' "$COUNT" "$OUT"
