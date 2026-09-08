#!/bin/sh -eu
# Scaffold the repository's Slack binding declaration. Idempotent; appends, never rewrites.
#
#   apply-slack-binding.sh --root REPO --workspace W --channel C \
#     [--file AGENTS.md] [--channel-id C…] [--mount /slack/…] [--account LABEL] \
#     [--sender-id U…] [--operations "a,b"] [--fallback "connector"]
#
# The operator's instruction document is authoritative. This writes ONE fenced block into a
# file that carries no declaration yet, and refuses `already_declared` — writing nothing —
# the moment the reader finds one anywhere, at any scope. It never edits, reorders, reflows or
# removes a line the operator wrote; a declaration that is wrong is the operator's to change,
# because a setup step that silently rewrote a destination would be indistinguishable from
# posting to the wrong workspace on purpose.
#
# Output (one JSON line):
#   {"applied":true,"file":"AGENTS.md","created":false,"reason":""}
#   {"applied":false,"reason":"already_declared"|"no_workspace"|"no_channel"|"no_root"|"write_failed"}

ROOT="" FILE="AGENTS.md" WORKSPACE="" CHANNEL="" CHANNEL_ID="" MOUNT="" ACCOUNT="" SENDER="" OPERATIONS="" FALLBACK=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=${2:-}; shift 2 ;;
    --file) FILE=${2:-}; shift 2 ;;
    --workspace) WORKSPACE=${2:-}; shift 2 ;;
    --channel) CHANNEL=${2:-}; shift 2 ;;
    --channel-id) CHANNEL_ID=${2:-}; shift 2 ;;
    --mount) MOUNT=${2:-}; shift 2 ;;
    --account) ACCOUNT=${2:-}; shift 2 ;;
    --sender-id) SENDER=${2:-}; shift 2 ;;
    --operations) OPERATIONS=${2:-}; shift 2 ;;
    --fallback) FALLBACK=${2:-}; shift 2 ;;
    *) printf '{"applied":false,"reason":"invalid_argument"}\n'; exit 2 ;;
  esac
done
[ -n "$ROOT" ] && [ -d "$ROOT" ] || { printf '{"applied":false,"reason":"no_root"}\n'; exit 2; }
[ -n "$WORKSPACE" ] || { printf '{"applied":false,"reason":"no_workspace"}\n'; exit 2; }
[ -n "$CHANNEL" ] || { printf '{"applied":false,"reason":"no_channel"}\n'; exit 2; }
case "$FILE" in /*|*..*) printf '{"applied":false,"reason":"file_not_repo_relative"}\n'; exit 2 ;; esac

READER=$(CDPATH='' cd -- "$(dirname -- "$0")/../../transport/scripts" && pwd)/read-declared-binding.sh
existing=$(sh "$READER" --root "$ROOT" 2>/dev/null || printf '')
if printf '%s' "$existing" | jq -e '.declared == true' >/dev/null 2>&1; then
  printf '%s' "$existing" | jq -c '{applied:false, reason:"already_declared", sources:.sources}'
  exit 0
fi

TARGET="$ROOT/$FILE"
created=false
[ -f "$TARGET" ] || created=true

{
  [ "$created" = true ] && printf '# Agent instructions\n\nRepository guidance for every agent. See `CLAUDE.md` for the full standard.\n'
  printf '\n## Slack binding\n\nThe development loop reads this declaration before it selects any Slack route.\nOne destination, one speaking identity, one fallback order — declared once, here.\n\n'
  printf '```workaholic-slack-binding\n'
  printf 'workspace: %s\n' "$WORKSPACE"
  printf 'channel: %s\n' "$CHANNEL"
  [ -n "$CHANNEL_ID" ] && printf 'channel_id: %s\n' "$CHANNEL_ID"
  [ -n "$MOUNT" ] && printf 'mount: %s\n' "$MOUNT"
  [ -n "$ACCOUNT" ] && printf 'account: %s\n' "$ACCOUNT"
  [ -n "$SENDER" ] && printf 'sender_id: %s\n' "$SENDER"
  [ -n "$OPERATIONS" ] && printf 'operations: %s\n' "$OPERATIONS"
  [ -n "$FALLBACK" ] && printf 'fallback: %s\n' "$FALLBACK"
  printf '```\n'
} >>"$TARGET" || { printf '{"applied":false,"reason":"write_failed"}\n'; exit 1; }

jq -cn --arg file "$FILE" --argjson created "$created" '{applied:true, file:$file, created:$created, reason:""}'
