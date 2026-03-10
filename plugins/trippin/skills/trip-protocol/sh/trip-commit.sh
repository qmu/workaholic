#!/bin/bash
# Commit a trip workflow step with standardized message format.
# Usage: bash trip-commit.sh <agent> <phase> <step> <description>
# Example: bash trip-commit.sh planner specification "write-direction-v1" "Define initial creative direction based on user requirements"
# Commit message format: [Agent] <description>
# Body: Phase: <phase>\nStep: <step>

set -euo pipefail

agent="${1:-}"
phase="${2:-}"
step="${3:-}"
description="${4:-}"

if [ -z "$agent" ] || [ -z "$phase" ] || [ -z "$step" ] || [ -z "$description" ]; then
  echo '{"error": "usage: trip-commit.sh <agent> <phase> <step> <description>"}' >&2
  exit 1
fi

if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet HEAD 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  git add -A

  # Capitalize agent name for bracket prefix
  agent_cap="$(echo "${agent:0:1}" | tr '[:lower:]' '[:upper:]')${agent:1}"

  body="Phase: ${phase}
Step: ${step}"

  git commit -m "$(cat <<EOF
[${agent_cap}] ${description}

${body}
EOF
)"

  commit_hash="$(git rev-parse --short HEAD)"
  echo '{"committed": true, "hash": "'"${commit_hash}"'", "agent": "'"${agent}"'", "step": "'"${step}"'"}'
else
  echo '{"committed": false, "reason": "no changes to commit"}'
fi
