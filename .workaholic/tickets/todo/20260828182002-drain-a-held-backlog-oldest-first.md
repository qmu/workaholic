---
created_at: 2026-08-28T18:20:02+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Drain a held backlog oldest-first

## Overview

PROPOSED. Unbinding the day count without an order would land the arrears as one wall.
**22 questions are held right now** — measured while this proposal was written: 7
`undrivable-unit`, 3 `retire-blocked`, 6 `stuck`, 1 `handoff-unit`, 1 `stalled-unit`, 1
`base-red`, 1 `direction-dormant`, 1 `direction-last`, 1 `release-status`. The ask counted
15 a few hours earlier, so the backlog is still growing.

`step-human-checkin.sh` collects held keys with `sort -u` (lines 87–89) — **alphabetical**,
which is an arbitrary order over a set whose only meaningful axis is age. Order them by the
day each was first held, so the arrears arrive in the order they went stale, still bounded by
`max_per_tick`. The day is already in the log the tick keeps (`log-read.sh` emits `day` per
entry), so this needs **no second ledger and no new field**.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-source.md` — one derivation of a fact, read by every consumer

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — the held-key
  collection at lines 82–98 and the `held` array it hands back in `needs_agent`.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — read only; its per-entry `day`
  is the ordering key and its output shape must not change.
- `scripts/test-workflow-scripts.mjs` — the ordering case.

## Implementation Steps

1. **Read the first-held day per key.** The `human-checkin-held-<slug>` entries already carry
   `day`; take the **earliest** `day` per key (a key held across several ticks is as old as
   its first hold, not its most recent).
2. **Replace the `sort -u` with an age sort**: ascending by that earliest day, and — because
   several keys are typically first held on the same day, and one day is the finest grain the
   log file names carry — break the tie on the **tick id** within the day, then on the key,
   so the order is total and a re-run of the same tick produces the identical sequence.
3. **Keep the drop rule exactly as it is**: a held key with any `human-checkin-ask-<slug>`
   line drops out (lines 92–94). The ask is still the resolution of the hold.
4. **Emit the ordered list in `held`**, unchanged in shape — an array of key strings — so the
   agent's existing loop needs no change and the per-tick cap continues to be enforced by
   `ask-question.sh`, not here. **This step orders; it does not cap and it does not ask.**
5. **Keep `held_count` counting the whole held set**, not the ordered prefix: the count is
   what tells a reader how deep the arrears are, and truncating it would hide exactly what the
   next ticket must report.
6. Add a hermetic case: a fixture with holds on three different days must hand back the
   oldest day's keys first, and the same fixture must produce a byte-identical order on a
   second run.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `held` is ordered by earliest-held day ascending, tie-broken deterministically, and a
  repeated run over one fixture produces a byte-identical order.
- A held key that has since been asked still drops out.
- `held_count` still counts the whole held set.
- The step still caps nothing and asks nothing; `max_per_tick` is enforced only by
  `ask-question.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the multi-day ordering case and the determinism
  case pass.
- Against the live tree: `step-human-checkin.sh --root . --tick <id> --hour 14 --weekday 3`
  lists the 22 held keys with the oldest-held first.

**Gate** — what must pass before approval:

- No second ledger, no stored cursor, no new field on any artifact, and `log-read.sh` is
  unmodified.

## Considerations

- **The order is a proposal to the agent, not a decision.** The agent still applies the
  Recommended-label test per candidate and `ask-question.sh` still gates each one, so an
  older question that is no longer worth asking is dropped by judgement, not asked because it
  sorted first.
- Age is not the same as urgency, and this ticket deliberately uses age: the ask asked for
  "the order they went stale". A severity ranking across the eight step vocabularies would be
  a judgement no script can make, and the four verdicts call for different acts by different
  people — the reason `/moderate` refused one unified blocked-on report.
- The day grain is coarse: a whole day's holds sort together. That is acceptable because the
  arrears span five days; if a finer grain is ever needed, the tick id is already the
  tie-break and carries `HHMMSS`.
