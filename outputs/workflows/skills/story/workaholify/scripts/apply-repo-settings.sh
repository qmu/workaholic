#!/bin/sh -eu
# Turn on the one remote setting a workaholic mechanism depends on: delete the branch when
# its pull request merges.
#
#   apply-repo-settings.sh [remote]
#
# Output (one JSON line):
#   {"changed", "applied": [...], "refused", "ok", "problems_before", "problems_after",
#    "residue": {...}}
#
# WHAT IT IS FOR: see `check-repo-settings.sh`'s header — the claim oracle is "unmerged
# remote branches", so a repository that never deletes a merged branch hands that oracle a
# growing population of merged-but-undeleted branches, which a shallow clone cannot tell
# from live claims.
#
# THE CHECK IS COMPOSED, NEVER REIMPLEMENTED — conformance is read from
# `check-repo-settings.sh` before and after, so the apply cannot disagree with the audit that
# motivated it, and a conforming repository is `changed: false` with no request sent at all.
# That is the shape `apply-claude-md-reference.sh` and `apply-bootstrap.sh` already have.
#
# IT REFUSES RATHER THAN HALF-WRITES. `not_admin` is its own refusal and is checked BEFORE
# the request: only an admin may PATCH a repository, so a push-only collaborator would spend
# a round trip to be told 403, and the operator needs to be told *who* can fix this rather
# than that something failed. Every unanswerable reading of the check refuses under the
# check's own word (`refused: unanswerable:<reason>`); none of them is rendered as applied.
#
# IT TOUCHES ONE FIELD. The PATCH body carries `delete_branch_on_merge` and nothing else, so
# a repository's merge-method settings, description, topics and visibility are untouched —
# the request cannot become a house-style sweep by accident.
#
# THE RESIDUE IS REPORTED, NEVER SWEPT. Turning the setting on is forward-only: the branches
# already standing stay standing, and they are the ones currently in the oracle's way. The
# count and the ready-to-run deletion ride through from the check; which of a team's branches
# may vanish is a judgment about somebody's work in progress, so it stays the operator's act.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CHECK="${SCRIPT_DIR}/check-repo-settings.sh"
GH_REST="${SCRIPT_DIR}/../../gather/scripts//gh-rest.sh"

REMOTE="${1:-origin}"

before=$(sh "$CHECK" "$REMOTE" 2>/dev/null || printf '')
[ -n "$before" ] || before='{"ok": false, "state": "unanswerable", "reason": "check_failed", "problems": [], "residue": {"readable": false, "reason": "not_read"}}'

residue=$(printf '%s' "$before" | jq -c '.residue // {"readable": false, "reason": "not_read"}' 2>/dev/null || printf '{"readable": false, "reason": "not_read"}')
problems_before=$(printf '%s' "$before" | jq -c '.problems // []' 2>/dev/null || printf '[]')
state=$(printf '%s' "$before" | jq -r '.state // "unanswerable"' 2>/dev/null || printf 'unanswerable')
reason=$(printf '%s' "$before" | jq -r '.reason // ""' 2>/dev/null || printf '')
slug=$(printf '%s' "$before" | jq -r '.slug // ""' 2>/dev/null || printf '')
admin=$(printf '%s' "$before" | jq -r '.admin | tostring' 2>/dev/null || printf 'null')

# $1 changed, $2 applied (JSON array), $3 refused, $4 problems_after (JSON array)
emit() {
    printf '{"changed": %s, "applied": %s, "refused": "%s", "ok": %s, "problems_before": %s, "problems_after": %s, "residue": %s}\n' \
        "$1" "$2" "${3:-}" "$(if [ "$4" = "[]" ] && [ -z "${3:-}" ]; then echo true; else echo false; fi)" \
        "$problems_before" "$4" "$residue"
    exit 0
}

case "$state" in
    unanswerable) emit false '[]' "unanswerable:${reason}" '[]' ;;
    conforming)   emit false '[]' '' '[]' ;;
esac

[ "$admin" = "true" ] || emit false '[]' not_admin "$problems_before"
[ -f "$GH_REST" ] || emit false '[]' no_transport_script "$problems_before"

if ! sh "$GH_REST" api --method PATCH "repos/${slug}" \
        -F delete_branch_on_merge=true >/dev/null 2>&1; then
    emit false '[]' patch_failed "$problems_before"
fi

after=$(sh "$CHECK" "$REMOTE" 2>/dev/null || printf '')
[ -n "$after" ] || after='{"problems": []}'
problems_after=$(printf '%s' "$after" | jq -c '.problems // []' 2>/dev/null || printf '[]')
residue=$(printf '%s' "$after" | jq -c '.residue // '"$residue" 2>/dev/null || printf '%s' "$residue")

emit true '["delete_branch_on_merge"]' '' "$problems_after"
