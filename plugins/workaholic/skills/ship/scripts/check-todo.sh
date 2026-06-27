#!/bin/sh -eu
# Check whether the current user's todo queue is clean.
# Usage: sh check-todo.sh
# Output: JSON with cleanliness status, ticket count, and file list.
#
# The blocking check is scoped to .workaholic/tickets/todo/<user>/ so that other
# developers' tickets -- in their own subdirectories, or unswept at the todo/
# root -- never block this user's merge. This is the deliberate per-user DX: a
# user ships when THEIR queue is clear, not when the whole repo's queue is.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_SLUG=$(sh "${SCRIPT_DIR}/../../../../workaholic/skills/gather/scripts/user-slug.sh")

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
todo_dir="${root}/.workaholic/tickets/todo/${USER_SLUG}"

if [ ! -d "$todo_dir" ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
  exit 0
fi

# Collect the ticket filenames (basenames). POSIX has no arrays or `< <(...)`,
# so accumulate via find|sort and count/serialize with grep + jq.
files=$(find "$todo_dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort || true)
count=$(printf '%s' "$files" | grep -c . || true)

if [ "$count" -eq 0 ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
else
  ticket_json=$(printf '%s\n' "$files" | grep -v '^$' | while IFS= read -r f; do basename "$f"; done | jq -R . | jq -s -c .)
  echo "{\"clean\": false, \"count\": ${count}, \"tickets\": ${ticket_json}}"
fi
