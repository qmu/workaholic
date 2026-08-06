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
# GIT-NATIVE, NOT `gh pr list`. An unmerged remote branch is the same oracle the
# claim protocol already rests on (drive/scripts/lib/claims.sh): no auth, no API
# budget, no network beyond the fetch the caller already did. It over-reads by
# exactly the branches that are pushed but have no pull request - which is the safe
# direction here, see below.
#
# WHICH DIRECTION TO ERR: OVER-READ. A set that over-reads suppresses a proposal;
# one that under-reads publishes a duplicate. The duplicate is the louder failure
# and the measured one, so every ambiguous case here resolves toward including the
# ref. A suppressed proposal is silence to the reporter, which is why the ambiguity
# is named in this header rather than left implicit.
#
# CLOSING A PULL REQUEST WITHOUT MERGING, decided rather than inherited: the branch
# is what this keys on, so a closed-but-undeleted branch keeps its refs in the set
# and its ask stays suppressed. DELETING THE BRANCH is the act that frees the
# feedback to be proposed again - the same invariant the claim protocol uses, where
# deleting the branch is what releases a claim. GitHub offers that delete on the
# close, so the ordinary path already does the right thing.
#
# COST, MEASURED (2026-08-05). One ancestry test per remote branch plus one tree
# diff per unmerged branch: ~4s over 195 remote branches here, of which 194 were
# merged-but-undeleted. The dominant term is the branch COUNT, not the artifact
# count, so deleting merged branches is what keeps this cheap. If it ever stops
# being cheap, the fix is `for-each-ref --no-merged` (one process instead of N),
# not a second parser pass.
#
# SHALLOW CLONES OVER-READ, DELIBERATELY. `git rev-list --count base..ref` cannot be
# reduced across a graft, so a shallow clone counts long-merged branches as ahead
# and pulls their refs in. This mirrors claims.sh's handling: the merge base is
# tested first, and a branch whose ancestry is unanswerable is INCLUDED (over-read)
# rather than dropped. The degradation is reported on stderr - stdout stays exactly
# the ref list its callers `sort -u`, so a warning can never be mistaken for a ref.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic"

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
BASE=""
for cand in origin/main origin/master main master; do
    if git rev-parse --verify --quiet "${cand}^{commit}" >/dev/null 2>&1; then
        BASE="$cand"
        break
    fi
done

if [ -z "$BASE" ]; then
    echo "list-proposed-refs: no base ref resolved; open pull requests not covered" >&2
elif ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "list-proposed-refs: not a git repository; open pull requests not covered" >&2
else
    if [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ]; then
        echo "list-proposed-refs: shallow clone; merged branches may be read as open (over-reading)" >&2
    fi
    n=0
    for ref in $(git for-each-ref --format='%(refname)' refs/remotes/origin 2>/dev/null || true); do
        short=${ref#refs/remotes/}
        [ "$short" = "origin/HEAD" ] && continue
        [ "$short" = "$BASE" ] && continue
        # Unanswerable ancestry (a shallow graft) counts as unmerged: over-read.
        if [ -n "$(git merge-base "$BASE" "$ref" 2>/dev/null || true)" ]; then
            [ "$(git rev-list --count "${BASE}..${ref}" 2>/dev/null || echo 0)" -gt 0 ] || continue
        fi
        # ONLY WHAT THE BRANCH ADDS. A two-dot tree diff, not `ls-tree`: a branch
        # carries the WHOLE artifact tree, and materialising every archived ticket on
        # every unmerged branch is thousands of `git show` calls -- measured at over
        # two minutes in this repository, on a path a reporter is waiting on. Anything
        # a branch shares with the base is already covered by the working-tree walk
        # above, so the difference is exactly the new artifacts. Two-dot on purpose:
        # it compares trees and needs no merge base, so it still answers in a clone
        # too shallow for `...` to resolve.
        for path in $(git diff --name-only --diff-filter=AM "$BASE" "$ref" -- \
                "$ROOT/missions" "$ROOT/tickets" 2>/dev/null || true); do
            case "$path" in
                */mission.md|"$ROOT"/tickets/todo/*.md|"$ROOT"/tickets/todo/*/*.md|"$ROOT"/tickets/archive/*/*.md) ;;
                *) continue ;;
            esac
            n=$((n + 1))
            git show "${ref}:${path}" >"${WORK}/${n}.md" 2>/dev/null || continue
            set -- "$@" "${WORK}/${n}.md"
        done
    done
fi

[ "$#" -gt 0 ] || exit 0

sh "${SCRIPT_DIR}/read-feedback-relation.sh" "$@" | sort -u
