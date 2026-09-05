---
created_at: 2026-09-06T08:20:31+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: give-a-dispatched-codex-worker-the-whole-role-it-is-named-for
mission: finish-the-backlog-without-handing-it-back-to-the-operator
merge_policy:
verification_handoff: 
---

# Record a worker's finish from its own reported outcome

## Overview

`run_worker` calls `record_worker_finish "$_role" "$_wexit"` — the finish is written from the
**process exit status** and nothing else, so a worker that exits zero while reporting it did
not execute records a healthy finish and the cadence counts the role done. On the coordinator
side `classify_report` defaults `TICK_OUTCOME=ready` and infers failure by grepping selected
words out of a free-text report. Successful process termination, valid execution, work
completion and notification delivery are four different facts and need four pieces of
evidence.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the loop is a running system; a degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `run_worker` (~340),
  `record_worker_finish` (~325), `classify_report` (~232).
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the one writer of the
  `loop-finish-<role>` line the cadence reads back.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the relay envelope contract,
  which already validates a structured worker result on the `RELAY=true` path.

## Implementation Steps

1. **Reproduce and localize.** Shim a worker that exits `0` and writes a report saying it
   could not execute. Record that `record_worker_finish` writes the `loop-finish-<role>` line
   and that `log-read.sh --step-prefix loop-finish-<role> --latest-tick` then reads the role as
   done. Record separately that `classify_report` answers `ready` for a report matching none of
   its grep patterns.
2. Enumerate the four facts and where each is currently taken from; note that the relay path
   already validates a structured envelope and the non-relay path does not.
3. Take the worker's outcome from what the worker **reported** — the CLI's schema-constrained
   final output where available — rather than from its exit status or from words in prose.
4. A report that cannot be read is `unreadable:<reason>`, **never** `ready`: an absence of a
   reading is not a healthy run. The cadence measures when we last *tried*, so record the
   attempt separately from the outcome and say which the line carries.
5. Keep `log-append.sh` the one writer and its `(tick, step)` idempotence untouched.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A worker exiting zero while reporting it did not execute records no healthy finish and the
  role is still due.
- A report that cannot be parsed reads `unreadable:<reason>` and never `ready`.
- A genuinely successful run is unchanged in every field.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- the reproduction named in step 1, re-run, now answering differently

**Gate** — what must pass before approval:

- the suite and the classified drill set both pass, and step 1's reproduction is shown before and after

## Considerations

- **The ask's proposal**, as a hypothesis: use JSONL events, schema-constrained final output
  and explicit-session resume (CLI 0.153.4). Confirm each against the installed CLI in step 1
  rather than assuming the documented surface.
- Recording *attempt* and *outcome* separately risks a role that retries forever. Whatever
  bounds the retry must be stated here, not invented at the call site.
- The relay path's envelope validation is the shape to extend, not a second mechanism.
