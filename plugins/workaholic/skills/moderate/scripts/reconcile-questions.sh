#!/bin/sh -eu
# Consume the completed moderation run and explicitly associated human answers.
# Usage: reconcile-questions.sh --input FILE
# Input: {tick,run:{steps:[]},answers:[{key,answer,source_ref,subject_verified,relation_confirmed}]}
#
# A QUESTION IS RETIRED ONLY ON A POSITIVE READING (2026-09-18, ticket `20260918080734`).
# This loop read `question-liveness.sh`'s `settled` — *the owning step ran and did not name
# this key* — and wrote `evidence: {proved: true, reason: "owning_step_resolved_premise"}` out
# of it. `settled` is an ABSENCE, so that is a proof asserted from a reading nobody made, the
# one shape `drive/reference/claims.md` forbids. It is now keyed on `resolution == "proved"`,
# the step's own statement that it resolved the key, and the evidence it writes names a reading
# that was actually made (`owning_step_reported_resolution` — a NEW word, so the old one stays
# unwritten from here on, which is what makes the reinstatement below self-terminating).
#
# EVERY OTHER RESOLUTION LEAVES THE ROW ALONE AND SAYS SO. A run report that implies an outcome
# by silence is how this went unnoticed for a whole class of question, so each untouched row
# appends `{"status":"not_retired","reason":"<resolution>","key":"<key>"}`.
#
# THE RESIDUE IS REPAIRED IN THIS SEAM, FIRST. The registry is per-clone runtime state under
# the Git common directory, so no pull request can carry a migration to it and every checkout
# must repair its own copy unattended. Measured on this repository: the only live question,
# `inbound-channel-unreadable:dev-workaholic`, read `state: retired` with `asked_tick: ""` —
# never asked and never askable again — while the channel it named was measurably unreadable
# in the same tick. `question-registry.sh`'s `reinstate` carries every bound; this walk only
# enumerates the rows that defect wrote.
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
jq -c '.data.questions[] | select(.state == "retired" and (.evidence.reason // "") == "owning_step_resolved_premise")' \
  "$tmp/registry" > "$tmp/residue"
while IFS= read -r row; do
  [ -n "$row" ] || continue
  printf '%s' "$row" | jq -c '{event:"reinstate",key:.key}' > "$tmp/request"
  sh "$SCRIPT_DIR/question-registry.sh" --input "$tmp/request" >> "$tmp/results"
done < "$tmp/residue"
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
  resolution=$(printf '%s' "$live" | jq -r '.resolution // "unknown"')
  if [ "$resolution" = proved ]; then
    jq -cn --arg key "$key" --arg step "$step" \
      '{event:"retire",key:$key,evidence:{proved:true,step:$step,reason:"owning_step_reported_resolution"}}' > "$tmp/request"
    sh "$SCRIPT_DIR/question-registry.sh" --input "$tmp/request" >> "$tmp/results"
  else
    jq -cn --arg key "$key" --arg reason "$resolution" \
      '{status:"not_retired",reason:$reason,key:$key}' >> "$tmp/results"
  fi
done < "$tmp/open"
jq -sc '{protocol:"workaholic.runtime/v1",request_id:"reconcile-questions",status:"ok",reason:"",data:{results:.}}' "$tmp/results"
