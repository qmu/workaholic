#!/bin/sh -eu
# Durable question identity and answers, independent of moderation-log retention.
# Usage: question-registry.sh --input FILE (event=list|register|asked|answer|retire|reinstate)
#
# `retire`'s GUARD IS CORRECT AND DOES NOT MOVE (2026-09-18, ticket `20260918080734`).
# `evidence.proved != true -> error` is the right floor; what was wrong was a caller
# manufacturing that flag out of an absence, and the repair is there (`reconcile-questions.sh`
# retires only on `question-liveness.sh`'s `resolution == "proved"`). No second retirement path
# is added here.
#
# `reinstate` REPAIRS THE ROWS THAT DEFECT ALREADY WROTE, and nothing else. The registry is
# per-clone runtime state under the Git common directory — uncommitted, and unreachable by any
# migration a pull request could carry — so every checkout must repair its own copy unattended.
# It restores `candidate` and NEVER `asked`: the question was never asked, and spending the
# asked-once ledger line on a question nobody heard is the failure that gate exists to prevent.
# Each bound refuses `deferred` with its own word and nothing written: an `answered` row is
# never touched (a person's own words outrank this repair), and any other `evidence.reason`, a
# row with no evidence, a row not retired at all and an unknown key are each named. It is
# idempotent — after one run no row carries the old word, so a second run finds nothing.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
RUNTIME="$SCRIPT_DIR/../../runtime/scripts"
. "$RUNTIME/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: question-registry.sh --input FILE"
runtime_require_json_file "$2"
INPUT=$2
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
attempt=0
while [ "$attempt" -lt 3 ]; do
  attempt=$((attempt+1))
  sh "$RUNTIME/state.sh" read --scope instance --id questions > "$tmp/read"
  [ "$(jq -r .status "$tmp/read")" = ok ] || { cat "$tmp/read"; exit 0; }
  # `reinstate`'s bounds refuse BEFORE any write is composed, so a refusal leaves the record
  # byte-identical and answers with its own word rather than an `invalid_input` error.
  if [ "$(jq -r '.event // ""' "$INPUT")" = reinstate ] && [ -n "$(jq -r '.key // ""' "$INPUT")" ]; then
    refusal=$(jq -r --slurpfile old "$tmp/read" --arg key "$(jq -r .key "$INPUT")" -n '
      (($old[0].data.record.data.questions // {})[$key]) as $row |
      if $row == null then "unknown_question"
      elif $row.state == "answered" then "answered_row"
      elif $row.state != "retired" then "not_retired:\($row.state // "")"
      elif ($row.evidence.reason // "") != "owning_step_resolved_premise" then "evidence_not_repairable"
      else "" end')
    if [ -n "$refusal" ]; then
      runtime_json_result deferred "$refusal" questions "$(jq -cn --arg key "$(jq -r .key "$INPUT")" '{reinstated:false,key:$key}')"
      exit 0
    fi
  fi
  jq -n --slurpfile old "$tmp/read" --slurpfile input "$INPUT" '
    ($old[0].data.record.data.questions // {}) as $q | $input[0] as $e |
    if $e.event == "list" then $q
    elif ($e.key|type != "string" or length==0) then error("key required")
    elif $e.event == "register" then
      $q | .[$e.key] = ((.[$e.key] // {key:$e.key,state:"candidate"}) +
        ($e|{step,coordinate,subject}|with_entries(select(.value != null and .value != ""))))
    elif $e.event == "asked" then
      if $q[$e.key] == null then error("register question first")
      elif ($q[$e.key].state == "answered" or $q[$e.key].state == "retired") then $q else
      $q | .[$e.key] += {state:"asked",asked_at:$e.now,coordinate:($e.coordinate // "")} end
    elif $e.event == "answer" then
      if ($e.answer|type != "string" or length==0) then error("answer required") else
      $q | .[$e.key] = ((.[$e.key] // {key:$e.key}) +
        {state:"answered",answer:$e.answer,source:($e.source // "session"),answered_at:$e.now}) end
    elif $e.event == "retire" then
      if $q[$e.key] == null or $e.evidence.proved != true then error("proved premise resolution required") else
      $q | if .[$e.key].state == "answered" then . else
        .[$e.key] += {state:"retired",evidence:$e.evidence} end end
    elif $e.event == "reinstate" then
      if ($q[$e.key].state != "retired"
          or ($q[$e.key].evidence.reason // "") != "owning_step_resolved_premise")
      then error("reinstate bounds not met") else
      $q | .[$e.key] = (.[$e.key] | del(.evidence) | .state = "candidate") end
    else error("invalid event") end' > "$tmp/questions" 2> "$tmp/error" || runtime_usage "$(cat "$tmp/error")"
  if [ "$(jq -r .event "$INPUT")" = list ]; then
    runtime_json_result ok "" questions "$(jq -c '{questions:[.[]]}' "$tmp/questions")"; exit 0
  fi
  jq -n --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --slurpfile q "$tmp/questions" \
    '{updated_at:$now,data:{questions:$q[0]}}' > "$tmp/write"
  if [ "$(jq -r .data.found "$tmp/read")" = false ]; then
    sh "$RUNTIME/state.sh" create --scope instance --id questions --input "$tmp/write" > "$tmp/result"
  else
    revision=$(jq -r .data.record.revision "$tmp/read")
    sh "$RUNTIME/state.sh" update --scope instance --id questions --expected-revision "$revision" --input "$tmp/write" > "$tmp/result"
  fi
  [ "$(jq -r .reason "$tmp/result")" = revision_conflict ] || break
done
cat "$tmp/result"
