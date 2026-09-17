#!/bin/sh -eu
# A release names a committed change set, not a completed planning artifact.
# Usage: release-boundary.sh [base-ref]
# Eligibility establishes only a nonempty readable range. Authorization, branch
# checks, safety and target-specific production confirmation remain separate gates.
BASE=${1:-origin/main}
refusal() { jq -cn --arg reason "$1" '{eligible:false,reason:$reason}'; exit 0; }
base=$(git rev-parse --verify "$BASE^{commit}" 2>/dev/null) || refusal base_unreadable
head=$(git rev-parse --verify 'HEAD^{commit}' 2>/dev/null) || refusal head_unreadable
git merge-base "$base" "$head" >/dev/null 2>&1 || refusal range_unreadable
status=0
git diff --quiet "$base...$head" -- || status=$?
case "$status" in
  0) refusal no_changes;;
  1) jq -cn --arg base "$base" --arg head "$head" \
       '{eligible:true,reason:"committed_change_set",base:$base,head:$head}';;
  *) refusal range_unreadable;;
esac
