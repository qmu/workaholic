#!/bin/sh -eu
# Check whether the current user's todo queue is clean.
# Usage: sh check-todo.sh
# Output: JSON with cleanliness status, ticket count, and file list.
#
# The blocking check is scoped to the tickets this user OWNS, so another
# developer's queued work never blocks this user's merge. This is the deliberate
# per-user DX: a user ships when THEIR queue is clear, not when the whole repo's
# queue is. The scope used to be the directory `todo/<user>/`; since P2
# (2026-08-06) it is the `assignees` field, read through the one ownership oracle
# (gather/scripts/owns.sh). An UNOWNED ticket counts as this user's: team-owned
# work is claimable by anyone, so leaving it queued is exactly the loose end this
# check exists to surface.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
todo_dir="${root}/.workaholic/tickets/todo"

if [ ! -d "$todo_dir" ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
  exit 0
fi

# Collect the ticket filenames (basenames). POSIX has no arrays or `< <(...)`,
# so accumulate via find|sort and count/serialize with grep + jq. Depth 2 keeps a
# not-yet-migrated per-user directory visible, so a stale checkout is not reported
# clean while it still holds work.
ME=$(git config user.email 2>/dev/null || true)
files=""
for f in $(find "$todo_dir" -maxdepth 2 -name '*.md' -type f 2>/dev/null | sort || true); do
  case "$(sh "${GATHER_SCRIPTS}/owns.sh" "$f" "$ME" 2>/dev/null || echo unowned)" in
    mine|unowned) ;;
    *) continue ;;
  esac
  if [ -n "$files" ]; then
    files="${files}
${f}"
  else
    files="$f"
  fi
done
count=$(printf '%s' "$files" | grep -c . || true)

if [ "$count" -eq 0 ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
else
  ticket_json=$(printf '%s\n' "$files" | grep -v '^$' | while IFS= read -r f; do basename "$f"; done | jq -R . | jq -s -c .)
  echo "{\"clean\": false, \"count\": ${count}, \"tickets\": ${ticket_json}}"
fi
