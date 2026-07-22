#!/bin/sh -eu
# List every strategy with its status and the missions that execute it. Strategies are
# enumerated across both areas (active/ and archive/). The `missions` rollup is COMPUTED,
# never stored: it is derived by scanning every mission's `strategy:` field through
# read-strategy-relation.sh and grouping by strategy slug. Nothing is stored on the
# strategy side, so an archived mission never leaves a dangling reference.
#
# Usage: list.sh
# Output: JSON array [{slug, title, status, path, missions: [...], active_missions: [...]}],
#         sorted by slug. Emits [] when there are no strategies. `missions` is every
#         mission (active + archived) executing the strategy; `active_missions` is the
#         subset under missions/active/ — the /mission planning session's gap signal is
#         an active strategy whose `active_missions` is empty (direction with nothing
#         currently advancing it). Both computed fresh, never stored.

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
# Each line is "<strategy-slug><TAB><mission-slug><TAB><area>". Computed fresh every run;
# the area column lets active_missions be derived without a second scan.
MAP=""
for area in active archive; do
    for md in .workaholic/missions/$area/*/mission.md; do
        [ -f "$md" ] || continue
        mslug=$(basename "$(dirname "$md")")
        for sslug in $(sh "${SCRIPT_DIR}/read-strategy-relation.sh" "$md"); do
            MAP="${MAP}${sslug}${TAB}${mslug}${TAB}${area}
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
    # Missions rolling up to this strategy, sorted, unique — all, then active-only.
    missions=$(printf '%s' "$MAP" | awk -F"$TAB" -v s="$slug" '$1 == s {print $2}' | LC_ALL=C sort -u)
    active_missions=$(printf '%s' "$MAP" | awk -F"$TAB" -v s="$slug" '$1 == s && $3 == "active" {print $2}' | LC_ALL=C sort -u)
    to_json_array() {
        _arr=""
        _first=1
        for _m in $1; do
            [ "$_first" -eq 1 ] || _arr="${_arr},"
            _first=0
            _arr="${_arr}\"$(json_escape "$_m")\""
        done
        printf '%s' "$_arr"
    }
    marr=$(to_json_array "$missions")
    aarr=$(to_json_array "$active_missions")
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"${slug}\",\"title\":\"${title}\",\"status\":\"${status}\",\"path\":\"${f}\",\"missions\":[${marr}],\"active_missions\":[${aarr}]}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
