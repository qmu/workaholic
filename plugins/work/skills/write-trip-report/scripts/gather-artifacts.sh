#!/bin/bash
# Gather trip artifacts and output JSON with paths to latest versions.
# Usage: bash gather-artifacts.sh <trip-name>
# Output: JSON with artifact paths and history availability.
# Supports both old-style per-artifact review directories and new-style
# top-level reviews/ directory (dual-path scanning for backward compatibility).

set -euo pipefail

trip_name="${1:-}"

if [ -z "$trip_name" ]; then
  echo '{"error": "trip name is required"}' >&2
  exit 1
fi

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

trip_path="${root}/.workaholic/.trips/${trip_name}"

if [ ! -d "$trip_path" ]; then
  echo '{"error": "trip directory not found", "path": "'"$trip_path"'"}' >&2
  exit 1
fi

# Find latest version of each artifact type
find_latest() {
  local dir="$1" prefix="$2"
  ls -1 "${dir}/${prefix}-v"*.md 2>/dev/null | sort -t'v' -k2 -n | tail -1 || echo ""
}

direction=$(find_latest "${trip_path}/directions" "direction")
model=$(find_latest "${trip_path}/models" "model")
design=$(find_latest "${trip_path}/designs" "design")

# Collect review files -- dual-path scanning for backward compatibility
# New-style: top-level reviews/ directory with round-N-agent.md files
# Old-style: per-artifact reviews/ subdirectories with artifact-vN-agent.md files
consolidated_reviews=""
old_direction_reviews=""
old_model_reviews=""
old_design_reviews=""

# Check new-style consolidated reviews first
if [ -d "${trip_path}/reviews" ]; then
  consolidated_reviews=$(ls -1 "${trip_path}/reviews/"*.md 2>/dev/null | paste -sd',' - || echo "")
fi

# Check old-style per-artifact review directories for backward compatibility
if [ -d "${trip_path}/directions/reviews" ]; then
  old_direction_reviews=$(ls -1 "${trip_path}/directions/reviews/"*.md 2>/dev/null | paste -sd',' - || echo "")
fi
if [ -d "${trip_path}/models/reviews" ]; then
  old_model_reviews=$(ls -1 "${trip_path}/models/reviews/"*.md 2>/dev/null | paste -sd',' - || echo "")
fi
if [ -d "${trip_path}/designs/reviews" ]; then
  old_design_reviews=$(ls -1 "${trip_path}/designs/reviews/"*.md 2>/dev/null | paste -sd',' - || echo "")
fi

# Check for event-log.md
has_event_log=false
event_log_path="${trip_path}/event-log.md"
if [ -f "$event_log_path" ]; then
  has_event_log=true
fi

# Check for history.md
has_history=false
history_path="${trip_path}/history.md"
if [ -f "$history_path" ]; then
  has_history=true
fi

# Check for plan.md
has_plan=false
plan_path="${trip_path}/plan.md"
if [ -f "$plan_path" ]; then
  has_plan=true
fi

# Build JSON arrays for reviews
build_array() {
  local items="$1"
  if [ -z "$items" ]; then
    echo "[]"
    return
  fi
  local result="["
  local first=true
  IFS=',' read -ra arr <<< "$items"
  for item in "${arr[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      result="${result},"
    fi
    result="${result}\"${item}\""
  done
  result="${result}]"
  echo "$result"
}

cons_rev_json=$(build_array "$consolidated_reviews")
dir_rev_json=$(build_array "$old_direction_reviews")
mod_rev_json=$(build_array "$old_model_reviews")
des_rev_json=$(build_array "$old_design_reviews")

cat <<EOF
{
  "trip_name": "${trip_name}",
  "trip_path": "${trip_path}",
  "direction": "${direction}",
  "model": "${model}",
  "design": "${design}",
  "reviews": ${cons_rev_json},
  "direction_reviews": ${dir_rev_json},
  "model_reviews": ${mod_rev_json},
  "design_reviews": ${des_rev_json},
  "has_event_log": ${has_event_log},
  "event_log_path": "${event_log_path}",
  "has_history": ${has_history},
  "history_path": "${history_path}",
  "has_plan": ${has_plan},
  "plan_path": "${plan_path}"
}
EOF
