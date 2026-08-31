#!/bin/sh -eu
# Does the GitHub repository delete a branch when its pull request merges? Pure read.
#
#   check-repo-settings.sh [remote]
#
# Output (one JSON line):
#   {"ok", "slug", "state": "conforming|nonconforming|unanswerable", "reason",
#    "settings": {"delete_branch_on_merge": bool|null},
#    "admin": bool|null,
#    "problems": [...],
#    "residue": {"readable", "reason", "merged_undeleted", "sample": [...], "command"}}
#
#   ok     false exactly when `state` is `unanswerable` — a reading we could not make,
#          which is never rendered as a repository that is already correct.
#
# WHY A REMOTE SETTING IS PART OF WIRING A REPOSITORY TO THE STANDARDS. The claim protocol
# has no lock file and no server: **unmerged remote branches are the only claim oracle**
# (`drive/reference/claims.md`). "Unmerged" is `git rev-list --count base..ref`, and that
# range is only reducible when the merge base is inside the clone. In a SHALLOW clone it is
# not, so a branch whose commits all reached the base still counts as ahead, the scan finds
# its claim commit, and a PR-unit that merged days ago is reported in flight — measured
# 2026-08-04 on the hourly unattended runner, where `origin/claude/sharp-rubin-xiorxm`
# (merged as PR #109) returned 154 ahead while shallow and 0 after `--unshallow`, and was
# offered as `resumable` past both safety gates.
#
# `lib/claims.sh` repairs that where it can (`--unshallow`) and degrades loudly where it
# cannot (`shallow_history`). Both are the reader defending itself against a condition the
# REPOSITORY creates: with `delete_branch_on_merge` off, every merged pull request leaves a
# branch behind for the oracle to trip over, forever. Measured here 2026-09-01: 268 of 302
# remote branches were merged-but-undeleted. The setting is the only place that population
# is bounded at its source, so a repository wired to the standards has it on.
#
# THE SETTING IS FORWARD-ONLY, AND THE RESIDUE IS SAID RATHER THAN SWEPT. Turning it on
# deletes nothing that already exists, so the accumulated branches stay a live input to the
# scan. They are reported with the ready-to-run deletion, never deleted here: which of a
# team's branches may vanish is a judgment about somebody's work in progress, and this is
# the same line the rename registry's `name` rows draw (`proposed, never applied`).
#
# NOT MERGE-METHOD OPINIONS. `allow_squash_merge`, `allow_merge_commit` and the rest are a
# repository's own taste and no mechanism here reads them; only the one setting a workaholic
# mechanism depends on is checked, so the check cannot grow into a house-style audit.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"

REMOTE="${1:-origin}"
SLUG=""

# $1 state, $2 reason, $3 problems (JSON array), $4 dbom (json literal), $5 admin (literal),
# $6 residue (JSON object). `ok` is derived from the state rather than passed, so no call
# site can report a degradation as a conforming repository by forgetting a flag.
UNREAD_RESIDUE='{"readable": false, "reason": "not_read", "merged_undeleted": null, "sample": [], "command": ""}'

emit() {
    _ok=true
    if [ "$1" = "unanswerable" ]; then _ok=false; fi
    printf '{"ok": %s, "slug": "%s", "state": "%s", "reason": "%s", "settings": {"delete_branch_on_merge": %s}, "admin": %s, "problems": %s, "residue": %s}\n' \
        "$_ok" "$SLUG" "$1" "${2:-}" "${4:-null}" "${5:-null}" "${3:-[]}" \
        "${6:-$UNREAD_RESIDUE}"
    exit 0
}

# The residue reading is local-only and never fatal: it is evidence for the setting, not the
# check itself. A shallow clone cannot answer "merged into the base" at all, and says so
# rather than answering zero — the same asymmetry `lib/claims.sh` keeps.
read_residue() {
    if [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo true)" = "true" ]; then
        printf '{"readable": false, "reason": "shallow_history", "merged_undeleted": null, "sample": [], "command": ""}'
        return 0
    fi
    _base="refs/remotes/${REMOTE}/main"
    git show-ref --verify --quiet "$_base" 2>/dev/null || {
        printf '{"readable": false, "reason": "no_base_ref", "merged_undeleted": null, "sample": [], "command": ""}'
        return 0
    }
    # Everything already on the base and still standing, minus the base itself, the symbolic
    # HEAD, and the release tier — a release branch is batch-level and outlives its merge by
    # design (`cut-release-branch.sh`).
    _list=$(git branch -r --merged "${REMOTE}/main" 2>/dev/null \
        | sed -e 's/^[* ]*//' -e "s#^${REMOTE}/##" \
        | grep -v -e '^main$' -e '^HEAD' -e '^release/' -e '^HEAD ->' || true)
    _count=$(printf '%s' "$_list" | grep -c . || true)
    case "$_count" in ''|*[!0-9]*) _count=0 ;; esac
    _sample=$(printf '%s\n' "$_list" | grep . | head -5 | jq -R . | jq -sc . 2>/dev/null || printf '[]')
    _cmd=""
    if [ "$_count" -gt 0 ]; then
        _cmd="git branch -r --merged ${REMOTE}/main | sed -e 's|^[* ]*||' -e 's|^${REMOTE}/||' | grep -v -e '^main\$' -e '^HEAD' -e '^release/' | xargs -r -n 25 git push ${REMOTE} --delete"
    fi
    printf '{"readable": true, "reason": "", "merged_undeleted": %s, "sample": %s, "command": %s}' \
        "$_count" "$_sample" "$(printf '%s' "$_cmd" | jq -Rs .)"
}

[ -f "$GH_REST" ] || emit unanswerable no_transport_script

slug=$(sh "$GH_REST" slug "$REMOTE" 2>/dev/null || true)
case "$slug" in
    */*) SLUG="$slug" ;;
    *) emit unanswerable slug_unresolved ;;
esac

# REPOSITORY-SCOPED REST, never `gh repo view` (GraphQL-backed, and a web session may 403 it
# mid-run — `rules/shell.md`). No separate availability probe: it would spend a round trip to
# learn what this call reports, so the failure of the one call is classified instead.
if ! body=$(sh "$GH_REST" api "repos/${SLUG}" 2>&1); then
    case "$body" in
        *"not on PATH"*) emit unanswerable gh_unavailable ;;
        *"rate limit"*|*"rate_limit"*|*"API rate"*) emit unanswerable rate_limited ;;
        *"not enabled for this session"*|*"not permitted for this session"*)
            emit unanswerable session_refused ;;
        *"Not Found"*|*"404"*) emit unanswerable repo_not_found ;;
        *) emit unanswerable transport_error ;;
    esac
fi

# An unparseable body is ours, and it is never evidence that the setting is already on.
printf '%s' "$body" | jq -e 'type == "object" and (.delete_branch_on_merge | type == "boolean")' \
    >/dev/null 2>&1 || emit unanswerable unparseable_response

dbom=$(printf '%s' "$body" | jq -r '.delete_branch_on_merge')
admin=$(printf '%s' "$body" | jq -r 'if (.permissions.admin | type) == "boolean" then (.permissions.admin | tostring) else "null" end')

residue=$(read_residue)

if [ "$dbom" = "true" ]; then
    emit conforming "" '[]' true "$admin" "$residue"
fi

problems=$(jq -nc '["delete_branch_on_merge (a merged pull request leaves its branch on the remote; the claim oracle reads unmerged remote branches, so every one of them is a candidate false claim)"]')
emit nonconforming "" "$problems" false "$admin" "$residue"
