#!/bin/sh -eu
# One tick's progress readout: where the queue stands, per mission, and what the
# origination gate would answer next.
#
# Usage: tick-progress.sh [repo-root]
# Output: one JSON object, ALWAYS exit 0.
#   {"queue_total": N, "missions": [{slug, checked, total, todo, archived, draining}],
#    "gating_missions": N, "wip_limit": N|null, "propose_gate": "work_waiting"|"open"}
#
# WHY IT EXISTS (2026-09-03, the developer's ask). The tick reported which loops it
# spawned and nothing about whether the work was moving. A person watching it could not
# tell a queue that is draining from one that is stuck, nor how close the origination
# gate is to opening — both of which are already derivable from readers this repository
# owns. It composes them; it derives nothing of its own, holds no state and writes
# nothing.
#
# `draining` is a FACT ABOUT THIS MISSION'S OWN ARCHIVE, not a trend: a mission with
# archived tickets has had work land. A trend needs two readings and this script keeps
# no cursor by design — the caller compares ticks.

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
S="$ROOT/plugins/workaholic/skills"
ACTIVE="$ROOT/.workaholic/missions/active"

queue_total=$(find "$ROOT/.workaholic/tickets/todo" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
rows=''
gating=0

if [ -d "$ACTIVE" ]; then
  for slug in $(find "$ACTIVE" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort); do
    prog=$(sh "$S/mission/scripts/progress.sh" "$ACTIVE/$slug/mission.md" 2>/dev/null || echo '{}')
    q=$(sh "$S/mission/scripts/queue-size.sh" "$slug" 2>/dev/null || echo '{}')
    row=$(printf '%s\n%s\n' "$prog" "$q" | jq -s --arg slug "$slug" '
      {slug: $slug,
       checked: (.[0].checked // null), total: (.[0].total // null),
       todo: (.[1].todo // null), archived: (.[1].archive // null),
       draining: ((.[1].archive // 0) > 0)}' 2>/dev/null || echo '{}')
    [ "$(printf '%s' "$row" | jq -r '.todo // 0' 2>/dev/null)" -gt 0 ] 2>/dev/null && gating=$((gating + 1))
    rows="$rows$row"
  done
fi

limit="${WORKAHOLIC_WIP_LIMIT:-}"
gate=work_waiting
[ "$gating" -eq 0 ] && gate=open

printf '%s' "$rows" | jq -s \
  --argjson queue "$queue_total" \
  --argjson gating "$gating" \
  --arg limit "$limit" \
  --arg gate "$gate" \
  '{queue_total: $queue, missions: ., gating_missions: $gating,
    wip_limit: (if $limit == "" then null else ($limit | tonumber) end),
    propose_gate: $gate}'
