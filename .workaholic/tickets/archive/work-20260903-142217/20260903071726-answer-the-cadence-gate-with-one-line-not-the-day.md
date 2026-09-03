---
created_at: 2026-09-03T07:17:26+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: pay-only-the-operative-cost-on-every-tick
merge_policy:
verification_handoff: 
---

# Answer the cadence gate with one line not the day

## Overview

The tick's `moderate` gate needs exactly one value — how old the newest tick in the log is —
and `log-read.sh` returns every entry of the day to supply it. Measured in one session: about
12 KB early on, 50,087 bytes two hours later, read twelve times an hour and growing monotonically
until the day rolls over. Nothing else in the tick consumes those entries.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the one reader; gains a mode,
  loses no existing behaviour
- `plugins/workaholic/commands/infinite-development.md` — §2's `moderate` gate is the caller
- `scripts/test-workflow-scripts.mjs` — hermetic tests for the reader

## Implementation Steps

1. Add `--newest` to `log-read.sh`: the newest tick's id and day and nothing else, composable
   with the existing `--step` / `--step-prefix` filters so the finish-time reader can use it too.
2. Emit the same JSON envelope shape the reader already emits, with `entries` holding at most
   one row — a second output shape is a second parser.
3. Keep every existing flag and default byte-identical: a caller that does not pass `--newest`
   reads exactly what it read before.
4. Point §2's `moderate` gate at it. The unreadable-log rule is untouched: an unreadable log
   still spawns.
5. Add a hermetic test asserting `--newest` returns one row and that the default is unchanged.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `--newest` returns the newest tick's id and day and no other entries.
- Every existing invocation returns byte-identical output.
- The `moderate` gate reads through it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes, including the new row.
- `bash plugins/workaholic/skills/moderate/scripts/log-read.sh --newest` returns one row.

**Gate** — what must pass before approval:

- No existing caller's output changes.

## Considerations

This is the smallest of the five and the only one that touches a script rather than prose;
it is first because it is independent of the others.

## Final Report

**Outcome**: implemented.

`log-read.sh` gained `--latest-tick`: the newest `(day, tick)` among the rows the filters kept, with
an **empty `entries` array** and `count: 0`. The tick's `moderate` gate now asks for that one value.

**The empty array is honest rather than a truncation** — the caller asked for a timestamp, not for a
sample of the log. **Every filter still applies**, so `--step-prefix foo --latest-tick` answers *when
did a `foo…` step last run*, which is a second use the flag gets for free.

**`latest_tick` is the empty string when nothing matched**, and the header says a caller must read
that as *no such tick* and never as *just now* — the direction of failure this repository chooses
everywhere else, and the one that matters here because *just now* would silence the gate.

**Measured on a two-tick fixture**: 487 bytes → 108. The reported production case is 50,087 bytes at
two hours, read twelve times an hour and growing monotonically until the day rolls over.

**Verified**: `node scripts/test-workflow-scripts.mjs`, including that a filtered `--latest-tick`
answers that filter's newest and that no match answers the empty string.
