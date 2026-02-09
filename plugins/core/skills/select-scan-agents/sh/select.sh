#!/usr/bin/env bash
# select.sh - Select scanner agents based on scan mode and branch changes
#
# Usage: bash select.sh <mode> [base_branch]
#   mode: "full" or "partial"
#   base_branch: required for partial mode (e.g., "main")
#
# Output: JSON with mode and agent list
#   {"mode":"full","agents":["communication-lead","model-analyst",...]}

set -eu

MODE="${1:-}"
BASE_BRANCH="${2:-}"

ALL_AGENTS="communication-lead model-analyst infra-lead architecture-lead db-lead test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"

if [ -z "$MODE" ]; then
  echo '{"error":"Usage: select.sh <mode> [base_branch]"}'
  exit 1
fi

if [ "$MODE" = "full" ]; then
  agents_json=""
  sep=""
  for agent in $ALL_AGENTS; do
    agents_json="${agents_json}${sep}\"${agent}\""
    sep=","
  done
  echo "{\"mode\":\"full\",\"agents\":[${agents_json}]}"
  exit 0
fi

if [ "$MODE" != "partial" ]; then
  echo '{"error":"Mode must be full or partial"}'
  exit 1
fi

if [ -z "$BASE_BRANCH" ]; then
  echo '{"error":"base_branch required for partial mode"}'
  exit 1
fi

# Get diff stat against base branch
DIFF_STAT=$(git diff --stat "${BASE_BRANCH}...HEAD" 2>/dev/null || echo "")

if [ -z "$DIFF_STAT" ]; then
  # No changes detected, return changelog-writer only
  echo '{"mode":"partial","agents":["changelog-writer"]}'
  exit 0
fi

# Track which agents to include (using marker file approach for POSIX compatibility)
TMPDIR_SEL=$(mktemp -d)
trap 'rm -rf "$TMPDIR_SEL"' EXIT

# Always include changelog-writer for partial scan
touch "$TMPDIR_SEL/changelog-writer"

# Analyze each changed path
echo "$DIFF_STAT" | while IFS= read -r line; do
  # Skip summary line (e.g., "10 files changed, 50 insertions(+)")
  case "$line" in
    *"files changed"*|*"file changed"*) continue ;;
  esac

  # Extract file path (first field before the pipe)
  path=$(echo "$line" | sed 's/|.*//' | sed 's/^ *//' | sed 's/ *$//')

  case "$path" in
    plugins/core/commands/*|plugins/core/agents/*)
      touch "$TMPDIR_SEL/architecture-lead"
      ;;
  esac

  case "$path" in
    plugins/core/skills/*)
      touch "$TMPDIR_SEL/architecture-lead"
      ;;
  esac

  case "$path" in
    plugins/core/rules/*)
      touch "$TMPDIR_SEL/quality-lead"
      touch "$TMPDIR_SEL/architecture-lead"
      ;;
  esac

  case "$path" in
    .workaholic/tickets/*)
      touch "$TMPDIR_SEL/db-lead"
      touch "$TMPDIR_SEL/model-analyst"
      ;;
  esac

  case "$path" in
    .workaholic/terms/*)
      touch "$TMPDIR_SEL/terms-writer"
      ;;
  esac

  case "$path" in
    .claude-plugin/*|plugins/*/.claude-plugin/*)
      touch "$TMPDIR_SEL/infra-lead"
      touch "$TMPDIR_SEL/delivery-lead"
      ;;
  esac

  case "$path" in
    README.md|CLAUDE.md)
      touch "$TMPDIR_SEL/communication-lead"
      touch "$TMPDIR_SEL/architecture-lead"
      ;;
  esac

  case "$path" in
    .github/*)
      touch "$TMPDIR_SEL/delivery-lead"
      touch "$TMPDIR_SEL/security-lead"
      ;;
  esac
done

# Build JSON from marker files
agents_json=""
sep=""
for agent in $ALL_AGENTS; do
  if [ -f "$TMPDIR_SEL/$agent" ]; then
    agents_json="${agents_json}${sep}\"${agent}\""
    sep=","
  fi
done

echo "{\"mode\":\"partial\",\"agents\":[${agents_json}]}"
