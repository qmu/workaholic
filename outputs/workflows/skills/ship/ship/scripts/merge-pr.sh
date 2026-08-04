#!/bin/sh -eu
# Merge a PR, then bring the local base branch up to date when this checkout can.
# Usage: sh merge-pr.sh <pr-number> [base-branch]
# Output: {"merged": true, "pr_number": N, "commit_hash": "...",
#          "commit_hash_source": "pr_merge_commit"|"base_tip"|"unresolved",
#          "branch_head": "...",
#          "checked_out": true|false, "checkout_reason": "", "base": "main"}
#     or: {"merged": false, "error": "merge failed"} on stderr, exit 1
#     or: {"merged": false, "reason": "gh_unavailable"} on stderr, exit 1 -- the CLI is
#         absent (the cloud runner's condition), so NOTHING was merged. This one still
#         exits non-zero, unlike the read-only seams: the caller asked for an
#         irreversible action that did not happen, and reporting that as success would
#         be the worst possible degradation.
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

if ! command -v gh >/dev/null 2>&1; then
  echo '{"merged": false, "reason": "gh_unavailable", "pr_number": '"$pr_number"', "detail": "the GitHub CLI is not installed here; nothing was merged -- merge the pull request from an environment that has it"}' >&2
  exit 1
fi

if ! gh pr merge "$pr_number" --merge --delete-branch=false; then
  echo '{"merged": false, "error": "merge failed"}' >&2
  exit 1
fi

# --- From here the merge has LANDED. Nothing below may fail the script. --------------

# `commit_hash` NAMES THE COMMIT THIS MERGE PRODUCED ON THE BASE, not the branch head.
# It used to be `git rev-parse --short HEAD`, which inside a claim worktree is the last
# commit on the WORK BRANCH — a different commit whenever the base advanced since the
# branch's last catch-up, and not even an ancestor of what landed under a squash or
# rebase merge. Ship Flow step 7 feeds this field straight to the release as its
# target, so a release-on-tag project tagged a commit that was never on the base's
# first-parent line. Observed on two consecutive ships, deterministically, and both
# times recovered by hand with `gh pr view --json mergeCommit` — a value that reads
# true and is not, which is exactly the silent-wrong-answer class the observability
# policy exists to prevent.
#
# The PR's own `mergeCommit` is authoritative for every merge strategy, so it is asked
# first. `base_tip` is a DERIVED fallback (it is the merge commit only while nobody
# else merged in between), which is why the source is reported rather than left for
# the caller to assume.
branch_head=$(git rev-parse --short HEAD 2>/dev/null || true)
commit_hash=""
commit_hash_source="unresolved"

merge_oid=$(gh pr view "$pr_number" --json mergeCommit --jq '.mergeCommit.oid' 2>/dev/null || true)
case "$merge_oid" in
  "" | null) ;;
  *) commit_hash="$merge_oid"; commit_hash_source="pr_merge_commit" ;;
esac

# Fetch before resolving: the merge commit does not exist in this checkout yet, which
# both the fallback and the short-form normalization below need it to.
git fetch origin "$base" >&2 2>&1 || true

if [ -z "$commit_hash" ]; then
  base_tip=$(git rev-parse "origin/${base}" 2>/dev/null || true)
  if [ -n "$base_tip" ]; then
    commit_hash="$base_tip"; commit_hash_source="base_tip"
  fi
fi

# Normalize to the short form callers have always been handed. Falls back to the full
# oid when the object is not present locally — a usable value beats an empty one.
if [ -n "$commit_hash" ]; then
  short=$(git rev-parse --short "$commit_hash" 2>/dev/null || true)
  if [ -n "$short" ]; then
    commit_hash="$short"
  fi
fi

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

cat <<EOF
{"merged": true, "pr_number": $pr_number, "commit_hash": "$commit_hash", "commit_hash_source": "$commit_hash_source", "branch_head": "$branch_head", "checked_out": $checked_out, "checkout_reason": "$checkout_reason", "base": "$base"}
EOF
