#!/bin/sh -eu
# Enumerate mission and ticket artifacts once for a snapshot. Relations continue
# to come from the established reader; this producer only aggregates its answers.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ROOT=${1:-.workaholic}
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
: >"$tmp/tickets.ndjson"; : >"$tmp/missions.ndjson"

find "$ROOT/tickets/todo" "$ROOT/tickets/archive" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r file; do
    case "$file" in "$ROOT"/tickets/todo/*) area=todo;; *) area=archive;; esac
    relations=$(sh "$SCRIPT_DIR/read-relation.sh" "$file" 2>/dev/null | jq -Rsc 'split("\n")|map(select(length>0))')
    jq -cn --arg path "$file" --arg area "$area" --argjson relations "$relations" '{path:$path,area:$area,relations:$relations}'
done >"$tmp/tickets.ndjson"

find "$ROOT/missions/active" -mindepth 2 -maxdepth 2 -type f -name mission.md 2>/dev/null | LC_ALL=C sort | while IFS= read -r file; do
    slug=$(basename "$(dirname "$file")")
    counts=$(awk '
      /^## / {in_acc=($0 ~ /^##[ \t]+Acceptance[ \t]*$/); open=0; next}
      !in_acc {next}
      /^[ \t]*-[ \t]+\[( |x|X)\]/ {
        total++; open=1; checked_item=($0 ~ /^[ \t]*-[ \t]+\[(x|X)\]/); if (checked_item) checked++;
        pending=(!checked_item && $0 !~ /\(#[^)]+\)/); if (pending) unlinked++;
        if (!checked_item && next_text=="") {next_text=$0; sub(/^[ \t]*-[ \t]+\[ \][ \t]*/,"",next_text); sub(/[ \t]*\(#[^)]*\)[ \t]*$/, "", next_text)}
        next
      }
      open && /^[ \t]+[^ \t]/ {if (pending && $0 ~ /\(#[^)]+\)/) {unlinked--; pending=0}; next}
      {open=0; pending=0}
      END {printf "%d\t%d\t%d\t%s",checked+0,total+0,unlinked+0,next_text}
    ' "$file")
    checked=$(printf '%s' "$counts" | cut -f1); total=$(printf '%s' "$counts" | cut -f2); unlinked=$(printf '%s' "$counts" | cut -f3); next=$(printf '%s' "$counts" | cut -f4-)
    jq -cn --arg slug "$slug" --arg path "$file" --arg next "$next" --argjson checked "$checked" --argjson total "$total" --argjson unlinked "$unlinked" '{slug:$slug,path:$path,checked:$checked,total:$total,unlinked:$unlinked,next:$next}'
done >"$tmp/missions.ndjson"

jq -s '.' "$tmp/tickets.ndjson" >"$tmp/tickets.json"; jq -s '.' "$tmp/missions.ndjson" >"$tmp/missions.json"
jq -cn --slurpfile tickets "$tmp/tickets.json" --slurpfile missions "$tmp/missions.json" '
  {schema_version:1,tickets:$tickets[0],missions:($missions[0] | map(. as $m | .queue={todo:([$tickets[0][]|select(.area=="todo" and (.relations|index($m.slug))) ]|length),archive:([$tickets[0][]|select(.area=="archive" and (.relations|index($m.slug))) ]|length)}))}'

