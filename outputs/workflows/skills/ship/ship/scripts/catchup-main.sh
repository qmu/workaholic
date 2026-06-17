#!/bin/sh -eu
# Catch the current work branch up with origin/<base> before deploy, so the
# artifact that gets deployed and confirmed equals what will land on merge.
# Fetches origin and merges origin/<base> into the current branch.
#
# Usage: bash catchup-main.sh [base-branch]   (default base: main)
# Output: JSON
#   {"caught_up": true,  "base": "main", "already_current": true|false}
#   {"caught_up": false, "base": "main", "conflict": true}   (merge aborted)

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
  git merge --abort >/dev/null 2>&1 || true
  printf '{"caught_up": false, "base": "%s", "conflict": true}\n' "$base"
fi
