---
created_at: 2026-09-03T07:21:08+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Run the ingest half on the tick's own capture

## Overview

`propose` bundles an event-driven half with a state-gated half behind one number, so a captured
ask waits up to fifteen minutes for a clock. The ingest half should run the moment an ask is
captured — and the tick is the thing that captured it: §1 files the issue itself, moments
earlier, so no derivation, no detector and no second reader is involved.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §1 files the ask, §2 spawns `propose`
- `plugins/workaholic/commands/propose.md` and `commands/specificate.md` — the two halves the
  `propose` subagent runs in order today
- `plugins/workaholic/skills/loops/SKILL.md` — the cadence table and its argument

## Implementation Steps

1. Split the `propose` loop's two halves at the spawn: the **strategy judgement**
   (`/propose`) keeps `WORKAHOLIC_PROPOSE_CADENCE_MINUTES`; the **ingest**
   (`/specificate`) is spawned whenever §1 filed at least one issue this tick.
2. Key it on the tick's own act — the count of issues §1 filed — and on nothing else. No queue
   reading, no inbox poll, no change detector: the standing objection in the command body is
   about the strategy half and it is left standing.
3. Keep an ingest run on the cadence too, so an ask filed by a person directly on GitHub —
   which §1 never sees — is still discovered. The capture is an **additional** trigger, not a
   replacement.
4. Preserve the ordering guarantee the merged routine bought: when both halves run in one tick,
   the strategy judgement runs first, so the ask it opens is in the inbox the ingest reads.
5. Name the two halves separately in the listing so the concurrency rule can tell them apart.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An ask captured by §1 is ingested on the same tick.
- The strategy half keeps its cadence and its standing objection is untouched.
- An ask filed directly on GitHub is still discovered on the cadence.
- When both run in one tick, the strategy judgement runs first.

**Verification method** — the commands/tests/probes that prove them:

- File an ask through §1: the ingest runs that tick.
- A tick that captured nothing runs ingest only when the cadence is up.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No change detector, queue reading or inbox poll was added to trigger either half.

## Considerations

Splitting the loop into two names means two entries in the listing and two entries in whatever
records finishes. That is the cost of the split and it is small; the alternative — one name with
two trigger conditions — makes the concurrency rule unable to say which half is running.

## Final Report

Development completed as planned. The two halves are split at the spawn and named separately in
the listing, so the concurrency rule can tell them apart: `propose` keeps
`WORKAHOLIC_PROPOSE_CADENCE_MINUTES` for the strategy judgement, and `ingest` is spawned whenever
§1 filed at least one issue this tick.

It is keyed on **the tick's own act** — the count of issues §1 filed — and on nothing else. No
queue reading, no inbox poll, no change detector: the standing objection in the command body is
about the strategy half and is left standing word for word.

The ingest also keeps running on the cadence, because an ask a person files directly on GitHub is
one §1 never sees; the capture is an **additional** trigger, never a replacement. When both run in
one tick the strategy judgement is spawned first, so the issue it opens is in the inbox the ingest
reads — the ordering guarantee the merged routine bought, preserved rather than re-argued.

### Discovered Insights

- **Insight**: The trigger needs no detector because the tick is the thing that captured the ask —
  §1 files the issue itself, moments earlier, so the event is already in hand. The bundling was
  what made a detector look necessary: an event-driven half behind a state-gated half's number has
  no way to learn about its own event except by re-reading the world.
  **Context**: The same shape is worth looking for wherever two triggers share one cadence.

