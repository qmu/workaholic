#!/bin/bash
# Check if todo tickets directory is clean.
# Usage: bash check-todo.sh
# Output: JSON with ticket count and file list

set -euo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
todo_dir="${root}/.workaholic/tickets/todo"

if [ ! -d "$todo_dir" ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
  exit 0
fi

tickets=()
while IFS= read -r f; do
  tickets+=("$(basename "$f")")
done < <(find "$todo_dir" -name '*.md' -type f 2>/dev/null | sort)

count=${#tickets[@]}

if [ "$count" -eq 0 ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
else
  ticket_json=$(printf '%s\n' "${tickets[@]}" | jq -R . | jq -s .)
  echo "{\"clean\": false, \"count\": ${count}, \"tickets\": ${ticket_json}}"
fi
