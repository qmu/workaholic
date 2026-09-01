---
created_at: 2026-08-29T06:20:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# Retry the delivery of a caught-up unit

## Overview

PROPOSED. On a successful catch-up, one `retry-undelivered.sh` in the same turn, through
the seam that already exists. Its outcome is reported in the run's **existing** merge
vocabulary (`merged` / `merge_refused: <word>`) — the outcome of a first attempt and of a
third are the same kind of fact, and a second set of words is how two readings drift.

The seam needs no new gate: `retry-undelivered.sh` already refuses every verdict but
`report_undelivered` by name, and refuses a scan-held pull request a second time anyway.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/drive/scripts/retry-undelivered.sh` — the delivery seam, used
  unchanged; read its header before touching it.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — `undelivered[]`, the set the run
  already walks.
- `plugins/workaholic/skills/drive/SKILL.md` §6 — the merge vocabulary this reuses.

## Implementation Steps

1. After a `caught_up` outcome, run `retry-undelivered.sh` once for that unit. One attempt,
   never a loop.
2. Report its outcome in §6's existing vocabulary. Do not invent a word for
   *delivered after a catch-up*.
3. A catch-up that was refused produces **no** retry — the refusal is the outcome.
4. A `session_type_cannot_merge` from this retry takes the same numbered connector step on
   the same bounds, unchanged.
5. Leave `retry-undelivered.sh` itself unmodified unless the fixture proves it must change,
   and say so if it does.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Exactly one delivery attempt per caught-up unit per run.
- The outcome is reported in the existing `merged` / `merge_refused: <word>` vocabulary.
- A refused catch-up produces no retry.
- `retry-undelivered.sh`'s own gates are unchanged, including the `scan_held` refusal.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The ticket-1 fixture, caught up and then delivered in one turn.

**Gate** — what must pass before approval:

- The fixture's stranded unit reaches `merged` in a single run, with no second vocabulary
  anywhere in the report.

## Considerations

The failure to avoid is a retry loop: catch up, refused, catch up again. One catch-up and
one delivery per unit per run, bounded by construction rather than by a counter.

## Final Report

Development completed as planned. `drive/SKILL.md` §6 and `reference/routing.md` now number the
composition: for each `undelivered[]` entry, one `catch-up-claim.sh`, then — **only on
`caught_up`** — one `retry-undelivered.sh <unit> --own-tip`. A refused catch-up produces no
retry, because the refusal is the outcome. `already_current` means nothing moved, so the retry
runs on its ordinary terms without the flag. Bounded by construction rather than by a counter:
one catch-up and one delivery per unit per run, each a single script invocation.

The outcome is reported in §6's **existing** merge vocabulary (`merged` / `merge_refused:
<word>`). No word was invented for *delivered after a catch-up* — that is two facts, and the
catch-up's own three words report the other one.

**`retry-undelivered.sh` did have to change, and the ticket asked for that to be said.** The
fixture proved it: the catch-up's own push makes the tip fresh, so the very next verdict reads
`claim_active` and the delivery the catch-up exists to unblock is refused by the act that
unblocked it. The change is one flag, `--own-tip`, whose whole effect is to re-ask
`claims_scan` with `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0`. Nothing is re-derived: identity,
ancestry, supersession, the drained fork and the recorded refusal all remain the oracle's own
answers, computed in one place. No verdict is widened and no gate moved — the suite asserts a
`merge_not_attempted: hard` unit is refused with the flag exactly as without it, and that
without the flag the behaviour is what it always was.

### Discovered Insights

- **Insight**: The bound "one attempt per unit per run" is cheapest to hold by making each act a
  single script call in a numbered step, rather than by a counter.
  **Context**: The failure to avoid was a retry loop — catch up, refused, catch up again. There
  is nothing to loop: the catch-up refuses idempotently and the delivery is gated behind its one
  success word.
