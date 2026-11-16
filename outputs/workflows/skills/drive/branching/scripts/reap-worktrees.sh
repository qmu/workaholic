#!/bin/sh -eu
# Reclaim every worktree that is provably finished with. DRY RUN BY DEFAULT.
#
#   reap-worktrees.sh [base-branch]              # report what WOULD be removed
#   reap-worktrees.sh --apply [base-branch]      # actually remove them
#
# Output (one JSON line):
#   {"applied": true|false, "base": "<base>",
#    "removed": [{"path","branch","size_bytes","branch_removed","branch_kept_reason"}],
#    "skipped": [{"path","branch","reason"}], "bytes_reclaimed": N, "human": "<n>",
#    "failed": [{"path","error"}]}
#
# WHY A SWEEP RATHER THAN MORE TEARDOWN CALLS. Teardown already exists three times over —
# `/ship` after a merge, `/drive` after an auto unit, `/mission-close` — and each is
# correct on its own. What they share is a precondition: SOMEBODY'S RUN HAS TO REACH THE
# END. A mission open for weeks keeps its desk the whole time; an interrupted run, a
# hand-driven branch, or a batch whose caller died is nobody's teardown. Measured when
# this was written: 53 GB held across four repositories, 31 GB of it fully merged and
# clean, one repository with 29 worktrees of which 22 were merged. A sweep does not
# replace those calls — it catches what they structurally cannot.
#
# THE SAFETY RULE IS `survey-worktrees.sh`'s `reclaimable`, AND THIS SCRIPT ADDS NONE OF
# ITS OWN. Merged (no commits the base lacks) AND clean (nothing uncommitted, tracked or
# untracked). One predicate, one implementation, one place to audit it — a reaper that
# re-derived the rule would be free to disagree with the reader that shows a human what
# is about to happen, and that disagreement is the whole failure mode worth preventing.
#
# EVERY SKIP IS NAMED. Six worktrees were correctly skipped in the incident above; a
# reaper that had silently taken them would have destroyed real work, and one that skips
# without saying why is indistinguishable from one that is broken.
#
# DRY RUN IS THE DEFAULT BECAUSE THE ACTION IS IRREVERSIBLE. A removed worktree is gone;
# its branch and commits survive (that is what "merged" means), but an unpushed anything
# would not — which is why "clean" is half the predicate rather than a nicety.
#
# THE LANDED BRANCH GOES WITH ITS WORKTREE (2026-09-26, issue #1279). Every merge is now a merge
# commit, so a landed unit's tip is an ancestor of `origin/<base>` and its worktree reads
# `merged: true` here. Under `--apply`, once the worktree is removed its local branch is removed
# too — only a `work-YYYYMMDD-HHMMSS` branch, only when its tip is an ancestor of the base at that
# moment, and only through `git update-ref -d <ref> <tip>` (never `git branch -D`), so the delete
# is spent on exactly the commit the proof was made about. Anything else keeps its branch and
# says why (`not_work_branch`, `not_ancestor`, `no_base`, `update_ref_refused`). The ~22 local
# branches squash-landed before this ruling are `prune-landed-branches.sh`'s business, not this
# sweep's. The remote is never touched.

set -eu

APPLY=false
if [ "${1:-}" = "--apply" ]; then APPLY=true; shift; fi
BASE="${1:-main}"

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

human() {
  b="$1"
  if [ "$b" -ge 1073741824 ]; then printf '%s.%sG' "$((b / 1073741824))" "$(((b % 1073741824) * 10 / 1073741824))"
  elif [ "$b" -ge 1048576 ]; then printf '%s.%sM' "$((b / 1048576))" "$(((b % 1048576) * 10 / 1048576))"
  elif [ "$b" -ge 1024 ]; then printf '%sK' "$((b / 1024))"
  else printf '%sB' "$b"; fi
}

# The current worktree cannot remove itself — git refuses, and a script that tried would
# be deleting the ground it stands on. Report it as a skip with a reason a caller can act
# on (run the sweep from the main checkout) rather than failing the whole run.
here=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

SURVEY=$(sh "${SCRIPT_DIR}/survey-worktrees.sh" "$BASE")

base_ref=""
if git rev-parse --verify --quiet "refs/remotes/origin/${BASE}" >/dev/null 2>&1; then
  base_ref="origin/${BASE}"
elif git rev-parse --verify --quiet "refs/heads/${BASE}" >/dev/null 2>&1; then
  base_ref="$BASE"
fi

# Remove a reaped worktree's landed local branch; prints `<removed>\t<kept_reason>`.
remove_landed_branch() {
  _b=$1
  case "$_b" in
    work-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) printf 'false\tnot_work_branch'; return 0 ;;
  esac
  _tip=$(git rev-parse --verify --quiet "refs/heads/${_b}^{commit}" 2>/dev/null || true)
  [ -n "$_tip" ] || { printf 'false\tabsent'; return 0; }
  [ -n "$base_ref" ] || { printf 'false\tno_base'; return 0; }
  git merge-base --is-ancestor "$_tip" "$base_ref" 2>/dev/null || { printf 'false\tnot_ancestor'; return 0; }
  if git update-ref -d "refs/heads/${_b}" "$_tip" >/dev/null 2>&1; then
    printf 'true\t'
  else
    printf 'false\tupdate_ref_refused'
  fi
}

removed=""; r_sep=""
skipped=""; s_sep=""
failed="";  f_sep=""
bytes=0

# One record per line: path<TAB>branch<TAB>size<TAB>reclaimable<TAB>skip_reason
records=$(printf '%s' "$SURVEY" | sed -e 's/^.*"worktrees": \[//' -e 's/\]}$//' \
  | sed -e 's/}, {/}\n{/g' \
  | sed -n 's/.*"path": "\([^"]*\)".*"branch": "\([^"]*\)".*"size_bytes": \([0-9]*\).*"reclaimable": \([a-z]*\).*"skip_reason": "\([^"]*\)".*/\1\t\2\t\3\t\4\t\5/p')

[ -n "$records" ] || {
  printf '{"applied": %s, "base": "%s", "removed": [], "skipped": [], "bytes_reclaimed": 0, "human": "0B", "failed": []}\n' "$APPLY" "$BASE"
  exit 0
}

OLDIFS=$IFS
IFS='
'
for rec in $records; do
  IFS=$OLDIFS
  path=$(printf '%s' "$rec" | cut -f1)
  branch=$(printf '%s' "$rec" | cut -f2)
  size=$(printf '%s' "$rec" | cut -f3)
  recl=$(printf '%s' "$rec" | cut -f4)
  reason=$(printf '%s' "$rec" | cut -f5)

  if [ "$recl" != "true" ]; then
    skipped="${skipped}${s_sep}{\"path\": \"${path}\", \"branch\": \"${branch}\", \"reason\": \"${reason}\"}"
    s_sep=", "
    IFS='
'
    continue
  fi

  if [ -n "$here" ] && [ "$path" = "$here" ]; then
    skipped="${skipped}${s_sep}{\"path\": \"${path}\", \"branch\": \"${branch}\", \"reason\": \"current_worktree\"}"
    s_sep=", "
    IFS='
'
    continue
  fi

  if [ "$APPLY" = "true" ]; then
    if git worktree remove "$path" >/dev/null 2>&1; then
      git worktree prune >/dev/null 2>&1 || true
      branch_out=$(remove_landed_branch "$branch")
      branch_removed=$(printf '%s' "$branch_out" | cut -f1)
      branch_kept=$(printf '%s' "$branch_out" | cut -f2)
      removed="${removed}${r_sep}{\"path\": \"${path}\", \"branch\": \"${branch}\", \"size_bytes\": ${size}, \"branch_removed\": ${branch_removed}, \"branch_kept_reason\": \"${branch_kept}\"}"
      r_sep=", "
      bytes=$((bytes + size))
    else
      failed="${failed}${f_sep}{\"path\": \"${path}\", \"error\": \"git worktree remove refused\"}"
      f_sep=", "
    fi
  else
    removed="${removed}${r_sep}{\"path\": \"${path}\", \"branch\": \"${branch}\", \"size_bytes\": ${size}}"
    r_sep=", "
    bytes=$((bytes + size))
  fi
  IFS='
'
done
IFS=$OLDIFS

printf '{"applied": %s, "base": "%s", "removed": [%s], "skipped": [%s], "bytes_reclaimed": %s, "human": "%s", "failed": [%s]}\n' \
  "$APPLY" "$BASE" "$removed" "$skipped" "$bytes" "$(human "$bytes")" "$failed"
