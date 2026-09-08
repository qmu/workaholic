#!/bin/sh -eu
# Consume the completed moderation run and explicitly associated human answers.
# Usage: reconcile-questions.sh --input FILE
# Input: {tick,run:{steps:[]},answers:[{key,answer,source_ref,subject_verified,relation_confirmed}]}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: reconcile-questions.sh --input FILE"
runtime_require_json_file "$2"; INPUT=$2
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
printf '{"event":"list"}' > "$tmp/request"
sh "$SCRIPT_DIR/question-registry.sh" --input "$tmp/request" > "$tmp/registry"
[ "$(jq -r .status "$tmp/registry")" = ok ] || { cat "$tmp/registry"; exit 0; }
jq '.run' "$INPUT" > "$tmp/run"
: > "$tmp/results"
jq -c '.answers[]?' "$INPUT" > "$tmp/answers"
while IFS= read -r answer; do
  if ! printf '%s' "$answer" | jq -e '.subject_verified == true and .relation_confirmed == true and
      (.source_ref|type=="string" and length>0) and (.key|type=="string" and length>0)' >/dev/null 2>&1; then
    printf '{"status":"deferred","reason":"answer_association_unproved"}\n' >> "$tmp/results"; continue
  fi
  key=$(printf '%s' "$answer" | jq -r .key)
  if ! jq -e --arg key "$key" '.data.questions[]|select(.key==$key)' "$tmp/registry" >/dev/null; then
    printf '{"status":"deferred","reason":"unknown_question"}\n' >> "$tmp/results"; continue
  fi
  words=$(printf '%s' "$answer" | jq -r .answer)
  sh "$SCRIPT_DIR/record-answer.sh" --tick "$(jq -r .tick "$INPUT")" --key "$key" --answer "$words" \
    --source "$(printf '%s' "$answer" | jq -r .source_ref)" >> "$tmp/results"
done < "$tmp/answers"
printf '{"event":"list"}' > "$tmp/request"
sh "$SCRIPT_DIR/question-registry.sh" --input "$tmp/request" > "$tmp/registry"
[ "$(jq -r .status "$tmp/registry")" = ok ] || { cat "$tmp/registry"; exit 0; }
jq -c '.data.questions[] | select(.state != "answered" and .state != "retired")' "$tmp/registry" > "$tmp/open"
while IFS= read -r q; do
  key=$(printf '%s' "$q" | jq -r .key); step=$(printf '%s' "$q" | jq -r '.step // empty')
  live=$(sh "$SCRIPT_DIR/question-liveness.sh" --key "$key" --step "$step" --run "$tmp/run")
  if [ "$(printf '%s' "$live" | jq -r .liveness)" = settled ]; then
    jq -cn --arg key "$key" --arg step "$step" \
      '{event:"retire",key:$key,evidence:{proved:true,step:$step,reason:"owning_step_resolved_premise"}}' > "$tmp/request"
    sh "$SCRIPT_DIR/question-registry.sh" --input "$tmp/request" >> "$tmp/results"
  fi
done < "$tmp/open"
jq -sc '{protocol:"workaholic.runtime/v1",request_id:"reconcile-questions",status:"ok",reason:"",data:{results:.}}' "$tmp/results"
