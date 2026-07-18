#!/bin/sh -eu
# Commit and push generated release note(s) to the current branch, so they are
# included in the merge to main. Run AFTER workaholic:write-release-note has written the
# note file(s) under .workaholic/release-notes/ and BEFORE merge-pr.sh.
# Usage: bash commit-release-note.sh <branch>
# Output: JSON {committed, branch, pushed, push_error[, fatal]} or {committed:false, reason}
#
# The push outcome decides the exit. This script runs BEFORE merge-pr.sh, so a
# note that fails to reach the remote is a PR about to merge WITHOUT its release
# note — a pre-merge failure while nothing has landed yet, which is exactly when
# stopping is cheap. A failed or rejected push (including no-upstream in a repo
# that has a remote) therefore exits 1 with `fatal: "release_note_not_on_remote"`;
# the local note commit is left intact for the caller to push and retry. The one
# soft outcome is `no_remote`: with nothing to push to there is no remote PR the
# note could miss, so the script still exits 0 and reports pushed:false. (This is
# deliberately harder than extract-deferred-concerns.sh's post-merge best-effort
# push — that one runs after the PR has merged, where aborting buys nothing.)

set -eu

branch="${1:-}"

if [ -z "$branch" ]; then
  echo '{"error": "branch name is required"}' >&2
  exit 1
fi

notes_dir=".workaholic/release-notes"

tracked_changes=$(git status --porcelain -- "$notes_dir" 2>/dev/null || echo "")

if [ -z "$tracked_changes" ]; then
  echo '{"committed": false, "reason": "no_release_note_changes"}'
  exit 0
fi

# Refresh the .workaholic OKF bundle indexes (stages them) so the new note is
# reflected in the committed hierarchy (best-effort: never blocks the commit).
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/push-outcome.sh"
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$notes_dir"
git commit -m "Add release notes for $branch" >/dev/null
# Pre-merge hard stop on a failed push (see header): only no_remote stays soft.
push_and_report

if [ "$PUSH_OK" != "true" ] && [ "$PUSH_ERROR" != "no_remote" ]; then
  echo '{"committed": true, "branch": "'"$branch"'", "pushed": false, "push_error": "'"$PUSH_ERROR"'", "fatal": "release_note_not_on_remote"}'
  exit 1
fi

echo '{"committed": true, "branch": "'"$branch"'", "pushed": '"$PUSH_OK"', "push_error": "'"$PUSH_ERROR"'"}'
