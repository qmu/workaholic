#!/bin/sh -eu
# Clear a unit's carried finish line once it has actually been sent.
#
# Usage: clear-unposted-line.sh <unit-id>
# Output: {"cleared": bool, "unit": "...", "branch": "...", "reason": ""}
#         Always exit 0 — a failed clear is an answer the caller reports; it never turns a landed
#         post into a failure.
#
# WHY IT EXISTS (2026-09-03, mission `deliver-a-post-the-transport-refused-or-say-it-reached-nobody`).
# A duplicate post is the loud failure here and a lost one the quiet failure. The record is what
# makes the re-send possible and it is also what would make it happen again next tick, so the
# landed send has to remove it — and the tree is the only store, so removing it is a commit.
#
# IT IS THE SECOND HALF OF ONE ACT AND NEVER A STANDALONE EDIT. Call it only immediately after a
# send that landed; a refused re-send leaves the record standing, which is the whole point of
# carrying it. Nothing else calls it.
#
# NO WORKTREE, NO CHECKOUT, NO INDEX OF THE CALLER'S IS TOUCHED — the same plumbing sequence
# `retry-undelivered.sh` uses to record a merge outcome back onto a branch, for the same reason:
# the run is standing somewhere else entirely, and attaching a worktree to delete four lines is a
# cost with no purchase.
#
# IT IS THIS IDENTITY'S OWN CLAIM ONLY. The bound is the oracle's — `foreign_identity` and
# `identity_unresolved` are verdicts, and pushing into a colleague's claim branch is the one act
# the claim protocol forbids outright.
#
# IT IS IDEMPOTENT. A branch already carrying no record answers `cleared: true` with reason
# `already_clear` and writes nothing, so a re-run costs one blob read.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

LISTER="${SCRIPT_DIR}/list-claims.sh"
RECORDER="${SCRIPT_DIR}/../../story/scripts//record-unposted-line.sh"

UNIT="${1:-}"
BRANCH=""

emit() {
    printf '{"cleared": %s, "unit": "%s", "branch": "%s", "reason": "%s"}\n' \
        "$1" "$UNIT" "$BRANCH" "${2:-}"
    exit 0
}

[ -n "$UNIT" ] || emit false no_unit_argument
[ -f "$LISTER" ] || emit false no_claim_reader
[ -f "$RECORDER" ] || emit false no_recorder

out=$(sh "$LISTER" 2>/dev/null || true)
[ -n "$out" ] || emit false claims_unreadable
printf '%s' "$out" | jq -e . >/dev/null 2>&1 || emit false claims_unparseable
[ "$(printf '%s' "$out" | jq -r '.fetched // false')" = "true" ] || emit false origin_unreachable

verdict=$(printf '%s' "$out" | jq -r --arg u "$UNIT" \
    '[.claims[]? | select(.unit == $u) | .resume_reason] | first // ""' 2>/dev/null || printf '')
BRANCH=$(printf '%s' "$out" | jq -r --arg u "$UNIT" \
    '[.claims[]? | select(.unit == $u) | .branch] | first // ""' 2>/dev/null || printf '')

[ -n "$BRANCH" ] || emit false no_claim_for_unit
case "$verdict" in
    foreign_identity ) emit false foreign_identity ;;
    identity_unresolved ) emit false identity_unresolved ;;
esac

story_path=".workaholic/stories/${BRANCH}.md"
tmp=$(mktemp -d 2>/dev/null || printf '')
[ -n "$tmp" ] || emit false no_tmpdir
trap 'rm -rf "$tmp"' EXIT INT TERM

git cat-file blob "origin/${BRANCH}:${story_path}" >"${tmp}/story.md" 2>/dev/null \
    || emit false no_story_blob

rec=$(sh "$RECORDER" --clear "${tmp}/story.md" 2>/dev/null || true)
printf '%s' "$rec" | grep -q '"recorded": true' || emit false clear_refused
printf '%s' "$rec" | grep -q '"changed": true' || emit true already_clear

blob=$(git hash-object -w "${tmp}/story.md" 2>/dev/null || true)
[ -n "$blob" ] || emit false blob_write_failed

GIT_INDEX_FILE="${tmp}/index"
export GIT_INDEX_FILE
git read-tree "origin/${BRANCH}" 2>/dev/null || emit false read_tree_failed
git update-index --add --cacheinfo "100644,${blob},${story_path}" 2>/dev/null \
    || emit false update_index_failed
tree=$(git write-tree 2>/dev/null || true)
unset GIT_INDEX_FILE
[ -n "$tree" ] || emit false write_tree_failed

commit=$(git commit-tree "$tree" -p "origin/${BRANCH}" -m "Clear the carried finish line" 2>/dev/null || true)
[ -n "$commit" ] || emit false commit_tree_failed

git push --quiet origin "${commit}:refs/heads/${BRANCH}" >/dev/null 2>&1 || emit false push_failed

emit true ""
