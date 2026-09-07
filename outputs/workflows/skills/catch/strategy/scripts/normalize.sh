#!/bin/sh -eu
# Normalize legacy comma-separated strategy fields at the snapshot boundary.
# The legacy list/read scripts and their output remain unchanged.
INPUT=""
[ "${1:-}" = --input ] && INPUT=${2:-} || { echo 'usage: normalize.sh --input FILE' >&2; exit 2; }
[ -f "$INPUT" ] && jq -e 'type=="object"' "$INPUT" >/dev/null 2>&1 || { echo 'strategy input must be a JSON object' >&2; exit 2; }
jq -c '
  def csv:
    if type=="string" then [split(",")[]|gsub("^[ \\t]+|[ \\t]+$";"")|select(length>0)]
    elif type=="array" then . else [] end;
  def normalized:
    .assignees=(.assignees // [] | csv)
    | if has("feedback") then .feedback=(.feedback|csv) else . end
    | if has("readable") then . else .readable=true end;
  if has("strategies") then .strategies|=map(normalized) | if has("readable") then . else .readable=true end else normalized end' "$INPUT"

