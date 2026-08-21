#!/bin/sh -eu
# Render the wire shape of a crossing issue's title: exactly one leading `[FB] ` marker.
#
# Usage: fb-title.sh <title>          # prints the stamped title on stdout
# Emits the stamped title on stdout, or exits non-zero with a message on stderr.
#
# THE ONE IMPLEMENTATION OF THE TITLE'S WIRE SHAPE, and deliberately a separate script
# rather than a few lines inside `open-issue.sh`, because two callers need the same
# answer and only one of them sends:
#
#   * `open-issue.sh` calls it on the way to the wire, so no caller has to remember the
#     marker and no second implementation can drift from this one.
#   * The crossing's confirmation step (`reference/crossing.md` §4) renders the title
#     through it *before* showing it, so the developer confirms the exact string that
#     gets sent. A title confirmed verbatim and then rewritten by the sender would not
#     be verbatim at all — the confirmation is the crossing's only human gate, and a
#     gate shown a different string than the one that ships is not a gate.
#
# IDEMPOTENT BY CONTRACT. The marker was applied by hand for the whole life of the
# crossing — measured 2026-08-12: 17 of 17 issues this repository received through it
# already carried `[FB]`, against 1 of 9 filed directly by a human — so a composing
# agent writing the marker itself is the common case, not the edge, and `[FB] [FB] …`
# is the first regression a naive prepend would ship. Every spacing and case a composing
# agent plausibly writes is recognised and canonicalised to a single `[FB] `.

set -eu

title="${1:-}"

if [ -z "$title" ]; then
    echo "fb-title.sh: no title given" >&2
    exit 1
fi

# Strip every leading marker, then add exactly one back. Looping rather than matching
# once handles a title that already arrived double-prefixed by hand; the loop terminates
# because each pass either shortens the string or leaves it unchanged.
rest="$title"
while :; do
    stripped=$(printf '%s' "$rest" | sed 's/^[[:space:]]*\[[[:space:]]*[Ff][Bb][[:space:]]*\][[:space:]]*//')
    [ "$stripped" = "$rest" ] && break
    rest="$stripped"
done

# A title that was nothing but the marker carries no ask; refuse it rather than sending
# a bare `[FB]` to somebody else's tracker.
if [ -z "$rest" ]; then
    echo "fb-title.sh: title is only the [FB] marker — nothing to say" >&2
    exit 1
fi

printf '%s\n' "[FB] ${rest}"
