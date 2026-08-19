#!/bin/sh -eu
# Capture the GitHub issue number a proposal's ask came from, so step 10 can
# thread it into the pull request body as a closing keyword (`Closes #<N>`)
# and merging the proposal auto-closes the originating "[FB] ***" issue.
#
#   extract-issue-number.sh ["<argument>"]
#
# Two sources, routine first (it is the more specific signal — a routine's
# trigger IS the issue, while a hand-typed argument only MENTIONS one):
#   1. CCR_TRIGGER_ISSUE_NUMBER — set by a Claude Code Web routine invoked
#      from a GitHub issue trigger.
#   2. A `#<N>` reference or a `.../issues/<N>` URL inside the argument — a
#      developer typing `/specificate #319 ...` or pasting the issue link.
#
# Output (stdout, always exit 0 for a reported outcome):
#   {"issue_number": "<N>"}   digits only, never the `#` or the URL
#   {"issue_number": ""}      neither source named one -- not an error, most
#                              asks (a Slack message, a direct instruction)
#                              never had a GitHub issue at all
#
# WHY NOT GREP INLINE IN THE CALLING PROMPT: the CLAUDE.md shell-script
# principle forbids conditionals/pattern-matching in command or skill prose;
# this is the bundled script that owns it.

set -eu

ARG="${1:-}"

trigger="${CCR_TRIGGER_ISSUE_NUMBER:-}"
case "$trigger" in
  ''|*[!0-9]*) trigger="" ;;
esac

if [ -n "$trigger" ]; then
  printf '{"issue_number": "%s"}\n' "$trigger"
  exit 0
fi

# `#<N>` first (bare mention), then an issues/<N> URL -- either may appear
# anywhere in the argument. sed's BRE has no \d, so [0-9][0-9]* stands in.
from_hash=$(printf '%s\n' "$ARG" | sed -n 's/.*#\([0-9][0-9]*\).*/\1/p' | head -n 1)
if [ -n "$from_hash" ]; then
  printf '{"issue_number": "%s"}\n' "$from_hash"
  exit 0
fi

from_url=$(printf '%s\n' "$ARG" | sed -n 's#.*/issues/\([0-9][0-9]*\).*#\1#p' | head -n 1)
if [ -n "$from_url" ]; then
  printf '{"issue_number": "%s"}\n' "$from_url"
  exit 0
fi

printf '{"issue_number": ""}\n'
