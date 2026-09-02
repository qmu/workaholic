#!/bin/sh -eu
# List every strategy with the three parts a reader needs to act: status, target
# date (the Schedule's bound) and assignees (the Assignee). Pure read — it never
# writes, and it degrades to an empty list in a tree with no strategies/ area.
#
# THE STAGE COMES FROM `read.sh`, NEVER FROM A SECOND PARSE (2026-08-29, mission
# `make-a-direction-s-lifecycle-a-declared-stage`). Every other field here is read by this
# script's own `fm`, and the stage deliberately is not: an ABSENT `stage:` means 進行中, and
# that default has exactly one derivation, in `read.sh`. Parsing the field here would put the
# default in two places, which is how one artifact starts answering two ways.
#
# Usage: list.sh [--status active|achieved|abandoned] [workaholic-root]
# Output: JSON {count, strategies: [{slug, title, status, stage, stage_declared, target_date, created_at, assignees}]}

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
        created=$(fm "$f" created_at)
        row=$(sh "$(dirname "$0")/read.sh" "$slug" "$ROOT" 2>/dev/null || true)
        stage=$(printf '%s' "$row" | sed -n 's/.*"stage": "\([^"]*\)".*/\1/p')
        [ -n "$stage" ] || stage="進行中"
        declared=$(printf '%s' "$row" | sed -n 's/.*"stage_declared": \(true\|false\).*/\1/p')
        [ -n "$declared" ] || declared=false
        assignees=$(fm "$f" assignees | sed -e 's/^\[//' -e 's/\]$//')
        [ -n "$OUT" ] && OUT="${OUT},"
        OUT="${OUT}{\"slug\": \"$(json_escape "$slug")\", \"title\": \"$(json_escape "$title")\", \"status\": \"$(json_escape "$status")\", \"stage\": \"$(json_escape "$stage")\", \"stage_declared\": ${declared}, \"target_date\": \"$(json_escape "$target")\", \"created_at\": \"$(json_escape "$created")\", \"assignees\": \"$(json_escape "$assignees")\"}"
        COUNT=$((COUNT + 1))
    done
fi

printf '{"count": %s, "strategies": [%s]}\n' "$COUNT" "$OUT"
