---
created_at: 2026-09-08T20:15:10+09:00
author: a@qmu.jp
assignees: 
depends_on:
feedback: [20260908123559-discover-new-human-replies-inside-existing-slack-threads.md, 20260908123606-honor-repository-declared-qfs-slack-bindings-before-connector-fallback.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260910-133027
---

# Make the machine-load rounding assertion deterministic

## Overview

`test-workflow-scripts.mjs`'s row *load_per_core is load1 over cores* recomputes the expectation
in JavaScript (`Number((r.load1 / cores).toFixed(2))`) and compares it against the value
`loops/scripts/read-machine-load.sh` produced with awk's `%.2f`. The two disagree on a half-way
value: measured 2026-09-08 on a 4-core machine at `load1 = 2.51`, the script answered `0.62` and
the assertion expected `0.63`, failing the suite. Re-run at `load1 = 3.50` the same row passed.

The suite is otherwise hermetic — it creates throwaway repositories and touches no live state —
and this one row reads the machine's real `/proc/loadavg`, so it fails intermittently and only at
certain loads. That is exactly the shape that trains a reader to ignore a red suite, and the base
this loop merges onto is gated on it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the `read-machine-load.sh` block; the assertion that
  recomputes the rounding rather than pinning it.
- `plugins/workaholic/skills/loops/scripts/read-machine-load.sh` — the producer, which rounds
  with awk `%.2f`; its own contract (null is never zero) is not in question here.

## Implementation Steps

1. Reproduce the disagreement deterministically: feed `read-machine-load.sh` a fixed
   `WORKAHOLIC_LOADAVG_PATH` fixture whose `load1` is a half-way value for the machine's core
   count (`2.51` on 4 cores), rather than reading the live file.
2. Decide which rounding is the contract and say so in the script's header — awk's `%.2f` and
   JavaScript's `toFixed(2)` round a binary-inexact half in opposite directions, so one of them
   has to be named as the answer rather than left to whichever the test happened to use.
3. Assert against that named contract with a fixture, not against a recomputation of the live
   reading. Keep one row over the live file for the properties that are genuinely about this
   machine (the core count matches `nproc`, `load1` is a number), and take the derived value's
   assertion off it.
4. Confirm the row cannot depend on load: run the suite twice under a synthetic high load and
   once with the fixture at the measured boundary value.

## Considerations

The bug is in the *test*, not in the reader: `load_per_core` is a fan-out cost control, and two
hundredths either way changes no decision. What it costs is a suite that goes red for a reason
nobody can act on, which is why this is worth fixing and why it is not urgent.

A tempting shortcut — comparing with a tolerance — hides the fact that two components round
differently. Pinning the contract is the smaller change and the honest one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `read-machine-load.sh` block's derived-value assertion runs against a fixture and its
  outcome does not depend on the machine's live load.
- The rounding contract is named in the producer's own header, so the test pins a stated rule
  rather than reproducing an implementation detail.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes with a fixture whose `load1` is `2.51` on a
  4-core reading — the measured failing case.
- The same suite passes twice in a row while the machine is under synthetic load.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` reports 0 failed, and no row in it reads
  `/proc/loadavg` for a value it then asserts an exact expectation about.

