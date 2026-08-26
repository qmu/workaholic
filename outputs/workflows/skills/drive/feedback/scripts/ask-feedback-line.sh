#!/bin/sh -eu
# THE ONE WRITER OF AN INBOUND ASK'S `feedback:` HEADER LINE.
#
#   ask-feedback-line.sh <ref>...
#   ask-feedback-line.sh "<ref>, <ref>"      # a comma-separated string is one argument
#
# Output: exactly one line, `feedback: <ref>, <ref>` — or NOTHING AT ALL for an empty ref
#   set. Exit 0 in every case. Pure formatter: it reads no file, resolves no path and
#   writes nothing anywhere.
#
# ═══ WHY THIS IS A SCRIPT AND NOT THREE printf CALLS ═════════════════════════════════
# The line has exactly one reader — `specificate/scripts/read-ask-feedback-refs.sh` — and,
# until this script existed, exactly one writer, inlined in `propose/scripts/open-proposal.sh`
# beside the `strategy:`/`move:` marker. Two more callers want it (the inbound Slack sweep
# and `/fb`'s in-repo path), and the reader's own header states the rule this repository has
# already paid for twice: TWO PARSERS OF ONE FIELD EVENTUALLY DISAGREE, and the side that
# under-reads re-proposes feedback somebody already answered. The writing side gets the same
# single-writer treatment BEFORE it is multiplied rather than after — the same reasoning that
# makes `file-inbound-ask.sh` the one writer of the `slack-ref:` marker.
#
# IT LIVES IN THE FEEDBACK SKILL, not in `propose/`, because two of its three callers sit
# outside `propose/` and the `feedback:` relation is the feedback skill's own. The direction
# is already established: `file-inbound-ask.sh` reaches into `feedback/scripts/open-issue.sh`.
#
# ═══ THE FORMAT IS THE READER'S, NOT A NEW ONE ═══════════════════════════════════════
# Refs are normalised exactly as both readers of this relation normalise them — brackets
# dropped, split on commas, trimmed, empties removed — and joined with `, `. That is the
# canonical form `strategy/scripts/read.sh` already emits, so rewiring `open-proposal.sh`
# to this script left the issue body it composes byte-identical.
#
# AN EMPTY REF SET EMITS NO LINE, deliberately, and it is the case worth stating: a caller
# whose ask answers no live direction must produce NO LINE rather than an empty one. The
# reader tells the three states apart (`line_found: false`, a line naming nothing, a line
# naming refs), and an empty line would report the middle one — an ask that named a
# direction and lost it — for an ask that never had one.
#
# THE LINE IS VISIBLE BODY TEXT, never an HTML comment: a fact the loop depends on that no
# human reading the issue can see is the one thing this loop must never become
# (`propose/scripts/open-proposal.sh`, *The three header lines, and why they are visible*).

set -eu

[ "$#" -gt 0 ] || exit 0

REFS="$(printf '%s\n' "$@" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true)"

[ -n "$REFS" ] || exit 0

printf 'feedback: %s\n' "$(printf '%s\n' "$REFS" | paste -sd, - | sed 's/,/, /g')"
