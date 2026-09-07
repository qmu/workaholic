#!/bin/sh -eu
# Report EVERY worktree with its cost and whether it is reclaimable. Pure read.
#
#   survey-worktrees.sh [base-branch]        # base defaults to main
#
# Output (one JSON line):
#   {"base": "<base>", "count": N, "total_bytes": N, "reclaimable_bytes": N,
#    "worktrees": [{"path","branch","size_bytes","size_human","ahead","dirty",
#                   "merged","publication_transaction","transaction","transaction_phase",
#                   "reclaimable","skip_reason"}]}
#
# WHY THIS EXISTS. Worktrees were created silently and their cost never appeared in any
# output, so growth stayed invisible until a disk filled: 53 GB across four repositories,
# 31 GB of it fully merged and clean, one repository holding 29 worktrees. Nothing in the
# workflow reported a single byte of that. `workaholic:implementation` / objective-
# documentation is the policy — the cost is an observable fact, not something a developer
# should have to discover with `du`.
#
# THE RECLAIMABLE PREDICATE IS TWO CONDITIONS, AND BOTH ARE REQUIRED:
#
#   merged  — the branch has no commits the base lacks (`ahead == 0`)
#   clean   — the working tree has nothing uncommitted, tracked or untracked
#
# Either alone is not enough, and this is not a theoretical concern: in the incident that
# produced this script six worktrees were correctly skipped on exactly these grounds, and
# a reaper applying one condition would have destroyed real work. `skip_reason` names
# which condition failed (`unmerged`, `dirty`, `unmerged_and_dirty`) so a skip is never
# silent — an unexplained skip is indistinguishable from a bug.
#
# UNTRACKED FILES COUNT AS DIRTY. A half-written artifact from an interrupted run is
# untracked by definition, and it is precisely the state worth protecting.
#
# AN OPEN PUBLICATION TRANSACTION IS NEVER RECLAIMABLE. Its clean checkout may point at
# the base before the agent writes, or at an already-merged commit before `close`; either
# state satisfies the ordinary merged-and-clean predicate while the durable manifest still
# owns the checkout. The survey reads that manifest so the reaper cannot race recovery.
#
# THE MAIN TREE AND THE PUBLISH TREE ARE NEVER LISTED. The main tree is not a worktree
# anyone reclaims, and `.publish/` is disposable but belongs to the publish lifecycle
# (`open-publish-tree.sh` refuses a dirty one, `close-publish-tree.sh` removes it) — a
# reaper reaching into it would race that lifecycle for no gain.

set -eu

BASE="${1:-main}"

# THE MAIN TREE IS THE FIRST RECORD OF `git worktree list`, AND IT MUST BE FOUND THAT WAY.
# `git rev-parse --show-toplevel` answers "the tree I am standing in" — so when this runs
# from inside a linked worktree (which is exactly where /drive runs it) it returns THAT
# worktree. Using it as the main-tree guard both excluded the current worktree from the
# survey and reported the MAIN CHECKOUT as reclaimable. A reaper acting on that output
# would have removed the developer's primary tree. Caught by the first smoke run against
# a real repository; the fixture tests below pin it so it cannot come back.
main_root="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"
publish_path="${main_root}/.publish"
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
publication_dir="${common_dir}/workaholic/runtime/v1/publications"

publication_for_path() {
  _survey_path=$1
  [ -d "$publication_dir" ] || return 0
  for _survey_manifest in "$publication_dir"/*/meta.json; do
    [ -f "$_survey_manifest" ] || continue
    _survey_manifest_path=$(jq -r '.data.path // empty' "$_survey_manifest" 2>/dev/null || true)
    [ "$_survey_manifest_path" = "$_survey_path" ] || continue
    _survey_phase=$(jq -r '.data.phase // "unknown"' "$_survey_manifest" 2>/dev/null || printf unknown)
    [ "$_survey_phase" = closed ] && continue
    _survey_id=$(basename -- "$(dirname -- "$_survey_manifest")")
    printf '%s\t%s\n' "$_survey_id" "$_survey_phase"
    return 0
  done
}

# Resolve the base once. origin/<base> is preferred — "merged" must mean merged into what
# everyone else sees, not into a local branch that may itself be unpushed.
base_ref=""
if git rev-parse --verify --quiet "refs/remotes/origin/${BASE}" >/dev/null 2>&1; then
  base_ref="origin/${BASE}"
elif git rev-parse --verify --quiet "refs/heads/${BASE}" >/dev/null 2>&1; then
  base_ref="$BASE"
fi

human() {
  # Bytes to a short human string, without bc or numfmt (neither is guaranteed).
  b="$1"
  if [ "$b" -ge 1073741824 ]; then printf '%s.%sG' "$((b / 1073741824))" "$(((b % 1073741824) * 10 / 1073741824))"
  elif [ "$b" -ge 1048576 ]; then printf '%s.%sM' "$((b / 1048576))" "$(((b % 1048576) * 10 / 1048576))"
  elif [ "$b" -ge 1024 ]; then printf '%sK' "$((b / 1024))"
  else printf '%sB' "$b"; fi
}

entries=""
sep=""
count=0
total=0
reclaimable_total=0

current_path=""
current_branch=""

emit_record() {
  [ -n "$current_path" ] || return 0
  [ "$current_path" != "$main_root" ] || return 0
  [ "$current_path" != "$publish_path" ] || return 0
  [ -d "$current_path" ] || return 0

  # du reports disk usage in KiB with -k; that is the number that matters for a disk-full
  # incident (apparent size would understate a checkout with many small files).
  size_kb=$(du -sk "$current_path" 2>/dev/null | awk '{print $1}')
  [ -n "$size_kb" ] || size_kb=0
  size_bytes=$((size_kb * 1024))

  ahead=0
  if [ -n "$base_ref" ] && [ -n "$current_branch" ]; then
    ahead=$(git rev-list --count "${base_ref}..refs/heads/${current_branch}" 2>/dev/null || echo 0)
  fi

  dirty=false
  if [ -n "$(git -C "$current_path" status --porcelain 2>/dev/null)" ]; then dirty=true; fi

  merged=false
  if [ "$ahead" -eq 0 ] && [ -n "$base_ref" ]; then merged=true; fi

  publication_transaction=false
  transaction=""
  transaction_phase=""
  publication_record=$(publication_for_path "$current_path")
  if [ -n "$publication_record" ]; then
    publication_transaction=true
    transaction=$(printf '%s' "$publication_record" | cut -f1)
    transaction_phase=$(printf '%s' "$publication_record" | cut -f2)
  fi

  reclaimable=false
  skip=""
  if [ "$publication_transaction" = "true" ]; then
    skip="publication_transaction"
  elif [ "$merged" = "true" ] && [ "$dirty" = "false" ]; then
    reclaimable=true
  elif [ "$merged" = "false" ] && [ "$dirty" = "true" ]; then
    skip="unmerged_and_dirty"
  elif [ "$merged" = "false" ]; then
    skip="unmerged"
  else
    skip="dirty"
  fi

  # No base resolved at all: report it rather than claiming everything is unmerged.
  if [ -z "$base_ref" ]; then skip="base_unresolved"; reclaimable=false; fi

  if [ "$reclaimable" = "true" ]; then
    reclaimable_total=$((reclaimable_total + size_bytes))
  fi
  total=$((total + size_bytes))
  count=$((count + 1))

  entries="${entries}${sep}{\"path\": \"${current_path}\", \"branch\": \"${current_branch}\", \"size_bytes\": ${size_bytes}, \"size_human\": \"$(human "$size_bytes")\", \"ahead\": ${ahead}, \"dirty\": ${dirty}, \"merged\": ${merged}, \"publication_transaction\": ${publication_transaction}, \"transaction\": \"${transaction}\", \"transaction_phase\": \"${transaction_phase}\", \"reclaimable\": ${reclaimable}, \"skip_reason\": \"${skip}\"}"
  sep=", "
}

wt_list="$(git worktree list --porcelain)"
while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      emit_record
      current_path="${line#worktree }"
      current_branch=""
      ;;
    "branch refs/heads/"*)
      current_branch="${line#branch refs/heads/}"
      ;;
  esac
done <<EOF
$wt_list
EOF
emit_record

printf '{"base": "%s", "count": %s, "total_bytes": %s, "total_human": "%s", "reclaimable_bytes": %s, "reclaimable_human": "%s", "worktrees": [%s]}\n' \
  "$BASE" "$count" "$total" "$(human "$total")" "$reclaimable_total" "$(human "$reclaimable_total")" "$entries"
