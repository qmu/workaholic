#!/bin/sh -eu
# Cut a release/* staging branch from the base at promotion time (decision L1/L2).
#
# A release branch is the QA window between "merged onto the base" and "released to
# production". It is cut FROM the base, so it can only exist after the units it carries
# have merged — it is never a step of a per-unit ship, and cutting one changes nothing
# about how a unit lands.
#
# THE BRANCH CARRIES NO COMMITS OF ITS OWN. It is exactly a pointer at a base commit, and
# that is load-bearing: "which base commits did this release carry" stays answerable by
# `git log <previous>..<release tip>` forever. The durable record lives on the base
# (.workaholic/releases/), written by the ship skill, not here.
#
# It NEVER checks the branch out. Promotion runs over the base from whatever checkout the
# caller is standing in, and a cut that moved HEAD would make a batch-level act disturb an
# unrelated working tree.
#
# The name is minted here, from a timestamp, exactly as create.sh mints a work-* name —
# `release/YYYYMMDD-HHMMSS`, the second literal pattern hooks/guard-git-branch.sh permits.
# Never name a release branch yourself.
#
# Usage: cut-release-branch.sh [base]        (base defaults to main)
# Output: JSON {ok, branch, base, sha, pushed} or {ok:false, reason}
#   reason: no_origin | origin_unreachable | base_unresolved | branch_collision
#         | branch_creation_failed | push_failed
#
# Reported outcomes ride stdout with exit 0 (the publish-tree convention): the callers are
# command/skill markdown that cannot branch on an exit code. Genuine misuse — not a git
# repository — still exits non-zero.

set -eu

BASE="${1:-main}"

fail() {
  printf '{"ok": false, "reason": "%s"}\n' "$1"
  exit 0
}

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo '{"ok": false, "reason": "not_a_git_repo"}' >&2
  exit 1
fi

# The writer fails loudly with no origin, the same stance claim.sh takes: a release
# window nobody else can see is not a window.
if ! git remote get-url origin >/dev/null 2>&1; then
  fail no_origin
fi

if ! git fetch --quiet origin "$BASE" >/dev/null 2>&1; then
  fail origin_unreachable
fi

SHA=$(git rev-parse --verify --quiet "refs/remotes/origin/${BASE}" || true)
if [ -z "$SHA" ]; then
  fail base_unresolved
fi

BRANCH="release/$(date +%Y%m%d-%H%M%S)"

# A collision is reported, never resolved by overwriting — two promotions in the same
# second would otherwise force-share a name and one release's identity would be lost. The
# next call, one second later, succeeds.
if git rev-parse --verify --quiet "refs/heads/${BRANCH}" >/dev/null 2>&1; then
  fail branch_collision
fi
if git rev-parse --verify --quiet "refs/remotes/origin/${BRANCH}" >/dev/null 2>&1; then
  fail branch_collision
fi

if ! git branch "$BRANCH" "$SHA" >/dev/null 2>&1; then
  fail branch_creation_failed
fi

if ! git push --quiet origin "refs/heads/${BRANCH}:refs/heads/${BRANCH}" >/dev/null 2>&1; then
  # Roll the local ref back: a branch only this machine can see would read as a live
  # release window to this runner and to nobody else.
  git branch -D "$BRANCH" >/dev/null 2>&1 || true
  fail push_failed
fi

printf '{"ok": true, "branch": "%s", "base": "%s", "sha": "%s", "pushed": true}\n' \
  "$BRANCH" "$BASE" "$SHA"
