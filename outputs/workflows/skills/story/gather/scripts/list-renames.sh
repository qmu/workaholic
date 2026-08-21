#!/bin/sh -eu
# THE ONE READER of the rename registry (renames.tsv, this script's sibling).
#
# Every consumer goes through here — layout-doctor.sh, migrate-renamed-areas.sh,
# rename-conversions.sh, the tests. Two hand-rolled TSV parsers would drift exactly
# as four hand-rolled frontmatter readers once did (mission/SKILL.md, *Automatic
# updates*), so the parse, the validation and the vocabulary live in one place.
#
# Usage: list-renames.sh [--rows] [--kind area|name] [table-path]
#   --rows  emit normalized TAB-separated rows instead of JSON, one per line
#           (kind<TAB>old<TAB>new<TAB>since<TAB>why) — for the POSIX callers that
#           would otherwise have to parse JSON in sh. Same parse either way.
#   --kind  keep only rows of that kind.
#   table-path defaults to $WORKAHOLIC_RENAMES_TABLE, else the sibling renames.tsv.
#
# WHY THE ENV VAR EXISTS, and why it is not the opt-out this repository refuses
# elsewhere: every consumer reaches the table THROUGH this script, so one variable
# points the whole chain -- doctor, migration, conversions -- at a fixture table, which
# is how the suite proves the behaviour without mutating the shipped one. It selects a
# DATA SOURCE; it disables no gate and skips no check (contrast the layout gate, which
# has no opt-out because an injectable one fails open exactly when it is not set).
#
# Output (default): {"table": "<path>", "readable": true|false, "renames": [ ... ]}
#   each rename: {"kind","old","new","since","why"}
#
# IT NEVER FAILS ON A BAD TABLE. An unreadable or missing file is `readable: false`
# with an empty list, and a malformed row is skipped, because the first consumer is a
# hook: layout-doctor.sh must degrade to its previous behaviour rather than flag an
# entire tree because a data file lost a tab. Exit is always 0 for the same reason.
#
# A row is well-formed when kind is `area` or `name` and old/new/since are all
# non-empty. `new` is never empty by design — a retirement is not a rename and has no
# destination (renames.tsv's header carries the reasoning).

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

ROWS=0
KIND=""
TABLE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --rows) ROWS=1 ;;
        --kind) shift; KIND="${1:-}" ;;
        --kind=*) KIND="${1#--kind=}" ;;
        *) TABLE="$1" ;;
    esac
    shift
done

[ -n "$TABLE" ] || TABLE="${WORKAHOLIC_RENAMES_TABLE:-${SCRIPT_DIR}/renames.tsv}"

esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

if [ ! -r "$TABLE" ]; then
    if [ "$ROWS" -eq 1 ]; then exit 0; fi
    printf '{"table": "%s", "readable": false, "renames": []}\n' "$(esc "$TABLE")"
    exit 0
fi

# One awk pass does the whole parse: strip comments and blanks, split on TAB, drop a
# malformed row, and apply the --kind filter. Emitting TSV here and letting the JSON
# branch re-read it keeps ONE parse rather than two that agree by coincidence.
PARSED=$(awk -F '\t' -v want="$KIND" '
    /^[ \t]*#/ { next }
    /^[ \t]*$/ { next }
    {
        kind = $1; old = $2; new = $3; since = $4; why = $5
        if (kind != "area" && kind != "name") next
        if (old == "" || new == "" || since == "") next
        if (want != "" && kind != want) next
        printf "%s\t%s\t%s\t%s\t%s\n", kind, old, new, since, why
    }
' "$TABLE")

if [ "$ROWS" -eq 1 ]; then
    [ -n "$PARSED" ] && printf '%s\n' "$PARSED"
    exit 0
fi

items=""
sep=""
if [ -n "$PARSED" ]; then
    while IFS='	' read -r kind old new since why; do
        [ -n "$kind" ] || continue
        items="${items}${sep}{\"kind\":\"$(esc "$kind")\",\"old\":\"$(esc "$old")\",\"new\":\"$(esc "$new")\",\"since\":\"$(esc "$since")\",\"why\":\"$(esc "$why")\"}"
        sep=","
    done <<EOF
$PARSED
EOF
fi

printf '{"table": "%s", "readable": true, "renames": [%s]}\n' "$(esc "$TABLE")" "$items"
