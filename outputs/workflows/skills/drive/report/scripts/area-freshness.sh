#!/bin/sh -eu
# area-freshness.sh -- the upkeep seam for the two HAND-MAINTAINED areas that
# survived the 2026-08-13 layout reshape: deployments/ and terms/.
#
# Why this exists: guides/, policies/ and specs/ were retired that day because an
# area with no writer in the loop goes stale and then lies -- 17 of their 20 files
# still described an architecture retired five months earlier and nothing ever
# said so. deployments/ and terms/ survive, and the price of surviving is that
# staleness becomes VISIBLE. This is that visibility.
#
# It REPORTS, it never writes. That is the recorded answer to "which seam owns
# each area's upkeep" (ticket 20260813112618): /ship is the only live reader of a
# deployment record, but a record describes a procedure a HUMAN authored, so a
# machine that rewrote it from a run would record what happened rather than what
# should happen. Keeping both areas human-written and machine-CHECKED is the
# honest arrangement, and this script is what makes it more than aspirational.
#
# Two facts per record, both mechanical:
#   1. `retired_terms` -- the record names something this repository no longer
#      has: a de-listed .workaholic/ area (guides, policies, specs), or a retired
#      plugin namespace (drivin, trippin, standards, core, work). A record naming
#      a thing that does not exist is not "possibly stale", it is wrong.
#   2. `stale_days` -- calendar days since the record's last commit. Reported for
#      every record; a caller decides what is too old, because the right interval
#      differs per project and a threshold baked in here would be a guess.
#
# Facts, not verdicts -- the same contract doc-drift.sh keeps, for the same
# reason (operation policy: never false-block an otherwise-shippable branch).
#
# Usage: area-freshness.sh [workaholic-root]
# Output: JSON {areas: {<area>: {present, records: [{path, last_commit, stale_days,
#         retired_terms: [...]}]}}, flagged, total}
# Always exits 0.

set -eu

ROOT="${1:-.workaholic}"

# The vocabulary of "no longer exists here". Kept literal and small on purpose:
# this is a check for naming a RETIRED STRUCTURE, never a spell-checker for prose.
RETIRED='guides policies specs drivin trippin'

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

NOW=$(date +%s 2>/dev/null || echo 0)

TOTAL=0
FLAGGED=0
AREAS=""

for area in deployments terms; do
    dir="${ROOT}/${area}"
    [ -n "$AREAS" ] && AREAS="${AREAS}, "
    if [ ! -d "$dir" ]; then
        AREAS="${AREAS}\"${area}\": {\"present\": false, \"records\": []}"
        continue
    fi

    RECORDS=""
    for f in "$dir"/*.md; do
        [ -f "$f" ] || continue
        base=$(basename "$f")
        case "$base" in index.md|README.md|README) continue ;; esac
        TOTAL=$((TOTAL + 1))

        last=$(git log -1 --format=%cI -- "$f" 2>/dev/null || true)
        days=""
        if [ -n "$last" ] && [ "$NOW" -ne 0 ]; then
            lastepoch=$(git log -1 --format=%ct -- "$f" 2>/dev/null || echo "")
            if [ -n "$lastepoch" ]; then
                days=$(( (NOW - lastepoch) / 86400 ))
            fi
        fi

        # Which retired names this record still uses. Word-bounded so `policies`
        # in "the pillar policy skills" does not match and `specs` does not fire
        # on "specification".
        found=""
        for term in $RETIRED; do
            if grep -qEi "(^|[^a-z0-9_-])${term}([^a-z0-9_-]|$)" "$f" 2>/dev/null; then
                [ -n "$found" ] && found="${found}, "
                found="${found}\"${term}\""
            fi
        done
        [ -n "$found" ] && FLAGGED=$((FLAGGED + 1))

        [ -n "$RECORDS" ] && RECORDS="${RECORDS}, "
        RECORDS="${RECORDS}{\"path\": \"$(json_escape "$f")\", \"last_commit\": \"$(json_escape "$last")\", \"stale_days\": ${days:-null}, \"retired_terms\": [${found}]}"
    done
    AREAS="${AREAS}\"${area}\": {\"present\": true, \"records\": [${RECORDS}]}"
done

printf '{"areas": {%s}, "flagged": %s, "total": %s}\n' "$AREAS" "$FLAGGED" "$TOTAL"
