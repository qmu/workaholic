#!/bin/sh -eu
# Catch the current work branch up with origin/<base> before deploy, so the
# artifact that gets deployed and confirmed equals what will land on merge.
# Fetches origin and merges origin/<base> into the current branch.
#
# Catching up is MANDATORY before any deploy step (a stale branch either reverts
# merged work or, for an idempotent deploy-on-merge release, silently no-ops it).
# On conflict this classifies the conflict so the ship flow can act deterministically:
#   - "mechanical": every conflicted path is a version/lockstep manifest or under
#     outputs/ — routine reconciliation the agent performs itself (merge, resolve,
#     re-run the pre-merge proof, re-bump the version past any collision).
#   - "content": some other path conflicts — a human must judge it; halt and ask.
# The merge is aborted either way so the caller acts from a clean tree.
#
# Usage: bash catchup-main.sh [base-branch]   (default base: main)
# Output: JSON
#   {"caught_up": true,  "base": "main", "already_current": true|false}
#   {"caught_up": false, "base": "main", "conflict": true,
#    "conflict_class": "mechanical"|"content", "conflicted_files": ["..."]}

set -eu

base="${1:-main}"

git fetch origin "$base" --quiet 2>/dev/null || git fetch origin --quiet

before=$(git rev-parse HEAD)

if git merge --no-edit "origin/${base}" >/dev/null 2>&1; then
  after=$(git rev-parse HEAD)
  if [ "$before" = "$after" ]; then
    printf '{"caught_up": true, "base": "%s", "already_current": true}\n' "$base"
  else
    printf '{"caught_up": true, "base": "%s", "already_current": false}\n' "$base"
  fi
else
  # Capture the unmerged paths BEFORE aborting the merge.
  conflicted=$(git diff --name-only --diff-filter=U)

  # Classify: mechanical iff every conflicted path is one of the version/lockstep
  # manifests or lives under outputs/ (a strict allowlist — anything else is content).
  class="mechanical"
  for f in $conflicted; do
    case "$f" in
      .claude-plugin/marketplace.json) ;;
      plugins/workaholic/.claude-plugin/plugin.json) ;;
      plugins/workaholic/.codex-plugin/plugin.json) ;;
      outputs/*) ;;
      *) class="content" ;;
    esac
  done

  # Build a JSON array of the conflicted files (line-based to tolerate any path).
  files_json=$(printf '%s\n' "$conflicted" | awk 'NF{ printf "%s\"%s\"", sep, $0; sep="," }')

  git merge --abort >/dev/null 2>&1 || true

  printf '{"caught_up": false, "base": "%s", "conflict": true, "conflict_class": "%s", "conflicted_files": [%s]}\n' \
    "$base" "$class" "$files_json"
fi
