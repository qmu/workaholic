#!/bin/sh -eu
# List every strategy with its status and the missions that execute it. Strategies are
# enumerated across both areas (active/ and archive/). The `missions` rollup is COMPUTED,
# never stored: it is derived by scanning every mission's `strategy:` field through
# read-strategy-relation.sh and grouping by strategy slug. Nothing is stored on the
# strategy side, so an archived mission never leaves a dangling reference.
#
# Usage: list.sh
# Output: JSON array [{slug, title, status, path, missions: [<mission-slug>, ...]}],
#         sorted by slug. Emits [] when there are no strategies.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic/strategies"
TAB=$(printf '\t')

if [ ! -d "$ROOT" ]; then
    echo '[]'
    exit 0
fi

# JSON-escape a value (backslash and double-quote only; titles are plain text).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read a frontmatter field's value ("" when absent).
fm_field() {
    grep -m1 "^$2:" "$1" 2>/dev/null | sed -e "s/^$2:[ \t]*//" || true
}

# Build a strategy-slug -> mission-slug map by scanning every mission's strategy relation.
# Each line is "<strategy-slug><TAB><mission-slug>". Computed fresh every run.
MAP=""
for area in active archive; do
    for md in .workaholic/missions/$area/*/mission.md; do
        [ -f "$md" ] || continue
        mslug=$(basename "$(dirname "$md")")
        for sslug in $(sh "${SCRIPT_DIR}/read-strategy-relation.sh" "$md"); do
            MAP="${MAP}${sslug}${TAB}${mslug}
"
        done
    done
done

# Strategy dirs across both areas, sorted globally by slug (the dir basename).
DIRS=$(
    find "$ROOT/active" "$ROOT/archive" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
        | awk -F/ '{print $NF "\t" $0}' | LC_ALL=C sort | cut -f2-
)

OUT="["
FIRST=1
for d in $DIRS; do
    f="$d/strategy.md"
    [ -f "$f" ] || continue
    slug=$(basename "$d")
    title=$(json_escape "$(fm_field "$f" title)")
    status=$(json_escape "$(fm_field "$f" status)")
    # Missions rolling up to this strategy, sorted, unique.
    missions=$(printf '%s' "$MAP" | awk -F"$TAB" -v s="$slug" '$1 == s {print $2}' | LC_ALL=C sort -u)
    marr=""
    mfirst=1
    for m in $missions; do
        [ "$mfirst" -eq 1 ] || marr="${marr},"
        mfirst=0
        marr="${marr}\"$(json_escape "$m")\""
    done
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"${slug}\",\"title\":\"${title}\",\"status\":\"${status}\",\"path\":\"${f}\",\"missions\":[${marr}]}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
