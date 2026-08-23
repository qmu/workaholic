#!/bin/sh -eu
# Turn one FB-worthy Slack message into the `[FB]` GitHub issue the loop already reads.
#
#   file-inbound-ask.sh --slack-ref <channel>:<ts> --permalink <url> \
#                       --subject '<kind>[:<identity>]' --assignee <login> \
#                       <owner/name> <title> <body-file>
#
# Emits open-issue.sh's own JSON, verbatim.
#
# WHY A WRAPPER AND NOT A CALL SITE (2026-08-23, the developer's instruction to drop the
# Claude Tag dependency). The sweep's dedup reads `slack-ref:` lines back out of issue
# bodies (list-swept-slack-refs.sh), so the line's format is load-bearing: two writers
# formatting it two ways is a dedup that silently stops matching. This script is the ONE
# writer of that marker. It prepends the header the receiving `/specificate` inherits —
# the same three-axis judgment every capture carries — plus the marker and the human's
# own permalink, then hands the composed body to feedback/scripts/open-issue.sh, which
# stays the one issue-opening seam (title stamping, assignee reporting, REST transport).
#
#   kind: <caller's> / source: slack / subject: <caller's>
#   slack-ref: <channel>:<ts>
#   slack-link: <permalink>
#
# `source: slack` is fixed here because it is what this wrapper means; `subject` is the
# caller's judgment — whose opinion the message is, normally `person:<display name>` —
# because the identity axis must never be defaulted to the machine that ran the capture.
#
# THE MENTION IS NOT REQUIRED, WHICH IS THE POINT: the message being filed was written by
# a person to the channel, not to any bot. The Claude Tag route required them to say
# `@Claude` and cost a tagged session per ask; this route reads the channel as the
# running identity and files the same `[FB]` issue the tag produced, so the deliverable
# is unchanged and the dependency is gone.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
OPEN_ISSUE="${SCRIPT_DIR}/../../feedback/scripts/open-issue.sh"

usage() {
  echo "Usage: file-inbound-ask.sh --slack-ref <channel>:<ts> --permalink <url> --subject '<kind>[:<id>]' --assignee <login> <owner/name> <title> <body-file>" >&2
  exit 1
}

slack_ref="" permalink="" subject="" assignee="" kind="feedback"
while [ $# -gt 0 ]; do
  case "$1" in
    --slack-ref) slack_ref="${2:?}"; shift 2 ;;
    --permalink) permalink="${2:?}"; shift 2 ;;
    --subject)   subject="${2:?}"; shift 2 ;;
    --assignee)  assignee="${2:?}"; shift 2 ;;
    --kind)      kind="${2:?}"; shift 2 ;;
    --*) usage ;;
    *) break ;;
  esac
done
[ $# -eq 3 ] || usage
slug="$1"; title="$2"; body_file="$3"

[ -n "$slack_ref" ] || { echo '{"ok": false, "error": "no_slack_ref"}'; exit 1; }
case "$slack_ref" in
  *:*) : ;;
  *) echo '{"ok": false, "error": "malformed_slack_ref"}'; exit 1 ;;
esac
[ -n "$subject" ] || { echo '{"ok": false, "error": "no_subject"}'; exit 1; }
[ -f "$body_file" ] || { echo '{"ok": false, "error": "body_file_missing"}'; exit 1; }

composed="$(mktemp)"
trap 'rm -f "$composed"' EXIT

{
  printf 'kind: %s / source: slack / subject: %s\n' "$kind" "$subject"
  printf 'slack-ref: %s\n' "$slack_ref"
  [ -n "$permalink" ] && printf 'slack-link: %s\n' "$permalink"
  printf '\n'
  cat "$body_file"
} > "$composed"

if [ -n "$assignee" ]; then
  sh "$OPEN_ISSUE" --assignee "$assignee" "$slug" "$title" "$composed"
else
  sh "$OPEN_ISSUE" "$slug" "$title" "$composed"
fi
