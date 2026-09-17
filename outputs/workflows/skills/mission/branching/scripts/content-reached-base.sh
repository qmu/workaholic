#!/bin/sh -eu
# Prove every authored patch is present in the base after a squash and branch deletion.
# No worktree write. Exit 0 only for a non-empty, wholly reversible patch on a scratch index.
[ "$#" -eq 2 ] || exit 2
tip=$1 base=$2
common=$(git merge-base "$tip" "$base" 2>/dev/null) || exit 1
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
git diff --binary "$common" "$tip" > "$scratch/change.patch" || exit 1
[ -s "$scratch/change.patch" ] || exit 1
GIT_INDEX_FILE="$scratch/index" git read-tree "$base" || exit 1
GIT_INDEX_FILE="$scratch/index" git apply --cached --reverse --check "$scratch/change.patch" >/dev/null 2>&1
