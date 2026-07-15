#!/bin/sh -eu
# Detect development context from current branch pattern.
# Usage: sh detect-context.sh
# Output: JSON with context type, branch, and optional mode/trip_name

set -eu

branch=$(git branch --show-current 2>/dev/null || echo "")
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_SLUG=$(sh "${SCRIPT_DIR}/../../gather/scripts//user-slug.sh" 2>/dev/null || echo "")

if [ -z "$branch" ]; then
  echo '{"context": "unknown", "branch": ""}'
  exit 0
fi

# Resolve the trip directory belonging to THIS branch, or empty when the branch owns none.
#
# The ONLY trip<->branch association this repository records is the legacy naming
# convention: branch trip/<name> owns .workaholic/trips/<name>. A modern work-* branch
# stores no link to any trip -- init-trip.sh records no branch, plan.md carries no branch
# field, and a trip's branch is an independent work-YYYYMMDD-HHMMSS minted by create.sh.
# So a work-* branch cannot truthfully claim a trip, and this returns empty for it.
#
# This replaced a repo-wide `find` for ANY trip directory, which made has_trips a property
# of the repository instead of the branch: once .workaholic/trips/trip-20260319-040153/
# landed on main in March 2026, every branch after it reported trip or hybrid forever.
# The asymmetry was inside one function -- the ticket half three lines below was already
# scoped to USER_SLUG, deliberately and with a comment.
#
# Giving work-* branches a real association is a deliberate, separate decision, not a
# thing to infer here: detect-context.sh also emits trip_name only for trip/* branches, so
# report/SKILL.md's Trip Mode step 3 cannot resolve <trip-name> on a work-* branch either.
# The association must answer both, and inventing one inside a bugfix would make the
# detector wrong in a NEW way -- worse than wrong in a known one.
branch_trip_dir() {
  case "$branch" in
    trip/*) printf '%s' "${root}/.workaholic/trips/${branch#trip/}" ;;
    *) printf '' ;;
  esac
}

# Detect mode from workspace artifacts
detect_mode() {
  todo_dir="${root}/.workaholic/tickets/todo"
  has_trips=false
  has_tickets=false

  trip_dir=$(branch_trip_dir)
  if [ -n "$trip_dir" ] && [ -d "$trip_dir" ]; then
    has_trips=true
  fi

  # Scope the count to the current user's subdirectory so another developer's
  # leftover tickets don't flip mode detection for this user.
  ticket_count=$(find "${todo_dir}/${USER_SLUG}" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)
  if [ "$ticket_count" -gt 0 ]; then
    has_tickets=true
  fi

  if $has_trips && $has_tickets; then
    echo "hybrid"
  elif $has_trips; then
    echo "trip"
  elif $has_tickets; then
    echo "drive"
  else
    echo "drive"
  fi
}

# Work context: branch matches work-*
case "$branch" in
  work-*)
    mode=$(detect_mode)
    echo "{\"context\": \"work\", \"branch\": \"${branch}\", \"mode\": \"${mode}\"}"
    exit 0
    ;;
esac

# Backward compat: drive-* branches map to work context with drive mode
case "$branch" in
  drive-*)
    echo "{\"context\": \"work\", \"branch\": \"${branch}\", \"mode\": \"drive\"}"
    exit 0
    ;;
esac

# Backward compat: trip/* branches map to work context with trip/hybrid mode
case "$branch" in
  trip/*)
    trip_name="${branch#trip/}"
    mode=$(detect_mode)
    if [ "$mode" = "drive" ]; then
      mode="trip"
    fi
    echo "{\"context\": \"work\", \"branch\": \"${branch}\", \"mode\": \"${mode}\", \"trip_name\": \"${trip_name}\"}"
    exit 0
    ;;
esac

# Main/master: unknown context
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  echo "{\"context\": \"unknown\", \"branch\": \"${branch}\"}"
  exit 0
fi

# Other branch: check for worktrees
script_dir="$(cd "$(dirname "$0")" && pwd)"
list_script="${script_dir}/list-worktrees.sh"

if [ -f "$list_script" ]; then
  worktree_output=$(sh "$list_script" 2>/dev/null || echo '{"count": 0}')
  count=$(printf '%s' "$worktree_output" | jq -r '.count' 2>/dev/null || echo "0")

  if [ "$count" -gt 0 ]; then
    echo "{\"context\": \"worktree\", \"branch\": \"${branch}\"}"
    exit 0
  fi
fi

echo "{\"context\": \"unknown\", \"branch\": \"${branch}\"}"
