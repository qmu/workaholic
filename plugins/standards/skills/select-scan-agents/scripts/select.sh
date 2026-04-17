#!/usr/bin/env bash
# select.sh - Select scanner agents based on scan mode and branch changes
#
# Usage: bash select.sh <mode> [base_branch]
#   mode: "full" or "partial"
#   base_branch: required for partial mode (e.g., "main")
#
# Output: JSON with mode, managers, leads (with domain), and writers
#   {"mode":"full","managers":[...],"leads":[{"agent":"lead","domain":"ux"},...],"writers":["model-analyst",...]}

set -eu

MODE="${1:-}"
BASE_BRANCH="${2:-}"

ALL_MANAGERS="project-manager architecture-manager quality-manager"
ALL_LEAD_DOMAINS="accessibility security validity availability"
ALL_WRITERS="model-analyst changelog-writer terms-writer"

if [ -z "$MODE" ]; then
  echo '{"error":"Usage: select.sh <mode> [base_branch]"}'
  exit 1
fi

if [ "$MODE" = "full" ]; then
  managers_json=""
  sep=""
  for mgr in $ALL_MANAGERS; do
    managers_json="${managers_json}${sep}\"${mgr}\""
    sep=","
  done
  leads_json=""
  sep=""
  for domain in $ALL_LEAD_DOMAINS; do
    leads_json="${leads_json}${sep}{\"agent\":\"lead\",\"domain\":\"${domain}\"}"
    sep=","
  done
  writers_json=""
  sep=""
  for writer in $ALL_WRITERS; do
    writers_json="${writers_json}${sep}\"${writer}\""
    sep=","
  done
  echo "{\"mode\":\"full\",\"managers\":[${managers_json}],\"leads\":[${leads_json}],\"writers\":[${writers_json}]}"
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
  echo '{"mode":"partial","managers":[],"leads":[],"writers":["changelog-writer"]}'
  exit 0
fi

# Track which agents to include (using marker file approach for POSIX compatibility)
TMPDIR_SEL=$(mktemp -d)
trap 'rm -rf "$TMPDIR_SEL"' EXIT

# Always include changelog-writer for partial scan
touch "$TMPDIR_SEL/writer-changelog-writer"

# Analyze each changed path
echo "$DIFF_STAT" | while IFS= read -r line; do
  # Skip summary line (e.g., "10 files changed, 50 insertions(+)")
  case "$line" in
    *"files changed"*|*"file changed"*) continue ;;
  esac

  # Extract file path (first field before the pipe)
  path=$(echo "$line" | sed 's/|.*//' | sed 's/^ *//' | sed 's/ *$//')

  case "$path" in
    plugins/work/commands/*|plugins/work/agents/*)
      touch "$TMPDIR_SEL/mgr-architecture-manager"
      ;;
  esac

  case "$path" in
    plugins/work/skills/*)
      touch "$TMPDIR_SEL/mgr-architecture-manager"
      ;;
  esac

  case "$path" in
    plugins/work/rules/*)
      touch "$TMPDIR_SEL/mgr-quality-manager"
      touch "$TMPDIR_SEL/lead-validity"
      ;;
  esac

  case "$path" in
    .workaholic/tickets/*)
      touch "$TMPDIR_SEL/lead-validity"
      touch "$TMPDIR_SEL/writer-model-analyst"
      ;;
  esac

  case "$path" in
    .workaholic/terms/*)
      touch "$TMPDIR_SEL/writer-terms-writer"
      ;;
  esac

  case "$path" in
    .claude-plugin/*|plugins/*/.claude-plugin/*)
      touch "$TMPDIR_SEL/lead-availability"
      ;;
  esac

  case "$path" in
    README.md|CLAUDE.md)
      touch "$TMPDIR_SEL/lead-accessibility"
      touch "$TMPDIR_SEL/mgr-project-manager"
      ;;
  esac

  case "$path" in
    .github/*)
      touch "$TMPDIR_SEL/lead-availability"
      touch "$TMPDIR_SEL/lead-security"
      ;;
  esac
done

# Build JSON from marker files
managers_json=""
sep=""
for mgr in $ALL_MANAGERS; do
  if [ -f "$TMPDIR_SEL/mgr-$mgr" ]; then
    managers_json="${managers_json}${sep}\"${mgr}\""
    sep=","
  fi
done

leads_json=""
sep=""
for domain in $ALL_LEAD_DOMAINS; do
  if [ -f "$TMPDIR_SEL/lead-$domain" ]; then
    leads_json="${leads_json}${sep}{\"agent\":\"lead\",\"domain\":\"${domain}\"}"
    sep=","
  fi
done

writers_json=""
sep=""
for writer in $ALL_WRITERS; do
  if [ -f "$TMPDIR_SEL/writer-$writer" ]; then
    writers_json="${writers_json}${sep}\"${writer}\""
    sep=","
  fi
done

echo "{\"mode\":\"partial\",\"managers\":[${managers_json}],\"leads\":[${leads_json}],\"writers\":[${writers_json}]}"
