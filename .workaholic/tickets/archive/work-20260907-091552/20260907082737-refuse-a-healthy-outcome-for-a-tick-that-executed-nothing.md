---
created_at: 2026-09-07T08:27:37+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: recover-the-codex-loop-from-a-retired-plugin-path-and-refuse-a-false-healthy-status
merge_policy:
verification_handoff: 
---

# Refuse a healthy outcome for a tick that executed nothing

## Overview

PROPOSED. The acknowledgement branch of the supervisor rewrites the tick's status file from the
relay verdict alone: on `relay == "delivered"` it sets `.state="sleeping"`, `.outcome="ready"`,
`.blocked_reason=""` and `.transport_verdict="parent_connector"` (`codex-loop.sh:427-431`). It
never reads whether the tick executed. Measured 2026-09-06 (#1052): a tick reported in words that
no tick had run and no worker had been dispatched, and the supervisor recorded `outcome: ready`
with a healthy transport anyway — so the one artifact an operator inspects said the loop was fine
while it was doing nothing.

The run already carries the right signal: the worker result schema has an `executed` field, and
`RESULT_CLAUSE` (`:60`) defines it as "true only if you actually read that command body and
performed it". `worker_outcome` (`:743-760`) validates the envelope's shape but the
acknowledgement path never consults it. This ticket makes a zero-exit response that says nothing
ran read as not-healthy.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the acknowledgement branch at
  `:419-437` (the false-healthy write), `write_status`/`write_worker` at `:503-575` (the atomic
  recorders, where `exit_status` and `outcome` are already kept separate on purpose), and
  `worker_outcome` at `:743-760`.
- `plugins/workaholic/skills/work/scripts/worker-result.schema.json` — where `executed` is
  declared; the field this ticket makes load-bearing.
- `plugins/workaholic/skills/work/scripts/relay-contract.sh` — `acknowledgement` and `reconcile`,
  which produce the `relay` word the branch keys on. A delivered *relay* and an executed *tick*
  are different facts; this is where that is established.
- `scripts/e2e/loop-drill.sh` and `docs/loop-drill-runbook.md` §9 — drill and register.

## Implementation Steps

1. **Reproduce it.** Drive the acknowledgement path with a status file whose tick executed
   nothing and a relay that reconciles to `delivered`, and record that the resulting status file
   reads `outcome: ready` with a healthy transport verdict. Baseline first.
2. **Localize it.** Establish which producers can reach `:427-431` with a non-executing tick —
   the acknowledgement branch is one; check whether any other writer sets a healthy outcome
   without reading `executed`, so the repair covers the class rather than the one line measured.
3. Decide the vocabulary: a tick that did not execute needs its **own** word, distinct both from
   `ready` and from `relay_incomplete` (which names an undelivered relay, a different fact).
   Follow the repository's existing habit of naming an absence rather than collapsing it.
4. Make `executed` load-bearing at every such writer: a delivered relay may set the relay fields,
   and may not by itself set a healthy `outcome` or `transport_verdict`.
5. Keep `exit_status` and `outcome` separate, as `:549-551` already records — a zero exit is not
   an execution, and that comment names the exact defect this ticket closes.
6. Breaker-backed drill: a tick that reports `executed: false` must never leave a healthy status
   file, whatever the relay says. Register it in §9.
7. `sh scripts/e2e/loop-drill.sh verify-all`; `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A tick whose worker reports `executed: false` never yields `outcome: ready`, and never yields a
  transport verdict asserting a reachable transport.
- The unhealthy state carries its own named word, distinguishable from `relay_incomplete`.
- A tick that genuinely executed and delivered its relay records exactly what it records today.

**Verification method** — the commands/tests/probes that prove them:

- The step-1 reproduction re-run against the recorded baseline.
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The new drill fails with the repair reverted.
- No reading is added that requires the `codex` CLI to be present.

## Considerations

- An unreadable `executed` is not a `false` one. A missing or malformed field should read as its
  own named absence, not as either health or failure — the repository's standing rule that a
  degraded read is named as degraded and never as a clean one.
- `relay_incomplete` already exists for an undelivered relay. Reusing it for a non-executing tick
  would merge two conditions that call for different acts, which is the collapse this ticket is
  closing rather than repeating.
- This overlaps ticket 1 of this mission: a tick against a retired path is one *cause* of a
  non-executing tick. They are kept separate because the false-healthy record is a defect even
  when the cause is something else entirely.

## Final Report

Development completed as planned.

The baseline was recorded first, and it reproduced all three halves of the class. An envelope
declaring `executed: false` with the reason *no tick ran*, reconciling to `delivered`, produced
`state=sleeping outcome=ready blocked_reason="" transport_verdict=parent_connector`. A tick whose
own classification had already recorded `work_blocked` was *upgraded* to `ready` by the same
branch. And an envelope carrying no `executed` field at all validated and was graded healthy.

Three seams changed, which is the whole class:

- `relay-contract.sh` requires `executed` as a boolean on the envelope, so the relay stops being
  the one path where a run's own execution is unstated. An envelope omitting it is
  `malformed_envelope`, which `classify_report` already grades `relay_malformed`.
- `classify_report`'s relay branch reads `executed` **before** the outcome and intent rungs, and a
  false reading records the new word `tick_not_executed` with `not_executed:<reason>` — the
  vocabulary `worker_outcome` already uses — and `transport_verdict=unknown`. The relay fields are
  still derived, because the parent may still acknowledge.
- The acknowledgement branch releases a healthy outcome only for an outcome the relay itself was
  withholding (`relay_pending`, or a tick already `ready`). Every other recorded outcome is carried
  through with its own `blocked_reason` and `transport_verdict` untouched; the state still moves to
  `blocked`, so a reader sees the relay closed and the tick still unhealthy.

### Discovered Insights

- **Insight**: `worker_outcome` already read `executed` and already had the word for a run that
  did not execute, but only the **non-relay** fall-through reached it. The relay path had a
  parallel classification with no such term, and the acknowledgement branch then overwrote
  whichever term either path had produced.
  **Context**: The repair was not to invent a reading — it was to make the existing one reachable
  on the second path and to stop a later writer discarding it. A search for *where is `executed`
  read* finds the healthy-looking answer and misses that a second producer never consults it.

- **Insight**: *The relay was delivered* and *the tick ran* are two facts, and the status file has
  separate fields for them. The defect was one writer setting both from one word.
  **Context**: The same shape recurs wherever a later stage rewrites an earlier stage's verdict.
  A stage may set what it observed; it may not upgrade what it did not.
