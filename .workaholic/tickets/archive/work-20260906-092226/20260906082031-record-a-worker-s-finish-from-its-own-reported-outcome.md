---
created_at: 2026-09-06T08:20:31+09:00
status: done
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

## Final Report

**Reproduced first (step 1).** `record_worker_finish "$_role" "$_wexit"` wrote the
`loop-finish-<role>` line from the **process exit status** alone, with the summary
`<role> finished (exit 0)`. Shimming a worker that exits `0` while reporting it could not execute
therefore recorded a healthy finish, and
`log-read.sh --step-prefix loop-finish-<role> --latest-tick` then read the role as done. Separately,
`classify_report` defaulted `TICK_OUTCOME=ready` and reached that default for any report matching
none of its greps — so a report this function could not read was graded a healthy tick.

**Step 2, the four facts and where each came from.** *The process terminated* → the exit status.
*The role was executed* → **nowhere**. *The work completed* → **nowhere** (inferred from words
grepped out of prose). *The notification was delivered* → `TRANSPORT_VERDICT`, and only on the relay
path. The relay path already validated a structured envelope; the non-relay path had no structured
result at all.

**Step 3, confirmed against the installed CLI rather than assumed** (the Considerations asked for
this): `codex-cli 0.153.4` lists `--output-schema <FILE>`, `--output-last-message <FILE>` and
`--json`. So the outcome now comes from a **schema-constrained final message**
(`scripts/worker-result.schema.json`: `executed`, `outcome`, `reason`, `report`), read by
`worker_outcome()` — never from the exit status and never from prose. This **extends the relay
path's envelope validation** rather than adding a second mechanism, which is the shape the ticket
asked for.

**Step 4, the attempt and the outcome are recorded separately and the line says which it carries.**
`loop-attempt-<role>` is written for every run and names the outcome; `loop-finish-<role>` — the
line the cadence reads, whose reader is **untouched** — is written only for a run that actually
executed. So a worker that did nothing leaves its role **due**.

**The retry bound, stated here rather than invented at the call site** (the Considerations demanded
it): after `WORKAHOLIC_WORKER_ATTEMPT_MAX` consecutive unhealthy attempts (**default 3**) the finish
line *is* written, naming the outcome, so the role falls back to its ordinary cadence instead of
retrying on every tick forever. `0` means no bound; a non-numeric value falls back to 3 and holds
nothing.

**Step 5**: `log-append.sh` remains the one writer and its `(tick, step)` idempotence is untouched.

**Reproduction re-run, now answering differently** — `worker_outcome` over each shape:
- exits 0, reports `executed:false` → `not_executed:plugin_command_missing` → **no finish line**, role still due
- exits 0, reports `executed:true, outcome:ok` → `ok` → finish line written
- exits 0, reports `executed:true, outcome:pending` → `ok` (a completed run with an honest token)
- exits 0, free-text report → `unreadable:unparseable_report`, never `ready`
- exits 0, empty report → `unreadable:no_report`
- exits 7 → `failed:codex_exit_7`

And at the coordinator: an unparseable report reads `report_unreadable` /
`unreadable:unparseable_report`, and a report of a run that did not execute reads `work_blocked` /
`not_executed:plugin_command_missing`. **Neither reads `ready`.** A genuinely successful run is
unchanged in every field — `state=sleeping outcome=ready transport_verdict=available` — and the
existing rungs (`tick_failure`, `report_missing`, `transport_absent`, `work_blocked`) fire first and
are byte-identical.

**Gate.** `node scripts/test-workflow-scripts.mjs` — 6663 passed, 0 failed, with two new rows for
the load-bearing negatives and both fixtures moved onto the schema-shaped report a real run now
emits.
