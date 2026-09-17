#!/bin/sh -eu
# Audit the repository's declared Slack binding. Pure read; writes nothing.
#
#   check-slack-binding.sh [repo-root] [--scope RELDIR]...
#
# ADVISORY, NEVER A GATE — the standing of every `/workaholify` check
# (`check-slack-channel.sh`). What it buys is that a missing, partial, or contradictory
# declaration is named BEFORE loop startup rather than discovered as a post that went to the
# wrong workspace, or as an hour of reads against a channel nobody meant.
#
# It reads the declaration and nothing else: it reaches no provider, opens no connection and
# proves no channel exists. Whether the declared route is actually reachable is
# `transport/scripts/describe-qfs.sh`'s question, and whether the channel is visible is
# `check-slack-channel.sh`'s; a declaration that is well formed and points nowhere passes here
# and fails there, which is the honest split.
#
# Output (one JSON line):
#   {"declared":true,"complete":true,"findings":[],"binding":{…},"reason":""}
#
# Findings, each its own word: `not_declared`, `incomplete_declaration` (a required key is
# missing), `contradictory_declaration` (two instruction files at one depth disagree),
# `invalid_declaration` (an operation or fallback transport nothing implements),
# `unknown_key` (a key the schema does not carry — usually a typo, which is silent otherwise),
# `unverifiable_sender` (no `sender_id`: a route can be selected but the account that speaks
# can never be proved), `unreadable:<source>`.

ROOT=${1:-.}
case "$ROOT" in --*) ROOT=. ;; *) [ $# -gt 0 ] && shift || true ;; esac
SCOPE_ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE_ARGS="${SCOPE_ARGS} --scope ${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

READER=$(CDPATH='' cd -- "$(dirname -- "$0")/../../transport/scripts" && pwd)/read-declared-binding.sh
[ -x "$READER" ] || [ -f "$READER" ] || { printf '{"declared":false,"complete":false,"findings":["reader_missing"],"reason":"reader_missing"}\n'; exit 0; }

# shellcheck disable=SC2086
declaration=$(sh "$READER" --root "$ROOT" $SCOPE_ARGS 2>/dev/null || printf '')
printf '%s' "$declaration" | jq -e . >/dev/null 2>&1 || { printf '{"declared":false,"complete":false,"findings":["reader_failed"],"reason":"reader_failed"}\n'; exit 0; }

printf '%s' "$declaration" | jq -c '
  . as $d |
  ([ if ($d.declared|not) then "not_declared" else empty end,
     ($d.errors[]? | "unreadable:" + .source),
     (if ($d.conflicts|length) > 0 then "contradictory_declaration" else empty end),
     (if ($d.declared and (($d.missing|length) > 0)) then "incomplete_declaration" else empty end),
     (if ($d.invalid|length) > 0 then "invalid_declaration" else empty end),
     ($d.unknown_keys[]? | "unknown_key:" + .),
     (if ($d.declared and (($d.binding.sender_id // "") == "")) then "unverifiable_sender" else empty end)
   ] | unique) as $findings |
  {declared:$d.declared, complete:$d.complete, findings:$findings,
   sources:$d.sources, binding:$d.binding, declared_digest:$d.declared_digest,
   conflicts:$d.conflicts, missing:$d.missing, invalid:$d.invalid,
   reason:$d.reason}'
