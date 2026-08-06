#!/bin/sh -eu
# Read back the notification target a pull request body carries — the other half of
# the routine chain's hand-off (P4, 2026-08-06).
#
#   read-notify-target.sh <pr-number-or-url>          # read it from GitHub
#   read-notify-target.sh --body-file <path>          # read it from a body already in hand
#
# Output (stdout, exit 0 for a reported outcome):
#   {"found": true,  "target": "<url>"}
#   {"found": false, "reason": "absent"|"no_gh"|"unreadable"|"no_ref"}
#
# WHY A LABELLED LINE AND NOT PROSE. `/propose` writes `Notify-Thread: <url>` into
# the body it opens; `/implement`, started by that pull request's merge, reads it
# back here and replies there. The alternative — re-deriving the thread from an
# `fb:<stem>` search — is the step that put a reply in the wrong place on
# 2026-08-05: a search has to guess, and a guess in a notification path is a
# message that looks right and is unrelated to the event. A line the writer put
# there cannot be guessed wrong.
#
# `absent` IS THE FALLBACK SIGNAL, NOT AN ERROR. Every pull request opened before
# this change carries no line, and so does one opened by a seam that had no target
# to pass. The caller's documented behaviour on `found: false` is the existing
# thread search (`workaholic:workaholify`, *One thread per feedback item*) — which
# is why the reasons are distinguished: `absent` means "fall back", while `no_gh`
# and `unreadable` mean the question could not be asked at all and the caller is
# reading nothing rather than an answer.
#
# The pattern is anchored and the FIRST match wins. A body is user-editable text
# and may quote the line while discussing it; the writer emits exactly one, last,
# so first-match-wins resolves a quoted duplicate the way the writer intended.

set -eu

REF=""
BODY_FILE=""

case "${1:-}" in
  --body-file)
    BODY_FILE="${2:-}"
    [ -n "$BODY_FILE" ] || { printf '{"found": false, "reason": "no_ref"}\n'; exit 0; }
    ;;
  "")
    printf '{"found": false, "reason": "no_ref"}\n'
    exit 0
    ;;
  *)
    REF="$1"
    ;;
esac

if [ -z "$BODY_FILE" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    printf '{"found": false, "reason": "no_gh"}\n'
    exit 0
  fi
  BODY_FILE=$(mktemp "${TMPDIR:-/tmp}/workaholic-notify-target.XXXXXX")
  trap 'rm -f "$BODY_FILE"' EXIT
  if ! gh pr view "$REF" --json body -q .body >"$BODY_FILE" 2>/dev/null; then
    printf '{"found": false, "reason": "unreadable"}\n'
    exit 0
  fi
fi

[ -f "$BODY_FILE" ] || { printf '{"found": false, "reason": "unreadable"}\n'; exit 0; }

target=$(sed -n 's/^Notify-Thread:[[:space:]]*//p' "$BODY_FILE" | head -n 1 | sed -e 's/[[:space:]]*$//')

if [ -z "$target" ]; then
  printf '{"found": false, "reason": "absent"}\n'
  exit 0
fi

escaped=$(printf '%s' "$target" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
printf '{"found": true, "target": "%s"}\n' "$escaped"
