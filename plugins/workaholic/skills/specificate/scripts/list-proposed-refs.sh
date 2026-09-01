#!/bin/sh -eu
# The dedup set (docs/loop-engineering-workflow.md C4): the union of `feedback:`
# refs across every PROPOSED ARTIFACT - every mission (both areas) and every
# ticket (todo and archive) in the working tree, PLUS the same artifacts carried by
# unmerged remote branches, i.e. the proposals still open as pull requests - one
# filename per line. Feedback already referenced by any of them never spawns a
# second proposal; combined with the cursor this makes the batch idempotent.
#
# Usage: list-proposed-refs.sh
# Output: zero or more feedback record filenames, one per line, de-duplicated.
#
# WHY TICKETS ARE IN THE SET. A proposal is a mission with its ticket set when the
# direction decomposes and ONE LOOSE BACKLOG TICKET when it is atomic. A loose
# ticket has no mission to carry the relation, so it carries `feedback:` itself -
# and a dedup set that read only missions would see no reference to that record
# and re-propose it on the next tick, forever.
#
# THE ARCHIVE COUNTS AS MUCH AS THE QUEUE. A loose proposed ticket that has been
# driven is the strongest possible evidence that its feedback was acted on; if
# archiving a ticket dropped its record out of the set, the batch would re-propose
# precisely the work it had just finished.
#
# ONE PARSER, ONE PROCESS. Every ref is read through read-feedback-relation.sh,
# which takes many files, so a scan over hundreds of archived tickets is one awk
# process rather than one per file - this runs on the 15-minute path. Nothing
# here parses the field itself; a second parser would eventually disagree with
# the first, and the side that under-reads re-proposes answered feedback.
#
# AN OPEN PULL REQUEST COUNTS AS PROPOSED (2026-08-05). The working tree this walks
# is, at the propose seam, the PUBLISH tree - a checkout of origin/main - so it
# sees merged artifacts only. A proposal still sitting in an open pull request has
# its `feedback:` refs on a branch nobody reads, and the seam concluded the ask had
# never been answered. Measured the day this shipped: issue #242 restated the ask
# already proposed ten minutes earlier in open PR #241, the scripted dedup did not
# catch it, and the duplicate was found only because the reviewing session happened
# to list open pull requests by hand. The set therefore also covers the artifacts on
# UNMERGED REMOTE BRANCHES, so it answers "has this ask been proposed" rather than
# the narrower "has a proposal for it merged".
#
# THE BRANCH WALK IS NOT OWNED HERE (2026-09-01, ticket 20260901042313). It lives in
# `lib/unmerged-branches.sh`, which carries the whole rationale: git-native rather than
# `gh pr list`, over-reading on every ambiguity, the shallow-clone caveat, the measured
# cost, and why deleting a branch is what frees its artifacts. It was extracted when
# `list-inbound-issues.sh` needed the same walk over the FEEDBACK RECORDS a branch adds -
# two walkers over one oracle drift, and the side that under-reads is the side that
# duplicates. What stays here is which artifacts to read and how to parse them.
#
# WHICH DIRECTION TO ERR: OVER-READ. A set that over-reads suppresses a proposal;
# one that under-reads publishes a duplicate. The duplicate is the louder failure
# and the measured one, so every ambiguous case here resolves toward including the
# ref. A suppressed proposal is silence to the reporter, which is why the ambiguity
# is named in this header rather than left implicit.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic"

UNMERGED_BRANCHES_LABEL="list-proposed-refs"
. "${SCRIPT_DIR}/lib/unmerged-branches.sh"

[ -d "$ROOT" ] || exit 0

WORK=$(mktemp -d "${TMPDIR:-/tmp}/proposed-refs.XXXXXX")
trap 'rm -rf "$WORK"' EXIT INT TERM

set --
for md in \
    "$ROOT"/missions/active/*/mission.md \
    "$ROOT"/missions/archive/*/mission.md \
    "$ROOT"/missions/*/mission.md \
    "$ROOT"/tickets/todo/*.md \
    "$ROOT"/tickets/todo/*/*.md \
    "$ROOT"/tickets/archive/*/*.md
do
    [ -f "$md" ] || continue
    set -- "$@" "$md"
done

# ---- the artifacts on unmerged remote branches ----------------------------
# Blobs are materialised into a scratch dir because the one parser reads FILES,
# and reading N blobs through N parser invocations is the cost this script was
# written to avoid. One `git show` per artifact, one parser pass over all of them.
BASE="$(unmerged_branches_base)"

if [ -z "$BASE" ]; then
    echo "list-proposed-refs: no base ref resolved; open pull requests not covered" >&2
elif ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "list-proposed-refs: not a git repository; open pull requests not covered" >&2
else
    unmerged_branches_warn_shallow
    n=0
    TAB="$(printf '\t')"
    while IFS="$TAB" read -r ref path; do
        [ -n "$path" ] || continue
        case "$path" in
            */mission.md|"$ROOT"/tickets/todo/*.md|"$ROOT"/tickets/todo/*/*.md|"$ROOT"/tickets/archive/*/*.md) ;;
            *) continue ;;
        esac
        n=$((n + 1))
        git show "${ref}:${path}" >"${WORK}/${n}.md" 2>/dev/null || continue
        set -- "$@" "${WORK}/${n}.md"
    done <<EOF
$(unmerged_branches_added_paths "$BASE" "$ROOT/missions" "$ROOT/tickets")
EOF
fi

[ "$#" -gt 0 ] || exit 0

sh "${SCRIPT_DIR}/read-feedback-relation.sh" "$@" | sort -u
