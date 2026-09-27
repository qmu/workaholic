#!/bin/sh -eu
# Name every local `work-*` branch and remove only the ones PROVED landed. DRY RUN BY DEFAULT.
#
#   prune-landed-branches.sh [--apply] [base-branch]      # base defaults to main
#
# Output (one JSON line):
#   {"applied": bool, "base": "<ref>", "removed": [{"branch","tip","proof"}],
#    "kept": [{"branch","tip","reason"}], "failed": [{"branch","error"}]}
#
# WHY IT EXISTS (2026-09-26, issue #1279, mission
# `merge-pull-requests-so-landed-branches-read-as-merged`). The developer saw ~22 local `work-*`
# branches and asked whether they were a problem: every one had landed, but under the retired
# squash ruling a landed branch is never an ancestor of the base, so it LOOKED unfinished and
# nothing removed it. Every merge is now a merge commit (`gather/scripts/merge-method.sh`), so a
# newly landed branch's tip is an ancestor of the base; the ones squash-landed before that stay
# non-ancestors forever, because history is not rewritten.
#
# TWO PROOFS, IN THIS ORDER, AND NOTHING ELSE REMOVES A BRANCH:
#
#   ancestor         the tip is an ancestor of `origin/<base>` — every commit on it is on the base
#   content_landed   `content-reached-base.sh <tip> <base>` exits 0 — the branch's whole authored
#                    patch reverse-applies on the base's tree, i.e. a squash already carried it
#
# EVERY OTHER BRANCH IS KEPT AND NAMED, never guessed about:
#
#   checked_out      a worktree (or the main checkout) has it checked out; removing the branch
#                    under a worktree is the reaper's business, after it removes the worktree
#   not_landed       neither proof holds — the branch carries work the base does not
#   no_base          no `origin/<base>` (or local `<base>`) to prove against
#
# THE REMOVAL IS `git update-ref -d <ref> <tip>`, NEVER `git branch -D`. `-D` deletes whatever the
# ref points at; `update-ref` with the old value deletes exactly the tip the proof was made about
# and refuses if the ref moved in between, so a proof can never be spent on a different commit.
# (`git branch -d` would do, except that it checks merged-ness against the CURRENT HEAD, which in
# a main checkout parked behind `origin/<base>` refuses a branch that is provably landed.)
# Only `refs/heads/work-YYYYMMDD-HHMMSS` is ever touched; the remote is never touched (the claim
# oracle reads remote branches, and `delete_branch_on_merge` removes those at the merge).

set -eu

APPLY=false
if [ "${1:-}" = "--apply" ]; then APPLY=true; shift; fi
BASE="${1:-main}"

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

base_ref=""
if git rev-parse --verify --quiet "refs/remotes/origin/${BASE}" >/dev/null 2>&1; then
  base_ref="origin/${BASE}"
elif git rev-parse --verify --quiet "refs/heads/${BASE}" >/dev/null 2>&1; then
  base_ref="$BASE"
fi

checked_out=$(git worktree list --porcelain 2>/dev/null | sed -n 's#^branch refs/heads/##p')

removed=""; r_sep=""
kept="";    k_sep=""
failed="";  f_sep=""

for branch in $(git for-each-ref --format='%(refname:short)' 'refs/heads/work-*'); do
  case "$branch" in
    work-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) continue ;;
  esac
  tip=$(git rev-parse --verify --quiet "refs/heads/${branch}^{commit}" 2>/dev/null || true)
  [ -n "$tip" ] || continue

  reason=""; proof=""
  if printf '%s\n' "$checked_out" | grep -qx "$branch"; then
    reason="checked_out"
  elif [ -z "$base_ref" ]; then
    reason="no_base"
  elif git merge-base --is-ancestor "$tip" "$base_ref" 2>/dev/null; then
    proof="ancestor"
  elif sh "${SCRIPT_DIR}/content-reached-base.sh" "$tip" "$base_ref" >/dev/null 2>&1; then
    proof="content_landed"
  else
    reason="not_landed"
  fi

  if [ -n "$reason" ]; then
    kept="${kept}${k_sep}{\"branch\": \"${branch}\", \"tip\": \"${tip}\", \"reason\": \"${reason}\"}"
    k_sep=", "
    continue
  fi

  if [ "$APPLY" = true ]; then
    if git update-ref -d "refs/heads/${branch}" "$tip" >/dev/null 2>&1; then
      removed="${removed}${r_sep}{\"branch\": \"${branch}\", \"tip\": \"${tip}\", \"proof\": \"${proof}\"}"
      r_sep=", "
    else
      failed="${failed}${f_sep}{\"branch\": \"${branch}\", \"error\": \"update_ref_refused\"}"
      f_sep=", "
    fi
  else
    removed="${removed}${r_sep}{\"branch\": \"${branch}\", \"tip\": \"${tip}\", \"proof\": \"${proof}\"}"
    r_sep=", "
  fi
done

printf '{"applied": %s, "base": "%s", "removed": [%s], "kept": [%s], "failed": [%s]}\n' \
  "$APPLY" "$base_ref" "$removed" "$kept" "$failed"
