#!/bin/sh -eu
# WHAT A STRANDED CLAIM BRANCH IS STILL HOLDING — the files, bounded, and the full count.
#
# Usage: stranded-claim-detail.sh <branch> [<stamped-artifact>...]
# Output: one JSON line, always exit 0
#   {"branch": "...", "readable": true,  "reason": "",             "files": [...], "count": 3}
#   {"branch": "...", "readable": false, "reason": "no_branch_ref", "files": [],   "count": null}
#
# WHY IT EXISTS (2026-08-31, mission `prove-a-claim-branch-is-empty-before-deleting-it`).
# `stranded` says a delivered claim's branch still holds content of its own; it does not say
# WHAT. A question that names only the verdict sends its reader back to the repository to find
# out what is at risk, and `workaholic:notify`'s catalog requires the opposite — the plain fact
# first, the identifier after it, and the named details riding the heading. This resolves those
# names, one bounded read per candidate and none for anything else.
#
# IT IS `declared-handoff-detail.sh`'S SIBLING, ON PURPOSE. That reader resolves the string a
# `awaiting_verification` question must quote; this one resolves the names a `stranded` question
# must carry. Both are called only for candidates the oracle already selected, so neither costs
# anything on an ordinary tick.
#
# IT DERIVES NOTHING OF ITS OWN. The answer is `claims_branch_diff_reading`'s, verbatim — the
# same reading `claims_delivery` composed to reach the verdict — so this can never disagree with
# the row it is describing. A second walk over the branch's diff would be exactly the drift the
# claim protocol spends its longest comments preventing.
#
# IT MAKES NO NETWORK CALL AND WRITES NOTHING: one `merge-base` and two `diff --name-only`
# against refs the caller already fetched, touching no ref, index or worktree.
#
# A READING IT COULD NOT MAKE IS `readable: false` WITH A NAMED REASON AND A NULL COUNT, never
# an empty file list — the caller must be able to tell *this branch holds nothing* from *we
# could not look*, and rendering the second as the first is how a stranded branch becomes
# invisible again.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

BRANCH=""
ARTS=""
for a in "$@"; do
    if [ -z "$BRANCH" ]; then
        BRANCH="$a"
    elif [ -z "$ARTS" ]; then
        ARTS="$a"
    else
        ARTS="${ARTS},${a}"
    fi
done

json_escape() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[[:cntrl:]]/ /g'
}

emit() { # $1 readable, $2 reason, $3 files-json-body, $4 count
    printf '{"branch": "%s", "readable": %s, "reason": "%s", "files": [%s], "count": %s}\n' \
        "$(json_escape "$BRANCH")" "$1" "$(json_escape "${2:-}")" "${3:-}" "${4:-null}"
    exit 0
}

[ -n "$BRANCH" ] || emit false no_branch "" null

REF="origin/${BRANCH}"
git rev-parse --verify --quiet "$REF" >/dev/null 2>&1 || emit false no_branch_ref "" null

BASE=$(claims_base)
[ -n "$BASE" ] || emit false no_base "" null

READING=$(claims_branch_diff_reading "$BASE" "$REF" "$ARTS" 2>/dev/null || true)
[ -n "$READING" ] || emit false reading_failed "" null

# The reader's own fields, sliced out rather than re-derived. `state` and `reason` are bare
# words and `count` a bare integer, so a positional slice is exact; the file list is carried
# through verbatim, already JSON-escaped by the reader that built it.
state=${READING#*'"state": "'}
state=${state%%'"'*}
why=${READING#*'"reason": "'}
why=${why%%'"'*}
files=${READING#*'"files": ['}
files=${files%%']'*}
count=${READING##*'"count": '}
count=${count%\}}

case "$state" in
    non_empty) emit true "" "$files" "$count" ;;
    empty)     emit true not_stranded "" 0 ;;
    *)         emit false "${why:-unanswerable}" "" null ;;
esac
