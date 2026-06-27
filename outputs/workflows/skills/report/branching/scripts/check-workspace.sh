#!/bin/sh -eu
# Check workspace cleanliness: unstaged, untracked, and staged changes.
# Usage: sh check-workspace.sh
# Output: JSON with clean status, counts, and human-readable summary

set -eu

# Porcelain status: each line is "XY <path>". X = staged column, Y = unstaged
# column, "??" = untracked. Count with grep (POSIX has no process substitution,
# and a piped `while` loop would lose its counters to a subshell).
status=$(git status --porcelain 2>/dev/null || true)

if [ -z "$status" ]; then
  echo '{"clean": true, "untracked_count": 0, "unstaged_count": 0, "staged_count": 0, "summary": ""}'
  exit 0
fi

# Untracked: first two columns are "??".
untracked=$(printf '%s\n' "$status" | grep -cE '^\?\?' || true)
# Staged: first column is neither space nor "?".
staged=$(printf '%s\n' "$status" | grep -cE '^[^ ?]' || true)
# Unstaged: second column is neither space nor "?".
unstaged=$(printf '%s\n' "$status" | grep -cE '^.[^ ?]' || true)

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
