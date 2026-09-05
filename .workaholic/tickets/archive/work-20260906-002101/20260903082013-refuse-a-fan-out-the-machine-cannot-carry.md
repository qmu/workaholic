---
created_at: 2026-09-03T08:20:13+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Refuse a fan-out the machine cannot carry

## Overview

With the reader in hand, the machine becomes an input to the spawn decision. Today that decision
is made from queue depth alone — and **on exactly the same evidence it used to add the third
runner it would have added a fourth and a fifth.** Past the core count each added runner makes
every other runner slower: throughput per runner falls, wall-clock per unit rises, and the loop
observes only that units are still landing. The failure is quiet, which is the kind this
repository takes most seriously elsewhere.

This is the second bound on the same fan-out, beside `WORKAHOLIC_IMPLEMENT_FANOUT`. The fan-out
becomes `min(declared bound, claimable units, what the machine can carry)`.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read
- `workaholic:operation` / `policies/failure-recovery.md` — work in progress is never thrown away

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §2, the ceiling that makes the spawn
  decision and where the refusal is named
- `plugins/workaholic/skills/loops/SKILL.md` — where the bound and its refusal are documented
- `.claude/settings.json` — the `env` block where `WORKAHOLIC_WIP_LIMIT` and
  `WORKAHOLIC_CADENCES` are declared, for the same reason
- `CLAUDE.md` — *Loops*, which lists the environment declarations and must move in the same change

## Implementation Steps

1. Declare the ratio as `WORKAHOLIC_MAX_LOAD_PER_CORE` in `.claude/settings.json`'s `env` block,
   beside the two bounds that already live there for the same reason.
2. **Absent means no machine bound** — a repository that declares nothing is byte-identical to
   one before this existed. That is the safety property, and it is why no number is picked for
   any other repository: the operator who measured `7.99` on four cores is the one who knows what
   their machine can carry.
3. Before each `implement` spawn beyond the first, read `read-machine-load.sh`. When
   `load_per_core` already exceeds the declared ratio, **do not spawn another runner** and report
   the refusal by name: `load_saturated: 7.99/4` — the reading and the core count, the way every
   other refusal in this loop is named rather than silent.
4. **The reading gates adding, never stopping.** No running unit is killed, paused or reaped for
   load: that throws away work in progress, which is the same mistake a too-eager staleness
   threshold makes. Measured the same day, a unit that looked stalled for twenty minutes was
   reading documents and landed shortly after.
5. **A gate that cannot be read is not a gate**: `readable: false` holds nothing, the fan-out
   proceeds exactly as it would without this, and the reading is reported by its reason. Same for
   a non-numeric declaration — `bad_load_ratio`, holding nothing and saying so.
6. **The first runner is never refused.** A machine over its ratio with nothing running would
   otherwise stop the loop entirely, and a loop that will not start work because it is busy with
   no work is worse than the failure this cures.
7. Document the bound, the refusal and both degradations in `workaholic:loops`, the command body
   and `CLAUDE.md`, in this change rather than a later one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Absent declaration: the tick fans out exactly as it does today.
- Over the ratio: no additional runner is spawned and `load_saturated: <load>/<cores>` is
  reported.
- Under the ratio: the fan-out is unchanged by this bound.
- An unreadable reading or a bad ratio holds nothing and is reported by name.
- No running unit is ever stopped by this reading.

**Verification method** — the commands/tests/probes that prove them:

- Unset `WORKAHOLIC_MAX_LOAD_PER_CORE`: a tick's spawn behaviour is byte-identical to before.
- Set it to `0.5` on a machine under load: the tick spawns the first runner, refuses the rest,
  and the report carries `load_saturated`.
- Set it to `abc`: the tick reports `bad_load_ratio` and fans out unbounded by it.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No code path kills, stops or reaps a *running* agent on a load reading.
- No default ratio is hard-coded; absent means no bound.

## Considerations

The ratio is a per-core figure rather than a raw load so that the same declaration means the same
thing on a single-board computer and on a workstation. **The machine is not incidental to this
design**: the loop is meant to run forever on whatever machine its developer has, and today a
small SBC and a large workstation receive the same instruction.

A ratio above the core count is not an error — an operator who wants queueing gets it, and the
bound simply never fires.

## Final Report

Development completed as planned.

`WORKAHOLIC_MAX_LOAD_PER_CORE` is now the second bound on the same fan-out, documented in the three
places this mission keeps in step — the command body's §2 (`plugins/workaholic/commands/infinite-development.md`),
`workaholic:loops`, and `CLAUDE.md`'s *Loops*. The fan-out reads `min(declared bound, claimable
units, what the machine can carry)`, and the refusal before each spawn **beyond the first** is named
`load_saturated: <load1>/<cores>` — the reading and the core count, never a silent hold.

The four bounds ride with it in every copy, each written as a refusal rather than a preference:
**absent means no machine bound** (such a repository is byte-identical to one before this existed,
and no number is picked for any machine); **the reading gates adding, never stopping** (no running
unit is killed, paused or reaped for load); **the first runner is never refused**; and **a gate that
cannot be read is not a gate** — `readable: false` holds nothing and is named by the reader's own
reason (`no_loadavg`, `no_core_count`, `unparseable`), while a non-numeric or non-positive
declaration is `bad_load_ratio`. The ratio is per core so one declaration means the same thing on a
single-board computer and on a workstation.

**Gate checks.** *No code path kills, stops or reaps a running agent on a load reading*: the only
`TaskStop` in either surface is the tick's existing unconditional reap of **idle** subagents, which
reads the agent listing and no load figure at all; the machine reading is consulted only at the
spawn decision. *No default ratio is hard-coded*: searching the tree for the name returns prose
only, in the three documents.

**No value was written into this repository's own `.claude/settings.json`**, for the reason step 2
gives in its own words — the operator who measured `7.99` on four cores is the one who knows what
their machine can carry. The five acceptance criteria are all about behaviour under a declaration
that is absent, present, bad or unreadable; none asks for one to be present here.

### Discovered Insights

- **Insight**: `read-machine-load.sh` already existed and was deliberately consumer-less — its own
  header says *this ticket adds the reading and nothing else … the bound that will read it is
  declared separately*.
  **Context**: the reader and its bound were split across two tickets on purpose, so the reading
  could land and be wrong about nothing. A later reader tracing why a reading existed with no
  consumer for one commit will find the answer in that header rather than in a gap.
- **Insight**: the reader answers about **CPU alone** and says so, because in the measurement that
  produced it memory was half free and the SoC was not throttling.
  **Context**: the bound therefore claims no general verdict about the machine's health. A future
  ask about memory or thermal pressure needs its own reading and its own declared bound; widening
  this one would make a CPU figure stand for something it never measured.
