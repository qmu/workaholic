#!/bin/sh -eu
# Merge a PR, then bring the local base branch up to date when this checkout can.
# Usage: sh merge-pr.sh <pr-number> [base-branch]
# Output: {"merged": true, "pr_number": N, "commit_hash": "...",
#          "commit_hash_source": "pr_merge_commit"|"base_tip"|"branch_head",
#          "on_base": true|false, "branch_head": "...",
#          "checked_out": true|false, "checkout_reason": "", "base": "main"}
#
# `commit_hash` IS THE COMMIT THAT LANDED ON THE BASE, not the head of the work branch.
# It used to be `git rev-parse HEAD` — which is the branch head whenever the post-merge
# checkout is skipped, and skipping it is the NORMAL case (/drive ships every `auto` unit
# from a claim worktree while the primary tree pins `main`). Ship Flow step 7 feeds this
# field to publish-release.sh as the release target, and a release-on-tag project tags it,
# so the defect put release tags on commits that were not on the base's first-parent line.
# Observed on two consecutive ships, deterministically, each recovered by hand.
# It is harmless only while the branch's tree happens to equal the merged tree; once the
# base advances between the branch's last catch-up and the merge, the branch head's tree
# is not what landed, and a squash or rebase merge makes it not even an ancestor.
#
# HOW IT IS RESOLVED, and why the source is reported rather than assumed:
#   pr_merge_commit — GitHub's own answer (REST `GET .../pulls/{n}` -> `merge_commit_sha`;
#                     this was `gh pr view --json mergeCommit` until 2026-08-12). Correct for
#                     every merge strategy, including squash and rebase.
#   base_tip        — the fetched `origin/<base>` tip, when GitHub did not answer.
#                     Correct in the ordinary case and the honest name for its assumption.
#   branch_head     — neither was resolvable. The OLD value, reported under its own name
#                     so a caller can see it is not a merge commit instead of being told
#                     it is one.
# `on_base` is the check the caller would otherwise have to run itself
# (`git merge-base --is-ancestor <commit_hash> origin/<base>`), so a tag step can refuse
# a target this script could not place on the base line. `branch_head` is kept for any
# caller that genuinely wants the branch's last commit.
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

# Captured before the merge, while this checkout is still on the work branch.
branch_head=$(git rev-parse --short HEAD 2>/dev/null || true)

if ! command -v gh >/dev/null 2>&1; then
  echo '{"merged": false, "reason": "gh_unavailable", "pr_number": '"$pr_number"', "detail": "the GitHub CLI is not installed here; nothing was merged -- merge the pull request from an environment that has it"}' >&2
  exit 1
fi

# REST, NOT `gh pr merge` (2026-08-12, FB 20260812172522): the subcommand is
# GraphQL-backed and a Claude Code Web session may serve only the pinned PR-review
# operations. `merge_method: merge` reproduces `--merge` exactly, and REST never deletes
# the head branch, which is what `--delete-branch=false` was asking for.
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

slug=$(sh "${GATHER_SCRIPTS}/gh-rest.sh" slug 2>&1) || {
  echo '{"merged": false, "reason": "no_remote", "detail": "'"$(printf '%s' "$slug" | tr -d '"\\' | tr '\n' ' ')"'"}' >&2
  exit 1
}

if ! merge_out=$(sh "${GATHER_SCRIPTS}/gh-rest.sh" api \
    "repos/${slug}/pulls/${pr_number}/merge" --method PUT -f merge_method=merge 2>&1); then
  # The underlying message rides the error rather than being swallowed: a 405 (GitHub
  # refusing the merge) and a 403 (the transport being restricted) need different
  # actions from whoever reads this.
  echo '{"merged": false, "error": "merge failed", "detail": "'"$(printf '%s' "$merge_out" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"'"}' >&2
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

# Resolve the commit that actually landed on the base. Every step is best-effort:
# nothing below may fail the script, because the merge has already happened.
git fetch origin "$base" --quiet >/dev/null 2>&1 || true

commit_hash=""
commit_hash_source=""

# `GET .../pulls/{n}` reading `merge_commit_sha` — the REST equivalent of the
# `gh pr view --json mergeCommit` this replaces. The documented precedence below is
# unchanged: the PR's own merge commit first, the base tip only as a fallback.
resolved=$(sh "${GATHER_SCRIPTS}/gh-rest.sh" api "repos/${slug}/pulls/${pr_number}" \
  --jq '.merge_commit_sha // empty' 2>/dev/null || true)
if [ -n "$resolved" ] && [ "$resolved" != "null" ]; then
  commit_hash="$resolved"
  commit_hash_source="pr_merge_commit"
else
  resolved=$(git rev-parse "origin/${base}" 2>/dev/null || true)
  if [ -n "$resolved" ]; then
    commit_hash="$resolved"
    commit_hash_source="base_tip"
  fi
fi

if [ -z "$commit_hash" ]; then
  commit_hash="$branch_head"
  commit_hash_source="branch_head"
fi

# Abbreviate when the object is present locally; keep the full oid when it is not.
commit_hash=$(git rev-parse --short "$commit_hash" 2>/dev/null || printf '%s' "$commit_hash")

on_base=false
if git merge-base --is-ancestor "$commit_hash" "origin/${base}" >/dev/null 2>&1; then
  on_base=true
fi

cat <<EOF
{"merged": true, "pr_number": $pr_number, "commit_hash": "$commit_hash", "commit_hash_source": "$commit_hash_source", "on_base": $on_base, "branch_head": "$branch_head", "checked_out": $checked_out, "checkout_reason": "$checkout_reason", "base": "$base"}
EOF
