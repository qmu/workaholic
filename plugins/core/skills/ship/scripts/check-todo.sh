#!/bin/bash
# Check whether the current user's todo queue is clean.
# Usage: bash check-todo.sh
# Output: JSON with cleanliness status, ticket count, and file list.
#
# The blocking check is scoped to .workaholic/tickets/todo/<user>/ so that other
# developers' tickets -- in their own subdirectories, or unswept at the todo/
# root -- never block this user's merge. This is the deliberate per-user DX: a
# user ships when THEIR queue is clear, not when the whole repo's queue is.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_SLUG=$(sh "${SCRIPT_DIR}/../../../../core/skills/gather/scripts/user-slug.sh")

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
todo_dir="${root}/.workaholic/tickets/todo/${USER_SLUG}"

if [ ! -d "$todo_dir" ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
  exit 0
fi

tickets=()
while IFS= read -r f; do
  tickets+=("$(basename "$f")")
done < <(find "$todo_dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)

count=${#tickets[@]}

if [ "$count" -eq 0 ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
else
  ticket_json=$(printf '%s\n' "${tickets[@]}" | jq -R . | jq -s .)
  echo "{\"clean\": false, \"count\": ${count}, \"tickets\": ${ticket_json}}"
fi
