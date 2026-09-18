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
#
# AND THE REGISTRY IS MADE COMPLETE HERE, WITHOUT DEPENDING ON THE AGENT (2026-09-18, ticket
# `20260918131255`) — the walk below the reinstatement, before any question is offered. The full
# reasoning and the measurement are stated at that block.
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
# --- REGISTER EVERY QUESTION KEY THE RUN REPORT CARRIES -------------------------------------
# (2026-09-18, ticket `20260918131255`.) A question could be raised, held because nothing could
# deliver it, and then VANISH — unasked, unanswered and reported nowhere. Candidacy was derived
# per tick from the PRODUCING STEP'S OWN WINDOW, and the arrears that make a hold a delay rather
# than a loss were enumerated from per-key `human-checkin-held-<slug>` log lines the AGENT wrote
# by hand: a question whose step stopped offering it, and for which the agent wrote no per-key
# line, was enumerated by no reader in the tick at all.
#
# MEASURED: on 2026-09-17 one `questions-held` line named four keys and promised that "every key
# stays held and is offered again"; exactly ONE of the four got a per-key held line, and it is
# the only one of the four still reachable. `blocked-tick:20260904-085918` had no registry row at
# all — `ask-question.sh` registers before every gate, so an absent row means the gate was never
# called for that key — and the hour after the log gained a second tick it left `blocked-tick`'s
# candidate set for good, that step reading only *the tick before last* by a structural bound its
# header defends and this change does not touch.
#
# SO THE REGISTRATION IS MECHANICAL AND LIVES HERE, in the seam that already walks the run report
# once per tick. The refused alternative is a stricter instruction to the agent: that is what the
# contract already said, and the measured tick wrote one line out of four — a rule an unattended
# run can omit with nothing noticing is the failure this exists to remove.
#
# IT IS THE STEP ROW'S OWN ID THAT IS REGISTERED, which repairs the measured
# `step: direction-health`-for-every-key rows as a by-product: `register` merges the provided
# `step`, and the producing step is the one `question-liveness.sh` must read.
#
# NO KEY IS EVER GUESSED. Only the `key` field the steps already emit is read; a step row whose
# `needs_agent` carries no `key` yields nothing and is COUNTED (`no_question_key`). A key is never
# derived from a summary, a slug or a legacy log line.
#
# AN `answered` OR `retired` ROW IS NOT REGISTERED AT ALL, so it comes out byte-identical: the
# skip is the caller's, because `register` merges `step` onto whatever row it finds and would
# otherwise touch a row a person's own answer owns.
printf '{"event":"list"}' > "$tmp/request"
sh "$SCRIPT_DIR/question-registry.sh" --input "$tmp/request" > "$tmp/registry"
[ "$(jq -r .status "$tmp/registry")" = ok ] || { cat "$tmp/registry"; exit 0; }
jq -c '(.steps // [])[] | . as $row
       | {step: ($row.step // ""),
          keys: ([($row.needs_agent // []) | .. | objects | .key?
                  | select(type == "string" and length > 0)] | unique)}' "$tmp/run" > "$tmp/raised"
while IFS= read -r row; do
  [ -n "$row" ] || continue
  step=$(printf '%s' "$row" | jq -r '.step')
  [ -n "$step" ] || continue
  if [ "$(printf '%s' "$row" | jq -r '.keys | length')" = 0 ]; then
    jq -cn --arg step "$step" '{status:"ok",reason:"no_question_key",step:$step}' >> "$tmp/results"
    continue
  fi
  printf '%s' "$row" | jq -r '.keys[]' > "$tmp/rowkeys"
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    row=$(jq -c --arg key "$key" \
      '[.data.questions[] | select(.key == $key)] | first // {}' "$tmp/registry")
    state=$(printf '%s' "$row" | jq -r '.state // ""')
    case "$state" in
      answered|retired)
        jq -cn --arg key "$key" --arg step "$step" --arg state "$state" \
          '{status:"ok",reason:("skipped:" + $state),key:$key,step:$step}' >> "$tmp/results"
        continue ;;
    esac
    # A WRITE ONLY WHERE ONE WOULD CHANGE SOMETHING. The cost this seam accepts is one
    # revision-checked write per NEWLY SEEN key per tick; an unconditional `register` would spend
    # one per raised key per tick forever, bumping the revision on a record whose questions are
    # byte-identical and racing every other writer for nothing. The second condition is the step
    # repair: a row recorded against a step that never raised it is what made
    # `question-liveness.sh` answer about the wrong step, and it is corrected once and then never
    # written again.
    if [ -n "$state" ] && [ "$(printf '%s' "$row" | jq -r '.step // ""')" = "$step" ]; then
      jq -cn --arg key "$key" --arg step "$step" \
        '{status:"ok",reason:"already_known",key:$key,step:$step}' >> "$tmp/results"
      continue
    fi
    jq -cn --arg key "$key" --arg step "$step" '{event:"register",key:$key,step:$step}' > "$tmp/request"
    sh "$SCRIPT_DIR/question-registry.sh" --input "$tmp/request" > "$tmp/registered"
    if [ "$(jq -r '.status' "$tmp/registered")" = ok ]; then
      reason=registered
      [ -z "$state" ] || reason=already_known
      jq -cn --arg key "$key" --arg step "$step" --arg reason "$reason" \
        '{status:"ok",reason:$reason,key:$key,step:$step}' >> "$tmp/results"
    else
      cat "$tmp/registered" >> "$tmp/results"
    fi
  done < "$tmp/rowkeys"
done < "$tmp/raised"

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
