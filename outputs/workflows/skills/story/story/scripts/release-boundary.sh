#!/bin/sh -eu
# Decide whether the current branch is one completed mission release boundary.
#
# A version is not allocated merely because a branch has implementation work. The branch must
# archive at least one ticket, every archived ticket must belong to the same mission, and that
# mission must have reached the repository's existing arithmetic terminal state: archived as
# `achieved`, every acceptance item checked and linked, and no todo ticket remaining.
#
# Usage: release-boundary.sh [base-ref]
# Output: {"eligible":true,...} or {"eligible":false,"reason":"...",...}
# Pure read. Unknown facts refuse eligibility; callers report the reason and do not bump.

set -eu

BASE=${1:-origin/main}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"

emit_no() {
  reason=$1
  detail=${2:-}
  printf '{"eligible":false,"reason":"%s"%s}\n' "$reason" "$detail"
  exit 0
}

git rev-parse --verify "$BASE^{commit}" >/dev/null 2>&1 || emit_no base_unreadable

ticket_paths=$(git diff --name-only "$BASE...HEAD" -- '.workaholic/tickets/archive/*/*.md' 2>/dev/null) \
  || emit_no diff_unreadable
[ -n "$ticket_paths" ] || emit_no no_archived_tickets

ticket_count=0
mission=""
for ticket in $ticket_paths; do
  [ -f "$ticket" ] || emit_no archived_ticket_missing
  ticket_count=$((ticket_count + 1))
  relations=$(sh "${MISSION_SCRIPTS}/read-relation.sh" "$ticket" 2>/dev/null || true)
  relation_count=$(printf '%s\n' "$relations" | grep -c . || true)
  [ "$relation_count" -eq 1 ] || emit_no ticket_without_one_mission ",\"ticket\":\"$(basename "$ticket")\""
  relation=$(printf '%s\n' "$relations" | head -n 1)
  if [ -z "$mission" ]; then
    mission=$relation
  elif [ "$mission" != "$relation" ]; then
    emit_no mixed_missions
  fi
done

[ -n "$mission" ] || emit_no no_mission
mission_file=".workaholic/missions/archive/${mission}/mission.md"
[ -f "$mission_file" ] || emit_no mission_not_archived ",\"mission\":\"${mission}\""

status=$(sed -n 's/^status:[[:space:]]*//p' "$mission_file" | head -n 1)
[ "$status" = achieved ] || emit_no mission_not_achieved ",\"mission\":\"${mission}\""

progress=$(sh "${MISSION_SCRIPTS}/progress.sh" "$mission_file" 2>/dev/null || true)
queue=$(sh "${MISSION_SCRIPTS}/queue-size.sh" "$mission" 2>/dev/null || true)
checked=$(printf '%s' "$progress" | sed -n 's/.*"checked": *\([0-9][0-9]*\).*/\1/p')
total=$(printf '%s' "$progress" | sed -n 's/.*"total": *\([0-9][0-9]*\).*/\1/p')
unlinked=$(printf '%s' "$progress" | sed -n 's/.*"unlinked": *\([0-9][0-9]*\).*/\1/p')
todo=$(printf '%s' "$queue" | sed -n 's/.*"todo": *\([0-9][0-9]*\).*/\1/p')
[ -n "$checked" ] && [ -n "$total" ] && [ -n "$unlinked" ] && [ -n "$todo" ] \
  || emit_no mission_state_unreadable ",\"mission\":\"${mission}\""
[ "$total" -gt 0 ] && [ "$checked" -eq "$total" ] && [ "$unlinked" -eq 0 ] && [ "$todo" -eq 0 ] \
  || emit_no mission_incomplete ",\"mission\":\"${mission}\",\"checked\":${checked},\"total\":${total},\"unlinked\":${unlinked},\"todo\":${todo}"

printf '{"eligible":true,"reason":"completed_mission","mission":"%s","tickets":%d,"checked":%d,"total":%d}\n' \
  "$mission" "$ticket_count" "$checked" "$total"
