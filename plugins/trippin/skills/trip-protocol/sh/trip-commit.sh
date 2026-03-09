#!/bin/bash
# Commit a trip workflow step with standardized message format.
# Usage: bash trip-commit.sh <agent> <phase> <step> [description]
# Example: bash trip-commit.sh planner specification "write direction v1" "Initial creative direction"
# Commit message format: trip(<agent>): <step>
# Body: Phase: <phase>\n<description>

set -euo pipefail

agent="${1:-}"
phase="${2:-}"
step="${3:-}"
description="${4:-}"

if [ -z "$agent" ] || [ -z "$phase" ] || [ -z "$step" ]; then
  echo '{"error": "usage: trip-commit.sh <agent> <phase> <step> [description]"}' >&2
  exit 1
fi

if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet HEAD 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  git add -A

  body="Phase: ${phase}"
  if [ -n "$description" ]; then
    body="${body}
${description}"
  fi

  git commit -m "$(cat <<EOF
trip(${agent}): ${step}

${body}
EOF
)"

  commit_hash="$(git rev-parse --short HEAD)"
  echo '{"committed": true, "hash": "'"${commit_hash}"'", "agent": "'"${agent}"'", "step": "'"${step}"'"}'
else
  echo '{"committed": false, "reason": "no changes to commit"}'
fi
