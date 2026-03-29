#!/bin/bash
# Check workspace cleanliness: unstaged, untracked, and staged changes.
# Usage: bash check-workspace.sh
# Output: JSON with clean status, counts, and human-readable summary

set -euo pipefail

untracked=0
unstaged=0
staged=0

while IFS= read -r line; do
  [ -z "$line" ] && continue
  xy="${line:0:2}"
  case "$xy" in
    '??') untracked=$((untracked + 1)) ;;
    *)
      # First char: staged status (non-space = staged change)
      case "${xy:0:1}" in
        ' '|'?') ;;
        *) staged=$((staged + 1)) ;;
      esac
      # Second char: unstaged status (non-space = unstaged change)
      case "${xy:1:1}" in
        ' '|'?') ;;
        *) unstaged=$((unstaged + 1)) ;;
      esac
      ;;
  esac
done < <(git status --porcelain 2>/dev/null)

total=$((untracked + unstaged + staged))

if [ "$total" -eq 0 ]; then
  echo '{"clean": true, "untracked_count": 0, "unstaged_count": 0, "staged_count": 0, "summary": ""}'
else
  parts=""
  if [ "$staged" -gt 0 ]; then
    parts="${staged} staged"
  fi
  if [ "$unstaged" -gt 0 ]; then
    [ -n "$parts" ] && parts="${parts}, "
    parts="${parts}${unstaged} unstaged"
  fi
  if [ "$untracked" -gt 0 ]; then
    [ -n "$parts" ] && parts="${parts}, "
    parts="${parts}${untracked} untracked"
  fi
  echo "{\"clean\": false, \"untracked_count\": ${untracked}, \"unstaged_count\": ${unstaged}, \"staged_count\": ${staged}, \"summary\": \"${parts}\"}"
fi
