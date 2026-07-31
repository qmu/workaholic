#!/bin/sh -eu
# Commit what the caller wrote into the publish tree and LAND IT ON A work-*
# BRANCH BEHIND A PULL REQUEST — the standard path for every workaholic artifact
# (feedback, mission, ticket).
#
#   publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]
#
# The positional arguments are commit.sh's, forwarded verbatim: this script owns
# the branch, the push, and the pull request, not the message. The base branch is
# `main` unless WORKAHOLIC_PUBLISH_BASE names another.
#
# Output (stdout, exit 0 for a reported outcome):
#   {"ok": true,  "sha": "<sha>", "branch": "work-…", "pr_url": "<url>", "base": "<base>"}
#   {"ok": false, "reason": "no_publish_tree"|"nothing_to_commit"|"commit_failed"
#                          |"branch_collision"|"push_failed"|"no_gh"|"pr_failed", ...}
#
# WHY THIS EXISTS ALONGSIDE publish-tree-commit.sh. Both write through the same
# isolated `.publish/` checkout, so the caller's branch, staged set, untracked
# set, and file contents are left byte-identical either way — that property is
# the whole reason the publish tree exists and it is unchanged here. What differs
# is the destination: `publish-tree-commit.sh` lands the commit directly on the
# base, this one lands it on a branch and opens a PR. The project standard is
# that every artifact reaches the base through a MERGED pull request, because the
# merge is the event that can be announced; a commit pushed straight to the base
# produces no such event. Direct-to-base publication remains available for the
# seams that are already downstream of a merge (concern extraction at ship time),
# where a second PR would be circular.
#
# THE REMOTE BRANCH IS work-*, THE LOCAL BRANCH IS STILL publish-main.
# `git push origin publish-main:work-YYYYMMDD-HHMMSS` creates the remote branch
# under the claim vocabulary's name while the local publish branch never leaves
# the machine. That is safe for the claim protocol precisely because the claim
# scan does not key on the NAME: it reads a `Claim <unit-id>` commit subject in
# the branch's unmerged range, and a publication branch carries none, so the scan
# skips it. A publication branch is therefore invisible as a claim while being an
# ordinary reviewable branch to everything else.
#
# A COLLISION IS REPORTED, NEVER RESOLVED BY OVERWRITING. Two publications in the
# same second would otherwise force-share a branch and one would silently lose
# its commit. The commit stays intact in the publish tree, and the next call —
# one second later — succeeds.
#
# A FAILED PULL REQUEST IS NOT A FAILED PUBLICATION, AND IS NOT REPORTED AS A
# SUCCESS EITHER. If the push landed but `gh` could not open the PR, the artifact
# IS on the remote branch and is recoverable; `ok` is false with `reason:
# "pr_failed"`, and both `branch` and `sha` are reported so the caller can open
# the PR by hand rather than re-publishing and duplicating the artifact.

set -eu

base="${WORKAHOLIC_PUBLISH_BASE:-main}"
PUBLISH_BRANCH="publish-main"

if [ "$#" -lt 6 ]; then
  echo 'Usage: publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]' >&2
  exit 1
fi

TITLE="$1"
WHY="$2"

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
publish_path="${repo_root}/.publish"

if ! git worktree list --porcelain | grep -q "^worktree ${publish_path}$"; then
  printf '{"ok": false, "reason": "no_publish_tree", "path": "%s", "detail": "run open-publish-tree.sh first"}\n' "$publish_path"
  exit 0
fi

before_sha="$(git -C "$publish_path" rev-parse HEAD)"

# --- 1. Commit through the shared wrapper ------------------------------------
if ( cd "$publish_path" && sh "${SCRIPT_DIR}/../../commit/scripts//commit.sh" "$@" ) >&2; then
  :
else
  printf '{"ok": false, "reason": "commit_failed", "path": "%s"}\n' "$publish_path"
  exit 0
fi

after_sha="$(git -C "$publish_path" rev-parse HEAD)"
if [ "$before_sha" = "$after_sha" ]; then
  # commit.sh exits 0 on "nothing staged". Reporting ok:true here would hand back
  # a sha that predates the caller's write — a publication that never happened,
  # reported as one that did.
  printf '{"ok": false, "reason": "nothing_to_commit", "path": "%s", "detail": "commit.sh staged nothing; nothing was published"}\n' "$publish_path"
  exit 0
fi

# --- 2. Mint the publication branch ------------------------------------------
work_branch="work-$(date +%Y%m%d-%H%M%S)"

if git -C "$publish_path" ls-remote --exit-code --heads origin "$work_branch" >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "branch_collision", "branch": "%s", "sha": "%s", "path": "%s", "detail": "a remote branch of that name already exists; the commit is intact in the publish tree and the next call succeeds"}\n' \
    "$work_branch" "$after_sha" "$publish_path"
  exit 0
fi

# --- 3. Push the commit onto the publication branch --------------------------
# No rebase-and-retry here, and none is needed: the destination is a BRAND NEW
# branch, so there is nothing to be non-fast-forward against. (publish-tree-commit.sh
# needs the retry because it pushes onto a shared base another runner may have
# advanced.) Reconciling with the base is the pull request's job.
if git -C "$publish_path" push --quiet origin "${PUBLISH_BRANCH}:refs/heads/${work_branch}" >&2; then
  :
else
  printf '{"ok": false, "reason": "push_failed", "branch": "%s", "sha": "%s", "path": "%s", "detail": "the commit is intact in the publish tree"}\n' \
    "$work_branch" "$after_sha" "$publish_path"
  exit 0
fi

# --- 4. Open the pull request ------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "no_gh", "branch": "%s", "sha": "%s", "base": "%s", "detail": "the artifact IS pushed to the branch; open the pull request by hand"}\n' \
    "$work_branch" "$after_sha" "$base"
  exit 0
fi

body_file=$(mktemp "${TMPDIR:-/tmp}/workaholic-publish-pr.XXXXXX")
trap 'rm -f "$body_file"' EXIT
{
  printf '## Overview\n\n%s\n\n' "$WHY"
  printf '## Artifacts\n\n'
  git -C "$publish_path" show --stat --oneline --name-only --format='' HEAD | sed -e '/^$/d' -e 's/^/- `/' -e 's/$/`/'
  printf '\n## Notes\n\nPublished from the publish tree, so the caller'"'"'s checkout was never touched. Merging this pull request is what lands the artifact on `%s`.\n' "$base"
} > "$body_file"

pr_url=$(git -C "$publish_path" rev-parse --show-toplevel >/dev/null 2>&1 && \
  ( cd "$publish_path" && gh pr create --base "$base" --head "$work_branch" --title "$TITLE" --body-file "$body_file" 2>/dev/null ) || true)

if [ -z "$pr_url" ]; then
  printf '{"ok": false, "reason": "pr_failed", "branch": "%s", "sha": "%s", "base": "%s", "detail": "the artifact IS pushed to the branch; open the pull request by hand rather than re-publishing"}\n' \
    "$work_branch" "$after_sha" "$base"
  exit 0
fi

printf '{"ok": true, "sha": "%s", "branch": "%s", "pr_url": "%s", "base": "%s"}\n' \
  "$after_sha" "$work_branch" "$pr_url" "$base"
