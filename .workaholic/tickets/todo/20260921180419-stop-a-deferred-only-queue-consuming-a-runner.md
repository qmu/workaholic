---
created_at: 2026-09-21T18:04:19+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
mission: hold-operator-deferred-tickets-out-of-the-offer-and-say-so
depends_on: [20260921180418-name-a-deferred-ticket-in-the-survey-exclusions.md]
feedback: []
merge_policy:
verification_handoff: 
---

# Stop a deferred-only queue consuming a runner

## Overview

The ask's last sentence: *a queue containing only operator-deferred work should not be treated
as implementation failure or consume an implementation runner.* That is a reading one layer
above the survey, and it is its own ticket because it is its own class of error.

**The hazard is the fallback, and it points the wrong way here.**
`loops/scripts/claimable-units.sh` states in its own header that a `readable: false` reading
falls back to **one** runner and is reported — correct, because an unreadable load must never
become zero capacity. A deferred-only queue is the opposite case: the reading **succeeded** and
the honest answer is zero claimable units. If deferral is mistaken for a degraded reading, the
loop spawns a runner every tick against work the operator explicitly parked; if zero claimable
units is mistaken for a degraded reading, the same thing happens. Both readings already exist
and this ticket makes the third one distinguishable from either.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a held loop says what is holding it
- `workaholic:implementation` / `policies/error-handling.md` — a refusal is named, never silent

## Key Files

- `plugins/workaholic/skills/loops/scripts/claimable-units.sh` — the count the fanout reads.
  Its header owns the `readable: false` → one-runner contract and the rule that a degraded read
  answers **null** counts, never zero.
- `plugins/workaholic/skills/loops/scripts/allocate-implement.sh` — preserves unreadable work as
  a one-runner fallback; must not preserve deferred work the same way.
- `plugins/workaholic/commands/infinite-development.md` — the coordinator ceiling. It carries
  the fanout rule and the obligation to post the precondition-stop shape when a tick spawns no
  runner because something was degraded — which a deferred-only queue is **not**.
- `plugins/workaholic/skills/work/SKILL.md` — the tick's report contract.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — source of the reading added by the
  previous ticket; composed, never re-derived.
- `CLAUDE.md` (*Architecture Policy*) — update in the same change.

## Implementation Steps

1. **Reproduce first.** With the previous ticket's change in place and a queue holding only
   deferred tickets, record what `claimable-units.sh` answers today and what the coordinator
   does with it. Put both readings in the branch story.
2. **Compose, do not re-derive.** Read the deferred reading off `plan-units.sh`'s own output
   (`excluded[]` / `backlog_all_excluded`), the way every other term in `claimable-units.sh` is
   composed. No second walk of the queue and no second parse of the declaration.
3. **Keep the three answers distinct.** A successful read with nothing claimable answers **zero**
   with the deferred reason named; a degraded read keeps its **null** counts and its
   `readable: false`; a queue with claimable work is unchanged. The test is
   `readable == false`, never `readable // true` (`rules/shell.md`), and zero must never be
   written where null belongs.
4. **Do not let it fall back to one runner.** `allocate-implement.sh`'s one-runner preservation
   is for *unreadable* work; prove a deferred-only queue takes zero runners and that an
   unreadable one still takes one.
5. **It is not a precondition stop.** The coordinator posts the precondition-stop shape when a
   tick spawns no runner because something it needed was **degraded**. A deferred-only queue is
   the operator's own decision and a healthy idle tick, so it posts no alert — but the tick
   report names it, so the tick does not read as unexplained silence. State this in the ceiling
   and in `SKILL.md` in **one** wording and pin it byte-identically if the suite pins the
   surrounding text.
6. **No new post shape, no new transport, no new control path.** This adds a reading and a
   report clause only.
7. Update `CLAUDE.md` in the same commit and run the local proof set.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A queue whose whole backlog is deferred answers zero claimable units with the reason named,
  and is not `readable: false`.
- Such a tick spawns zero implementation runners, reports no failure, and posts no
  precondition-stop alert; the tick report names what is holding the queue.
- An unreadable survey still answers `readable: false` with **null** counts and still falls back
  to one runner.
- A queue holding claimable work produces a byte-identical count and fanout.
- The ceiling and `SKILL.md` carry one wording for the new report clause.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node --test scripts/tests/agentic-loop/*.test.mjs`
- `sh scripts/e2e/loop-drill.sh verify-observation-during-work`
- a hermetic fixture covering all three readings — deferred-only, unreadable, and claimable —
  asserting on the recorded event sequence and never on elapsed time
- `bash plugins/workaholic/skills/branching/scripts/local-proof.sh`

**Gate** — what must pass before approval:

- The local proof set reports `ok: true` with every `not_run` row named.
- The three readings are proved together in one fixture, so a later change cannot collapse two
  of them without failing.

## Considerations

- **The direction of error is chosen deliberately.** Treating deferral as degraded spawns a
  runner forever against parked work; treating a degraded read as deferral stops the loop
  silently. Neither is acceptable, which is why the three answers are proved in one fixture
  rather than in three.
- **This ticket must not become a control path.** The loop already has one liveness authority
  and one allocation seam; deferral is a reading those consume, not a hold, flag or second
  cadence.
- **Stated cost.** A queue that is entirely deferred now produces quiet ticks by design. The
  report clause is what keeps that quiet legible; without it this change would be
  indistinguishable from the loop stopping, which this repository has measured twice.

## Final Report

Development completed as planned. `claimable-units.sh` composes `plan-units.sh`'s own `excluded[]` — no
second walk of the queue, no second parse of the declaration — and keeps the three answers distinct;
`allocate-implement.sh` is **byte-identical**, because it already answered `no_claimable_work` with zero
runners for a readable zero and `claimable_unreadable` with one for a degraded reading. What was missing
was a reader that could tell the two apart, which is the whole of this change.

Step 1's reproduction, with the previous ticket's change in place: a deferred-only queue answered
`claimable: 0` with nothing naming why, byte-identical to a repository with an empty queue — so the
coordinator's line read `implement allocation: 0 (no_claimable_work)` over work the operator had parked
and a reader had no way to tell that from a drained backlog.

The three readings, proved together in one fixture (`scripts/tests/agentic-loop/coordinator-allocation.test.mjs`)
and end to end from the reader into the allocator:

| Queue | `claimable-units.sh` | `allocate-implement.sh` |
| ----- | -------------------- | ----------------------- |
| held entirely by deferral | `claimable: 0`, `deferred: 2`, **no** `readable` key | `runners: 0`, `no_claimable_work`, `claimable_readable: true` |
| `deferral_unreadable` | `readable: false`, `reason: deferral_unreadable`, **null** counts | `runners: 1`, `claimable_reason: deferral_unreadable` |
| two missions, one backlog unit, one deferred ticket | `claimable: 3`, `missions: 2`, `backlog_units: 1`, `deferred: 1` | `runners: 1`, `work_available` |

Step 5: a deferred-only tick is **not** a precondition stop, and the ceiling now says so in one wording
carried byte-identically in `commands/infinite-development.md` and `skills/work/SKILL.md` (pinned by the
suite, the shape `workaholic:mention-reread` already uses). No new post shape, no new transport, no new
control path — a reading and a report clause.

### Discovered Insights

- **Insight**: `deferred` is reported and never subtracted. A deferred ticket is already absent from
  `backlog[]` before this reader sees it, so the count needed no arithmetic at all — the field exists
  only so the tick's report can name what is holding the queue instead of printing a bare zero.
  **Context**: The tempting change is to subtract it somewhere, which would double-count and make the
  reader's claim that it derives nothing of its own false.
- **Insight**: The unreadable arm has to be judged **before** the deferred count, not beside it.
  **Context**: A survey carrying both a real deferral and an unreadable one must answer
  `readable: false`: the honest reading is that the queue could not be fully judged, and answering a
  plausible `deferred: n` over it is the collapse the header refuses.
