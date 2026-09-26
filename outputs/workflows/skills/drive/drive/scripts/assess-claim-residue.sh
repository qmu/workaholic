#!/bin/sh -eu
# Read-only assessment. A clean synthetic merge compares effects, not ancestry:
# squash-delivered changes are not called unique merely because merge-base is old.
# Usage: assess-claim-residue.sh <branch> [base-ref] [head-ref]
branch=${1:?branch required}
base=${2:-${WORKAHOLIC_BASE_REF:-origin/main}}
head=${3:-origin/$branch}
base_sha=$(git rev-parse --verify "$base^{commit}" 2>/dev/null || true)
head_sha=$(git rev-parse --verify "$head^{commit}" 2>/dev/null || true)
state=unknown; reason=ref_unreadable; tree=''; paths='[]'
if [ -n "$base_sha" ] && [ -n "$head_sha" ]; then
    if merged=$(git merge-tree --write-tree "$base_sha" "$head_sha" 2>/dev/null); then
        tree=$(printf '%s\n' "$merged" | head -n 1)
        if names=$(git diff --name-only "$base_sha" "$tree" -- . ':(exclude).workaholic' 2>/dev/null); then
            paths=$(printf '%s\n' "$names" | jq -Rsc 'split("\n") | map(select(length > 0))')
            if [ "$paths" = '[]' ]; then state=landed; reason=tree_effect_present
            else state=pending; reason=review_required; fi
        else reason=diff_unreadable; fi
    else reason=content_conflict_or_merge_unreadable; fi
fi
jq -cn --arg branch "$branch" --arg head "$head_sha" --arg base "$base_sha" \
    --arg state "$state" --arg reason "$reason" --arg tree "$tree" --argjson paths "$paths" \
    '{branch:$branch,head:$head,base:$base,state:$state,reason:$reason,tree:$tree,paths:$paths,
      delivery_claim:"assessment_only_not_a_retirement_proof"}'
