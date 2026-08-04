#!/bin/sh -eu
# The dedup set (docs/loop-engineering-workflow.md C4): the union of `feedback:`
# refs across every PROPOSED ARTIFACT - every mission (both areas) AND every
# ticket (todo and archive) - one filename per line. Feedback already referenced
# by any of them never spawns a second proposal; combined with the cursor this
# makes the batch idempotent.
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

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic"

[ -d "$ROOT" ] || exit 0

set --
for md in \
    "$ROOT"/missions/active/*/mission.md \
    "$ROOT"/missions/archive/*/mission.md \
    "$ROOT"/missions/*/mission.md \
    "$ROOT"/tickets/todo/*/*.md \
    "$ROOT"/tickets/archive/*/*.md
do
    [ -f "$md" ] || continue
    set -- "$@" "$md"
done

[ "$#" -gt 0 ] || exit 0

sh "${SCRIPT_DIR}/read-feedback-relation.sh" "$@" | sort -u
