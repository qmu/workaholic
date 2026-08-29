#!/bin/sh -eu
# Turn one FB-worthy Slack message into the `[FB]` GitHub issue the loop already reads.
#
#   file-inbound-ask.sh --slack-ref <channel>:<ts> --permalink <url> \
#                       --subject '<kind>[:<identity>]' --assignee <login> \
#                       [--feedback '<ref>[, <ref>]'] \
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
#   feedback: <ref>, <ref>
#
# THE `feedback:` LINE IS THE DIRECTION THIS ASK ANSWERS (2026-08-26). The sweep is the
# loop's own writer and its majority inbound path, and until this line existed the issue it
# filed carried no direction at all — so work born on the channel intersected every
# strategy's `feedback[]` at NOTHING. Measured 2026-08-26 on this repository: the
# developer's 11:08 JST message became issue #604, `/specificate` emitted a five-ticket
# mission from it, and `attributed-work.sh` still reported that strategy's
# `waiting_count: 0` — so `/propose`'s in-flight brake stood open over a whole queued
# mission.
#
# It carries the strategy's own REFS, never its slug, because `attributed-work.sh` walks
# `strategy.feedback[] n artifact.feedback[]` and nothing here may add a second relation.
# It is emitted by `feedback/scripts/ask-feedback-line.sh` — the ONE writer of this line,
# shared with `open-proposal.sh` — and an ABSENT flag emits no line at all, leaving the
# composed body byte-identical to what it was before the flag existed. An ask that answers
# no live direction is an ordinary outcome, never forced into one.
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
#
# A SECOND MARKER, FOR A SECOND CALLER (2026-08-29, mission
# `let-the-tick-s-own-findings-become-the-loop-s-work`). `/moderate`'s `file-findings` step
# turns a REPAIRABLE finding of the tick into the same `[FB]` issue, and its dedup reads its
# own marker back out of the issues exactly as the sweep's does. So this script — already the
# ONE writer of a marker, which is what keeps a dedup from silently stopping to match —
# gains `--finding <step id>:<finding id>` beside `--slack-ref`, writing:
#
#   kind: <caller's> / source: moderate / subject: <caller's>
#   finding: <step id> / id: <finding id>
#
# EXACTLY ONE OF THE TWO is required, and the pair is mutually exclusive: a finding is not a
# channel message and an issue claiming to be both would be read by two dedups. `source` is
# fixed per marker because it is what the wrapper MEANS on each route — `slack` for a message
# a person wrote, `moderate` for a finding the tick made — while `subject` stays the caller's
# judgment on both, because the identity axis must never be defaulted to the machine.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
OPEN_ISSUE="${SCRIPT_DIR}/../../feedback/scripts//open-issue.sh"
ASK_FEEDBACK_LINE="${SCRIPT_DIR}/../../feedback/scripts//ask-feedback-line.sh"

usage() {
  echo "Usage: file-inbound-ask.sh (--slack-ref <channel>:<ts> [--permalink <url>] | --finding <step>:<id>) --subject '<kind>[:<id>]' --assignee <login> [--feedback '<ref>[, <ref>]'] <owner/name> <title> <body-file>" >&2
  exit 1
}

slack_ref="" permalink="" subject="" assignee="" kind="feedback" feedback="" finding=""
while [ $# -gt 0 ]; do
  case "$1" in
    --slack-ref) slack_ref="${2:?}"; shift 2 ;;
    --finding)   finding="${2:?}"; shift 2 ;;
    --permalink) permalink="${2:?}"; shift 2 ;;
    --subject)   subject="${2:?}"; shift 2 ;;
    --assignee)  assignee="${2:?}"; shift 2 ;;
    --kind)      kind="${2:?}"; shift 2 ;;
    --feedback)  feedback="${feedback:+${feedback}, }${2:?}"; shift 2 ;;
    --*) usage ;;
    *) break ;;
  esac
done
[ $# -eq 3 ] || usage
slug="$1"; title="$2"; body_file="$3"

# Exactly one marker: an issue claiming to be both a channel message and a tick finding would
# be matched by two dedups, and one that claims to be neither is invisible to both.
if [ -n "$slack_ref" ] && [ -n "$finding" ]; then
  echo '{"ok": false, "error": "two_markers"}'; exit 1
fi
source_axis="slack"
if [ -n "$finding" ]; then
  source_axis="moderate"
  case "$finding" in
    *:*) : ;;
    *) echo '{"ok": false, "error": "malformed_finding_ref"}'; exit 1 ;;
  esac
else
  [ -n "$slack_ref" ] || { echo '{"ok": false, "error": "no_slack_ref"}'; exit 1; }
  case "$slack_ref" in
    *:*) : ;;
    *) echo '{"ok": false, "error": "malformed_slack_ref"}'; exit 1 ;;
  esac
fi
[ -n "$subject" ] || { echo '{"ok": false, "error": "no_subject"}'; exit 1; }
[ -f "$body_file" ] || { echo '{"ok": false, "error": "body_file_missing"}'; exit 1; }

composed="$(mktemp)"
trap 'rm -f "$composed"' EXIT

{
  printf 'kind: %s / source: %s / subject: %s\n' "$kind" "$source_axis" "$subject"
  if [ -n "$finding" ]; then
    printf 'finding: %s / id: %s\n' "${finding%%:*}" "${finding#*:}"
  else
    printf 'slack-ref: %s\n' "$slack_ref"
    # An explicit `if` rather than the `&&` this line used to be: it is now the last command
    # of a branch, and under `set -e` a bare failing test there would abort the composition.
    if [ -n "$permalink" ]; then printf 'slack-link: %s\n' "$permalink"; fi
  fi
  [ -n "$feedback" ] && sh "$ASK_FEEDBACK_LINE" "$feedback"
  printf '\n'
  cat "$body_file"
} > "$composed"

if [ -n "$assignee" ]; then
  sh "$OPEN_ISSUE" --assignee "$assignee" "$slug" "$title" "$composed"
else
  sh "$OPEN_ISSUE" "$slug" "$title" "$composed"
fi
