#!/bin/sh -eu
# List recent reflection entries across active and archived missions, newest first,
# bounded. The next /mission Creation Interrogation reads these back so recurring
# `front-load next:` items become pre-answered questions — the feedback loop of the
# overnight model (`workaholic:development` / `overnight-ai`).
#
# Read-only. Parses the three fixed bullets of each ## Reflection entry.
#
# Usage: list-reflections.sh [limit]   (limit defaults to 20)
# Output: JSON array [{slug, date, run_id, blocked, leaked, front_load}], newest first.

set -eu

LIMIT="${1:-20}"
case "$LIMIT" in ''|*[!0-9]*) LIMIT=20 ;; esac

TAB=$(printf '\t')

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

REC=""
for area in active archive; do
    for f in .workaholic/missions/$area/*/mission.md; do
        [ -f "$f" ] || continue
        slug=$(basename "$(dirname "$f")")
        entries=$(awk -v slug="$slug" -v TAB="$TAB" '
            function flush() { if (have) printf "%s%s%s%s%s%s%s%s%s%s%s\n", slug, TAB, d, TAB, rid, TAB, b, TAB, l, TAB, fl }
            /^## / {
                if ($0 ~ /^##[ \t]*Reflection[ \t]*$/) { inref = 1; next }
                flush(); have = 0; inref = 0; next
            }
            !inref { next }
            /^### / {
                flush()
                have = 1; d = $2; rid = ""; b = ""; l = ""; fl = ""
                seenb = 0; seenl = 0; seenf = 0
                for (i = 1; i <= NF; i++) if ($i == "run") rid = $(i + 1)
                next
            }
            have && /blocked:/ && !seenb          { s = $0; sub(/^[-*[:space:]]*blocked:[[:space:]]*/, "", s); b = s; seenb = 1; next }
            have && /leaked questions:/ && !seenl  { s = $0; sub(/^[-*[:space:]]*leaked questions:[[:space:]]*/, "", s); l = s; seenl = 1; next }
            have && /front-load next:/ && !seenf   { s = $0; sub(/^[-*[:space:]]*front-load next:[[:space:]]*/, "", s); fl = s; seenf = 1; next }
            END { flush() }
        ' "$f")
        [ -n "$entries" ] && REC="${REC}${entries}
"
    done
done

# Newest first: sort by date (k2) then run_id (k3) descending; bound to LIMIT.
SORTED=$(printf '%s' "$REC" | grep -v '^[[:space:]]*$' | LC_ALL=C sort -t"$TAB" -k2,2r -k3,3r | head -n "$LIMIT")

OUT="["
FIRST=1
while IFS="$TAB" read -r slug d rid b l fl; do
    [ -n "$slug" ] || continue
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"$(json_escape "$slug")\",\"date\":\"$(json_escape "$d")\",\"run_id\":\"$(json_escape "$rid")\",\"blocked\":\"$(json_escape "$b")\",\"leaked\":\"$(json_escape "$l")\",\"front_load\":\"$(json_escape "$fl")\"}"
done <<EOF
$SORTED
EOF
OUT="${OUT}]"
printf '%s\n' "$OUT"
