#!/bin/sh -eu
# Merge a PR, then bring the local base branch up to date when this checkout can.
# Usage: sh merge-pr.sh <pr-number> [base-branch]
# Output: {"merged": true, "pr_number": N, "commit_hash": "...",
#          "checked_out": true|false, "checkout_reason": "", "base": "main"}
#     or: {"merged": false, "error": "merge failed"} on stderr, exit 1
#
# THE EXIT STATUS REFLECTS THE MERGE, AND ONLY THE MERGE. The merge is irreversible, so
# the caller's most important question is whether it happened -- and a non-zero exit
# after a successful merge answers the opposite. That is not hypothetical: this script
# used to end with a bare `git checkout main`, which git refuses inside a linked worktree
# whenever `main` is checked out in the primary tree. `/drive` ships every `auto` unit
# FROM the claim worktree, so the sanctioned location was exactly where it broke, and on
# 2026-07-30 it reported failure while PR #108 merged as 39b52709. The post-merge
# bookkeeping is now a reported FIELD; only a failed merge fails the script.
#
# WHY THE CHECKOUT IS STILL ATTEMPTED. Landing on the base is convenient for the steps
# that follow a merge. It is no longer load-bearing: extract-deferred-concerns.sh takes
# an explicit base and publishes there regardless of the checkout it runs in, so a
# skipped checkout cannot silently send knowledge to a dead branch (which is what
# happened to PR #108's four concern records).

set -eu

pr_number="${1:-}"
base="${2:-main}"

if [ -z "$pr_number" ]; then
  echo '{"error": "PR number is required"}' >&2
  exit 1
fi

if ! gh pr merge "$pr_number" --merge --delete-branch=false; then
  echo '{"merged": false, "error": "merge failed"}' >&2
  exit 1
fi

# --- From here the merge has LANDED. Nothing below may fail the script. --------------
checked_out=false
checkout_reason=""

current=$(git branch --show-current 2>/dev/null || true)
if [ "$current" = "$base" ]; then
  checked_out=true
elif git worktree list --porcelain 2>/dev/null | grep -qx "branch refs/heads/${base}"; then
  # Another worktree of this repository holds the base branch, so `git checkout` here
  # cannot succeed and is not attempted: the primary-tree-holds-main layout is the
  # normal one, not an error state.
  checkout_reason="base_checked_out_elsewhere"
elif git checkout "$base" >&2 2>&1; then
  checked_out=true
else
  checkout_reason="checkout_failed"
fi

if [ "$checked_out" = "true" ]; then
  if ! git pull origin "$base" >&2 2>&1; then
    checkout_reason="pull_failed"
  fi
fi

commit_hash=$(git rev-parse --short HEAD)

cat <<EOF
{"merged": true, "pr_number": $pr_number, "commit_hash": "$commit_hash", "checked_out": $checked_out, "checkout_reason": "$checkout_reason", "base": "$base"}
EOF
