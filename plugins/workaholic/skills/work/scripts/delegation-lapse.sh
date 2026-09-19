#!/bin/sh -eu
# WHICH LOOP GUARANTEES LAPSE UNDER A DELEGATION RESTRICTION (2026-09-19, ticket
# `20260919095618`). Usage: delegation-lapse.sh --input <facts.json>
#
# The measured session: the operator turned subagents off. `skills/work/SKILL.md`'s Tick
# section says *never run those roles inline and never wait for them*, so with delegation gone
# the only way to make progress was to implement in the parent -- and the coordinator, still
# persisted and still running, stopped receiving role ticks. NOTHING ANYWHERE SAID THAT THIS
# TRADE HAD BEEN MADE. From the outside a loop whose observation clock had stopped looked like
# a loop that was busy.
#
# The repository had a vocabulary for a stop it could SEE -- the three reserved final-response
# events, and the precondition-stop obligation for a tick degraded into spawning nothing -- and
# a standing rule beside it that *a reading the coordinator could not make is never zero
# capacity*. An operator RESTRICTION is the same class of fact and had no treatment at all: it
# is not a degraded reading, so no existing word covered it. This reader is that word, and it
# is a reader only -- it writes nothing, starts nothing, and posts nothing.
#
# IT IS NOT A REFUSAL TO RUN. The operator restricted delegation for a real reason, and a loop
# that stops observing in protest helps nobody: the coordinator keeps observing and
# acknowledging and never becomes an inline implementer, which is why `coordinator_action` is
# `keep_observing` under every restriction this reader knows.
#
# Facts:
#   delegation      "available" | "refused"                                    (required)
#   context_policy  "full_conversation" | "bounded_task" | null    (default null: undeclared)
#
# Answers:
#   restriction           "none" | "delegation_refused" | "bounded_context"
#   guarantees            the closed list, in one place: what the loop advertises
#   lapsed                which of them stop holding under this restriction
#   held                  which of them still hold
#   costs                 a guarantee that holds at a stated cost, named with the cost
#   announce              true only when `lapsed` is non-empty -- a tick whose delegation is
#                         intact announces nothing new
#   signature             the precondition-stop signature to post under, or ""
#   coordinator_action    always "keep_observing": observation survives where it can
#
# The announcement reuses `workaholic:notify`'s EXISTING precondition-stop shape under this
# signature, with its dedup, escalation and cool-down unchanged. No new shape and no new
# transport. That class decides SEVERITY, never whether a stop is announced at all -- a
# misreading this repository has already paid for once, recorded in `workaholic:notify`.
#
# An operator restriction is not a degraded reading, and the two vocabularies stay apart: one
# is a person's decision, the other is something the loop could not see.
#
# Refusals (exit 2, nothing written): input_required, invalid_facts.

INPUT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --input) INPUT=${2:-}; shift 2 ;;
    *) printf '{"ok":false,"reason":"unknown_argument"}\n'; exit 2 ;;
  esac
done

[ -n "$INPUT" ] && [ -s "$INPUT" ] || { printf '{"ok":false,"reason":"input_required"}\n'; exit 2; }

if ! jq -e '
  type == "object" and
  (.delegation == "available" or .delegation == "refused") and
  ((.context_policy == null) or .context_policy == "full_conversation" or
   .context_policy == "bounded_task")
' "$INPUT" >/dev/null 2>&1; then
  printf '{"ok":false,"reason":"invalid_facts"}\n'
  exit 2
fi

# THE CLOSED LIST LIVES HERE AND IS CITED ELSEWHERE. These are the four properties the loop
# advertises, and naming them once is what lets a restriction say WHICH of them it costs
# instead of "some guarantees may be affected", which is worse than saying nothing.
jq -c '
  ["observation_clock","acknowledgement_on_cadence",
   "work_advances_without_waiting","separable_worker_evidence"] as $all
  | (if .delegation == "refused" then "delegation_refused"
     elif .context_policy == "bounded_task" then "bounded_context"
     else "none" end) as $restriction
  | (if $restriction == "delegation_refused"
     then ["work_advances_without_waiting","separable_worker_evidence"]
     else [] end) as $lapsed
  | (if $restriction == "bounded_context"
     then ["separable_worker_evidence: a bounded child knows less and can therefore claim less — its finish is evidence for the parent, never automatic permission"]
     else [] end) as $costs
  | {ok:true, restriction:$restriction, guarantees:$all,
     lapsed:$lapsed,
     held:[$all[] | . as $g | select(any($lapsed[]; . == $g) | not)],
     costs:$costs,
     announce:(($lapsed|length) > 0),
     signature:(if ($lapsed|length) > 0 then ("delegation-restricted:" + $restriction) else "" end),
     coordinator_action:"keep_observing", reason:""}
' "$INPUT"
