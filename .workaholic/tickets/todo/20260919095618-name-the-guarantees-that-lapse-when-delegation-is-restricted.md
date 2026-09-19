---
created_at: 2026-09-19T09:56:18+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: dispatch-bounded-workers-without-stopping-the-observation-clock
merge_policy:
verification_handoff:
---

# Name the guarantees that lapse when delegation is restricted

## Overview

Operator's ask: **issue #1142** — *when delegation is disallowed, explicitly explain which
work-loop guarantees cannot be maintained; retain observation if possible rather than silently
replacing the coordinator with a long inline implementation turn*, and *preserve the coordinator
instance and startup anchor when changing dispatch policy; reconcile live children and receipts so
resumption neither creates a second clock nor duplicates work.*

**What the measured session did.** The operator turned subagents off. `skills/work/SKILL.md`'s
Tick section states *never run those roles inline and never wait for them*; with delegation gone
the only way to make progress was to implement in the parent, so the session did — and the
coordinator, still persisted and still running, stopped receiving role ticks. Nothing anywhere
said that this trade had been made. From the outside a loop whose observation clock had stopped
looked like a loop that was busy.

**What already exists, and what is missing.** The repository has a well-developed vocabulary for a
stop it *can* see: `work/scripts/final-response-contract.sh` reserves the parent's final response
for three events, and the precondition-stop post shape (2026-09-08) obliges a tick that spawned no
runner because something was degraded to say so on the channel under its own signature. There is
also a standing rule beside it: *a reading the coordinator could not make is never zero capacity.*
**A restriction the operator imposed is the same class of fact and has no such treatment** — it is
not a degraded reading, so no existing word covers it, and the tick has no obligation to name it.
The startup anchor and the receipts are handled for compaction and correction (*a correction does
not reset the startup anchor*, *after compaction, rediscover children*) but nothing covers a
**policy change** mid-loop.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/observability.md` — the governing policy: a loop running
  with a guarantee suspended must not be observationally identical to one running with it intact
- `workaholic:implementation` / `policies/test.md` — the vocabulary and the anchor invariant are
  pinned; the judgement is not

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` (Tick; *Children and reports*) — the *never inline,
  never wait* rule and the receipt lifecycle; the lapse vocabulary lands beside them.
- `plugins/workaholic/skills/work/scripts/final-response-contract.sh` — the three reserved events
  and the resume contract; read it in full to place this without adding a fourth event.
- `plugins/workaholic/commands/infinite-development.md` — the coordinator ceiling, the
  precondition-stop post obligation and the tick report; the wording must match `work/SKILL.md`
  byte for byte.
- `plugins/workaholic/skills/notify/SKILL.md` — the post shapes and the precondition-stop class.
  **Read its own note that the class decides severity, never whether a stop is announced**: that
  misreading already cost a wrong diagnosis once, and this ticket must not repeat it.
- `plugins/workaholic/skills/runtime/scripts/coordinator.sh` — receipts, instance and anchor; the
  reconciliation across a policy change happens through this and nothing new.
- `plugins/workaholic/skills/runtime/scripts/reconcile-turn.sh` — the existing reconciliation.
- `scripts/tests/agentic-loop/*.test.mjs` — the coordinator contracts.

## Implementation Steps

1. **Read the three existing contracts in full first** — the final-response contract, the
   precondition-stop obligation and the receipt lifecycle — and record which of them a
   delegation restriction already reaches. Design only for what none of them covers.
2. **Name the guarantees, as a short closed list.** The candidates are exactly the properties the
   loop advertises: an independent observation clock, acknowledgement on cadence, work advancing
   without the parent waiting, and a worker's result being separable evidence. Write them once, in
   `work/SKILL.md`, and cite them from the ceiling.
3. **State the lapse per restriction, not in general.** Full delegation refused: which of those
   four stop holding, and which still hold. Bounded context: which hold with a stated cost. A
   sentence that says *some guarantees may be affected* is worse than nothing.
4. **Observation survives where it can, and the loop says which it chose.** When delegation is
   refused, the coordinator keeps observing and acknowledging and does **not** become an inline
   implementer; if the operator wants inline work, that is their instruction and the loop names
   the lapse rather than performing it silently.
5. **Announce it once, through the shape that already exists.** A tick running with a guarantee
   suspended posts under the existing precondition-stop shape with its own signature, honouring
   the existing dedup, escalation and cool-down. Add no new shape and no new transport.
6. **Preserve instance, anchor and receipts across a policy change.** Changing the dispatch policy
   is a correction, not a restart: same instance id, same startup anchor, no second `start`, and
   live children reconciled through `coordinator.sh` so nothing is duplicated and no second clock
   appears. State this in the same place the correction rule is already stated.
7. **Contract tests** in `scripts/tests/agentic-loop/`: a policy change mid-loop leaves the
   instance id and anchor unchanged and issues no second `start`; live receipts survive it; a
   refused delegation produces the lapse report naming specific guarantees; and a tick whose
   delegation is intact produces none.
8. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`,
   `node --test scripts/tests/agentic-loop/*.test.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The guarantees are a named closed list, written once and cited, never restated.
- A restriction names **which** guarantees lapse; no general "may be affected" wording appears.
- A refused delegation keeps observation and acknowledgement running and does not turn the
  coordinator into an inline implementer.
- A policy change preserves the instance id and the startup anchor, issues no second `start`, and
  leaves live receipts reconciled — no duplicated work, no second clock.
- The announcement reuses the existing precondition-stop shape: no new shape, no new transport, and
  the existing dedup/cool-down behaviour is unchanged.
- A tick with delegation intact announces nothing new.

**Verification method** — the commands/tests/probes that prove them:

- `node --test scripts/tests/agentic-loop/*.test.mjs` is green and the new contracts fail when
  reverted.
- `node scripts/test-workflow-scripts.mjs` is green, including the byte-identical wording pair
  between the ceiling and `work/SKILL.md`.
- A fixture policy change shows identical instance id and anchor before and after.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- No fourth reserved final-response event is added; the lapse is commentary and a channel post,
  not a reason to end the parent's turn.
- The suite is green and the bundle rebuild is diff-clean.
- POSIX `sh` throughout.

## Considerations

- **The tempting error is to refuse to run at all when a guarantee lapses.** That is worse than
  the defect: the operator restricted delegation for a real reason, and a loop that stops
  observing in protest helps nobody. Name it and keep observing.
- **Do not widen the precondition-stop class to mean "any stop".** `workaholic:notify` records
  that the class decides **severity** and never whether a stop is announced; a change that blurs
  that would re-introduce a misdiagnosis this repository has already paid for once.
- **An operator restriction is not a degraded reading**, and the vocabulary should keep them
  apart: one is a person's decision and the other is something the loop could not see.

## Final Report

Development completed as planned.

The three existing contracts were read in full first. `final-response-contract.sh` reserves the
parent's final response for three events and reaches a delegation restriction not at all;
`commands/infinite-development.md`'s precondition-stop obligation covers a tick **degraded** into
spawning nothing; `lib/coordinator.jq` owns the receipt lifecycle and already answers
`already_started` to a second `start`. None of them covers an operator restriction, which is a
person's decision rather than something the loop could not see — so the vocabularies stay apart
and this adds one reader, no shape and no transport.

`work/scripts/delegation-lapse.sh` is that reader. The four guarantees are a closed list written
once in `work/SKILL.md` — `observation_clock`, `acknowledgement_on_cadence`,
`work_advances_without_waiting`, `separable_worker_evidence` — and the lapse is stated **per
restriction**: a refused delegation lapses the last two and holds the first two, a bounded
context holds all four at one stated cost, and no restriction announces nothing new. `announce`
is true **only** when `lapsed` is non-empty, which is what makes *a tick with delegation intact
announces nothing new* mechanical rather than a sentence. `coordinator_action` is
`keep_observing` under every restriction: the coordinator never becomes an inline implementer,
and inline work stays the operator's own instruction. The announcement reuses the existing
precondition-stop shape under the reader's own `signature`, with dedup, escalation and cool-down
untouched, and no fourth reserved final-response event exists.

Verified: `node --test scripts/tests/agentic-loop/delegation-lapse.test.mjs` (5 rows, including
the policy-change invariant — same instance, same anchor, `already_started` on a second `start`,
the live receipt surviving with the policy it was launched under) and
`node scripts/test-workflow-scripts.mjs "delegation restriction"` (11 rows).

### Discovered Insights

- **Insight**: the ceiling and `work/SKILL.md` both have to *quote* the forbidden sentence in
  order to forbid it, so a regex ban on "may be affected" cannot tell a prohibition from the
  thing prohibited.
  **Context**: the pin is written as a positive assertion — each surface must carry its own
  prohibition wording — which is the shape any "this phrasing is banned" rule needs here.
- **Insight**: `implement`'s fanout is 1, so a second `reserve` for that role answers
  `role_running` rather than `reserved`.
  **Context**: a contract row about the anchor or the receipt lifecycle must use a second role,
  or it measures the fanout instead of the thing it meant to.
