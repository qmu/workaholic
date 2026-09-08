#!/bin/sh -eu
# Durable question identity and answers, independent of moderation-log retention.
# Usage: question-registry.sh --input FILE (event=list|register|asked|answer|retire)
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
