#!/bin/sh -eu
# Read the `feedback:` relation of one or more ARTIFACTS and print the referenced
# feedback record filename(s), one per line - the single reader of the
# artifact->feedback relation (the mirror of mission/scripts/read-relation.sh).
# Tolerates the inline-list and bare-scalar forms, reads the frontmatter block
# only, and never fails on a malformed/missing file.
#
#   feedback: [a.md, b.md]  -> a.md / b.md
#   feedback: a.md          -> a.md
#   feedback:               -> (nothing)
#
# Usage: read-feedback-relation.sh <artifact-file>...
#
# IT TAKES A MISSION *OR* A TICKET, and it takes MANY. A proposal is a mission
# with its ticket set when the direction decomposes, and one loose backlog ticket
# when the direction is atomic - so the relation now lands on either artifact and
# the dedup set is the union of both (list-proposed-refs.sh). One reader for both
# sides is the point: two parsers of the same field would eventually disagree,
# and the side that under-reads re-proposes feedback somebody already answered.
#
# The many-files form exists because the dedup scan runs on the 15-minute path
# over every archived ticket - hundreds of them. One awk process reading N files
# costs what one process costs; N invocations of this script cost N process
# spawns, which is the difference between a scan you can afford per tick and one
# you cannot.

set -eu

[ "$#" -gt 0 ] || exit 0

raw=$(awk '
FNR == 1 { fm = ($0 == "---"); done = 0; next }
!fm || done { next }
/^---[ \t]*$/ { done = 1; next }
/^feedback:[ \t]*/ { sub(/^feedback:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; done = 1 }
' "$@" 2>/dev/null || true)

[ -n "$raw" ] || exit 0

printf '%s\n' "$raw" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true
