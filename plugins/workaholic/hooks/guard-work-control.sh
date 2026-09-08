#!/bin/sh -eu
# Native Claude Code backstop: a held/stopped coordinator cannot launch another worker.
# No registered /work instance means an ordinary interactive session and is unaffected.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
case "$session" in ''|*[!A-Za-z0-9._-]*|.|..) exit 0;; esac
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
[ -n "$cwd" ] && git -C "$cwd" rev-parse --git-common-dir >/dev/null 2>&1 || exit 0
state=$( (cd "$cwd" && sh "$SCRIPT_DIR/../skills/runtime/scripts/state.sh" read --scope instance --id "$session") 2>/dev/null || printf '{}')
deny() { printf 'Workaholic: %s\n' "$1" >&2; exit 2; }
printf '%s' "$state" | jq -e '.status=="ok"' >/dev/null 2>&1 || deny coordinator_unreadable
mode=$(printf '%s' "$state" | jq -r '.data.record.data.coordinator.mode // empty')
[ -n "$mode" ] || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
case "$tool" in
  AskUserQuestion) [ "$mode" = stopped ] || deny unattended_question; exit 0;;
  Agent|Task)
    [ "$mode" = running ] || deny "dispatch_$mode"
    receipt=$(printf '%s' "$input" | jq -r '.tool_input.prompt // "" | [scan("workaholic-receipt:([A-Za-z0-9][A-Za-z0-9._-]*)")] | .[0][0] // empty')
    [ -n "$receipt" ] || deny missing_dispatch_receipt
    printf '%s' "$state" | jq -e --arg receipt "$receipt" \
      '.data.record.data.coordinator.workers[$receipt].state=="reserved"' >/dev/null 2>&1 || deny receipt_not_reserved
    event=$(mktemp); trap 'rm -f "$event"' EXIT HUP INT TERM
    jq -cn --arg id "$receipt" '{event:"launch",id:$id,now:(now|floor)}' > "$event"
    launched=$( (cd "$cwd" && sh "$SCRIPT_DIR/../skills/runtime/scripts/coordinator.sh" --instance "$session" --input "$event") 2>/dev/null || printf '{}')
    printf '%s' "$launched" | jq -e '.status=="ok" and .reason=="launching"' >/dev/null 2>&1 || deny launch_not_reserved;;
esac
