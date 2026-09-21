---
created_at: 2026-09-21T18:02:08+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260921180138-a-native-work-loop-must-not-end-after-an-ordinary-progress-report.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260921-204131
---

# Prove a live continuation before a routine turn yields

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from a
     proposal into queued work. -->

A native `/work` parent repeatedly stops after emitting a final response that reports a
completed subset of work, while accepted work and observation remain. The operator's ask
(issue #1260) names the cause precisely: persisting `control: running` is not sufficient once
the host turn has ended and no interruptible wait remains.

**Diagnosis first — what this run measured, before proposing a mechanism.**

`work/scripts/final-response-contract.sh` already refuses a routine turn that names no
continuation (`continuation_unproved`), and its `invalid_facts` assertion already requires a
named continuation to carry a `kind` from the closed set, a non-empty `id` and a numeric
`next_due`. **It never compares `next_due` against the moment of the turn.** So a continuation
whose deadline has already passed satisfies the contract, the reader answers
`path: "resume", final_response: false`, and the turn yields to nothing.

`runtime/scripts/lib/coordinator.jq` already makes exactly that comparison at every event:
`resumed` is false with `resumed_reason: "continuation_lapsed"` when
`continuation.next_due < $e.now`. **The derivation exists and the final-response gate does not
consult it.** The repair is therefore to read the derivation the repository already holds at
the one seam that yields the turn — not to invent a second liveness authority.

Second, the contract owns the turn's facts but carries **no fact describing what the turn
intends to emit**. `final_response` is an *answer*, so a run that emits a routine final response
anyway is invisible to the reader and the contract cannot fail closed on the act the ask names.
A declared intent fact is what makes the refusal reachable, in exactly the shape
`interruption_kind` and `blocked_on` already have: a fact the run writes out, classified by
nobody and read from no sentence.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — a refusal is named, never silent
- `workaholic:operation` / `policies/observability.md` — the recorded event sequence is the evidence

## Key Files

- `plugins/workaholic/skills/work/scripts/final-response-contract.sh` — the reader that owns the
  turn's facts. Gains a `now` fact and the liveness term, and the intent fact and its refusal.
- `plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq` — holds the existing
  `continuation_lapsed` derivation (`next_due < now`). The source of the rule; read, not
  duplicated.
- `plugins/workaholic/skills/work/SKILL.md` — the contract's prose home; states the three
  reserved final-response events and must state the liveness and fail-closed terms.
- `plugins/workaholic/commands/infinite-development.md` and
  `plugins/workaholic/commands/work.md` — the two ceilings a routine-fired session reads; they
  carry the continuation wording today and must carry the added terms in **one** wording.
- `scripts/tests/agentic-loop/native-coordinator.test.mjs` — where the regression test the ask
  names belongs.
- `CLAUDE.md` — Architecture Policy states the continuation contract in prose; update in the
  same change.

## Implementation Steps

1. **Reproduce before changing anything.** Drive `final-response-contract.sh` with
   `interruption_kind: "routine"` and a continuation whose `next_due` is in the past; record
   that it answers `ok: true, path: "resume"`. Drive `coordinator.jq` with the same
   continuation and record that it answers `resumed: false,
   resumed_reason: "continuation_lapsed"`. Both readings go in the branch story — the
   divergence between the two readers is the defect.
2. **Add the `now` fact** to the reader's input schema (epoch seconds, integer, `>= 0`),
   asserted in the same `invalid_facts` program as every other fact. Decide and state in the
   script header whether an absent `now` is refused or defaults; prefer **required on any input
   naming a continuation**, so a caller cannot obtain a pass by omitting the clock.
3. **Add the liveness term** to the refusal ladder: a `routine` turn whose named continuation
   has `next_due < now` is refused **`continuation_lapsed`** — the word `coordinator.jq`
   already emits, never a second spelling. Place it immediately after the existing
   `continuation_unproved` rung so *named nothing* and *named something already dead* stay
   distinguishable. Nothing is written on the refusal and stdout stays JSON with exit 2.
4. **Add the intent fact and fail closed.** Take a boolean fact naming what the turn intends to
   emit (default `false`, so every existing caller is byte-identical), and refuse a `routine`
   turn that declares it. The three reserved events keep their current paths: `review_required`
   still answers `final_response: true`, and `task_review` and `routine` still answer `false`.
   Give the refusal its own word and add it to the header's refusal list.
5. **Do not widen the closed sets.** `interruption_kind` keeps its three values, `continuation.kind`
   its two, `blocked_on` its three; `path` gains no fourth value. This change adds facts and
   refusals only.
6. **Write the regression test** in `native-coordinator.test.mjs`: a completed worker recorded
   through `coordinator.sh finish`, then a progress report classified `routine`, then continued
   observation — asserting on the **recorded event sequence** and never on elapsed time, the
   rule `verify-observation-during-work` already holds. Cover the lapsed continuation, the
   declared-intent refusal, and the live-continuation pass, and assert no second `start` and no
   moved anchor.
7. **Carry one wording** into `skills/work/SKILL.md` and both command ceilings, and update
   `CLAUDE.md`'s Architecture Policy paragraph in the same commit. If the suite pins these
   surfaces byte-identically, extend that pin to the added terms rather than letting a second
   wording exist.
8. **Run the local proof set** (`branching/scripts/local-proof.sh`) and report `ok`, `complete`
   and every `not_run` row.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `routine` turn naming a continuation whose `next_due` is in the past is refused
  `continuation_lapsed`, with nothing written and exit 2.
- A `routine` turn declaring an intent to emit a final response is refused by its own named
  word, with nothing written and exit 2.
- `review_required` still answers `final_response: true` with the one question, and
  `task_review` and `routine` still answer `false`; `path` gains no fourth value and no closed
  set widened.
- Every existing caller that passes no intent fact behaves byte-identically.
- A regression test covers completed worker → progress report → continued observation with no
  second human message, asserting on the recorded event sequence and not on elapsed time.
- `continuation_lapsed` is spelled once as a rule: the reader and `coordinator.jq` do not carry
  two independent comparisons of `next_due` against a clock.

**Verification method** — the commands/tests/probes that prove them:

- `node --test scripts/tests/agentic-loop/native-coordinator.test.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-observation-during-work`
- `bash plugins/workaholic/skills/branching/scripts/local-proof.sh`

**Gate** — what must pass before approval:

- The local proof set reports `ok: true`, and every `not_run` row is named with its reason.
- The measured before/after readings from step 1 appear in the branch story.

## Considerations

- **The liveness rule must have one home.** `coordinator.jq` already owns `next_due < now`. If
  the reader cannot compose that program directly, state in both files that the comparison is
  one rule with two call sites and pin it in the suite — a second liveness authority beside the
  branch-tip/continuation pair is exactly what this repository refuses for the heartbeat.
- **Fail closed is a refusal, not a silent suppression.** The reader writes nothing, ever; it
  cannot stop a run from emitting text. What the refusal buys is that a run which asks the
  contract gets an unambiguous *no* with a name, and a run that emits anyway leaves a receipt
  that says the contract refused. Say that plainly in the header rather than implying the reader
  can prevent the act.
- **Stated cost.** Requiring `now` on any continuation-naming input is a tightened constraint on
  callers. Every call site in the tree must be updated in the same change, and the suite should
  fail on a caller that names a continuation without a clock.
- **Alternative weighed and rejected:** making the *coordinator* refuse at `finish` when the
  continuation has lapsed. Rejected because the turn has already yielded by then — the ask asks
  for the check *immediately before the turn yields*, which is this reader's seam and no other.
