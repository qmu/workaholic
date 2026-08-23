#!/bin/sh -eu
# Classify a refused `PUT .../pulls/N/merge` response into one honest reason.
#
# WHY IT IS ITS OWN SCRIPT (2026-08-23). The ladder lived inline in `publish-tree-pr.sh`,
# where the only way to exercise it was to make a real merge fail — so the reasons were
# asserted by reading the source rather than by running it. Pulled out, it is a pure function
# over a string: no network, no git, no state, and every rung testable.
#
# THE REASONS ARE DIFFERENT NEXT ACTIONS, which is the whole point of not collapsing them
# into `merge_failed`:
#
#   merge_not_allowed          405 — GitHub refuses the merge itself: a conflict, or a
#                              required check not satisfied. Look at the pull request.
#   head_moved                 409 — the head moved under us. Re-read and try again.
#   session_type_cannot_merge  403 "Merging pull requests is not permitted for this session
#                              type" — the EXECUTION CLASS saying no. Not a fault in the
#                              change, not a conflict, not a race; the pull request is fine
#                              and a different caller can merge it unchanged. This is the one
#                              refusal `rules/shell.md` allows to be retried through a
#                              connector.
#   merge_forbidden            any other 403 — a missing permission, a protected branch. A
#                              person must change something outside the pull request.
#   merge_failed               anything else, unclassified and honest about it.
#
# THE SESSION-TYPE RUNG IS KEYED ON THE MESSAGE, WITH THE STATUS AS ITS FALLBACK. 403 alone is
# also what a missing permission returns, so the status cannot carry this meaning by itself;
# the sentence can, and it is GitHub's own wording a reader will see quoted. If that wording is
# ever reworded upstream this degrades to `merge_forbidden` — still a 403, still not a fault in
# the change — rather than to `merge_failed`, so the class is never mistaken for a defect.
#
# Usage: merge-reason.sh "<the failed response text>"    # or on stdin
# Output: one bare word on stdout.

set -eu

if [ $# -gt 0 ]; then resp="$1"; else resp=$(cat); fi

case "$resp" in
    *405*) printf 'merge_not_allowed\n' ;;
    *409*) printf 'head_moved\n' ;;
    *"not permitted for this session type"*) printf 'session_type_cannot_merge\n' ;;
    *403*) printf 'merge_forbidden\n' ;;
    *)     printf 'merge_failed\n' ;;
esac
