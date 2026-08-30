#!/bin/sh -eu
# THE ONE WRITER OF AN INBOUND ASK'S `feedback:` HEADER LINE.
#
#   ask-feedback-line.sh <ref>...
#   ask-feedback-line.sh "<ref>, <ref>"      # a comma-separated string is one argument
#   ask-feedback-line.sh --refs-only <ref>...
#
# Output: exactly one line, `feedback: <ref>, <ref>` — or NOTHING AT ALL for an empty ref
#   set. Exit 0 in every case. Pure formatter: it reads no file, resolves no path and
#   writes nothing anywhere.
#
# `--refs-only` emits the same normalised set WITHOUT the `feedback: ` prefix, for the one
# caller that needs the refs as an ARGUMENT rather than as a body line: `/specificate`'s
# strategy form hands them to `create.sh`, which takes a comma-separated list. It is the same
# normalisation, deliberately — a successor's carried refs and an ask's carried refs are the
# same set formatted for two seams, and formatting one of them somewhere else is exactly how
# two writers of one relation begin. The prefixed output is unchanged for every existing
# caller, with one normalisation added for both modes: a REPEATED ref is collapsed, order
# preserved. A successor carrying its predecessor's refs beside the record that announced it
# names the same ref twice whenever the announcement cited one of them, and a doubled ref is
# noise in every reader of this relation.
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

REFS_ONLY=0
if [ "${1:-}" = "--refs-only" ]; then
  REFS_ONLY=1
  shift
fi

[ "$#" -gt 0 ] || exit 0

REFS="$(printf '%s\n' "$@" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true)"

[ -n "$REFS" ] || exit 0

# Duplicates are collapsed, order preserved: a successor carrying its predecessor's refs
# beside the record that announced it will name the same ref twice whenever the announcement
# itself cited one of them, and a doubled ref is noise in every one of this line's readers.
JOINED="$(printf '%s\n' "$REFS" | awk '!seen[$0]++' | paste -sd, - | sed 's/,/, /g')"

if [ "$REFS_ONLY" = "1" ]; then
  printf '%s\n' "$JOINED"
else
  printf 'feedback: %s\n' "$JOINED"
fi
