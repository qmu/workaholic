#!/bin/bash
# Read trip plan state from plan.md and output JSON.
# Usage: bash read-plan.sh <trip-path>
# Output: JSON with phase, step, iteration, instruction, updated_at
# If plan.md does not exist, outputs {"phase": "unknown", "step": "unknown"}

set -euo pipefail

trip_path="${1:-}"

if [ -z "$trip_path" ]; then
  echo '{"error": "trip path is required"}' >&2
  exit 1
fi

plan_file="${trip_path}/plan.md"

if [ ! -f "$plan_file" ]; then
  echo '{"phase": "unknown", "step": "unknown"}'
  exit 0
fi

# Extract frontmatter fields using simple line-by-line parsing
phase=""
step=""
iteration=""
instruction=""
updated_at=""
blocked=""
in_frontmatter=false

while IFS= read -r line; do
  if [ "$line" = "---" ]; then
    if [ "$in_frontmatter" = true ]; then
      break
    fi
    in_frontmatter=true
    continue
  fi
  if [ "$in_frontmatter" = true ]; then
    key="${line%%:*}"
    val="${line#*: }"
    # Strip surrounding quotes from value
    val="${val#\"}"
    val="${val%\"}"
    case "$key" in
      phase) phase="$val" ;;
      step) step="$val" ;;
      iteration) iteration="$val" ;;
      instruction) instruction="$val" ;;
      updated_at) updated_at="$val" ;;
      blocked) blocked="$val" ;;
    esac
  fi
done < "$plan_file"

# Output JSON - escape quotes in instruction and blocked for safe JSON
instruction_escaped=$(printf '%s' "$instruction" | sed 's/\\/\\\\/g; s/"/\\"/g')
blocked_escaped=$(printf '%s' "$blocked" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat <<EOF
{"phase": "${phase:-unknown}", "step": "${step:-unknown}", "iteration": ${iteration:-0}, "instruction": "${instruction_escaped}", "updated_at": "${updated_at}", "blocked": "${blocked_escaped}"}
EOF
