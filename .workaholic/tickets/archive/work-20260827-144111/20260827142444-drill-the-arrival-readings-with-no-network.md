---
created_at: 2026-08-27T14:24:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827142444-report-the-arrival-as-a-moderation-event.md
mission: say-when-a-direction-has-arrived
merge_policy:
verification_handoff: 
---

# Drill the arrival readings with no network

## Overview

PROPOSED. Add `scripts/e2e/loop-drill.sh verify-arrival`, over local fixtures with the transport
stubbed and **no network at all** — the shape `verify-direction-health` already sets for this
layer. It drills: arrived, dormant, overdue-and-arrived, unreadable, the asked-once gate, and its
own deliberately broken seam that proves the drill can fail.

The broken seam is the point. A drill that cannot fail proves nothing, and every recent drill in
this repository carries one.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill harness; `verify-direction-health` is the sibling to
  follow, including how it stubs the transport and builds fixtures.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file blame table.

## Implementation Steps

1. Read `verify-direction-health` end to end — fixture construction, transport stubbing, the
   assertion style and its own broken-seam case.
2. Add `verify-arrival` with fixtures for each reading: arrived; dormant; a direction both overdue
   and arrived (proving `arrived` wins); unreadable.
3. Drill the asked-once gate: run the step twice over the arrived fixture, assert one question
   then none.
4. Add the deliberately broken seam and assert the drill fails on it.
5. Register the drill in `docs/loop-drill-runbook.md` with its blame table row.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-arrival` passes and makes no network call.
- Each of the four readings is asserted, with overdue-and-arrived resolving to `arrived`.
- The asked-once gate is drilled across two runs.
- The broken seam fails the drill.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-arrival`
- The drill run with the network unavailable.

**Gate** — what must pass before approval:

- The broken seam demonstrated failing.

## Considerations

- Fixtures must not depend on the wall clock for the overdue case, or the drill rots on a fixed
  date; pass the dates in as the sibling drills do.

## Final Report

Development completed as planned. `scripts/e2e/loop-drill.sh verify-arrival` ships with 15 rows,
registered in the usage string and the dispatch, and documented in `docs/loop-drill-runbook.md`
(the stage table row plus §5i, with a blame table naming what to read for each row).

Five fixtures, one per reading: `arrived`, `latearrived` (arrived **and** past its date — the
case the mission exists for, proving `arrived` outranks `overdue`), `quiet` (`dormant`), `gone`
(`overdue`), and `busy` — the **deliberately broken seam**, carrying landed work *and* a queued
ticket behind an active mission, which must read `live`. The asked-once gate is drilled across
two `ask-question.sh` calls under `direction-arrived:arrived`. `arrival_fixture` guards the whole
drill: if no attributed work landed in the window, it fails immediately rather than letting every
arrival row pass vacuously.

**Dates are passed in** (`date -u -d "-30 days"` / `"+300 days"` at fixture-build time), never
read inside an assertion, so the drill does not rot on a fixed date.

Verified:

- `sh scripts/e2e/loop-drill.sh verify-arrival` → `pass`, 15/15 load-bearing rows.
- **No network**: re-run with `gh`, `curl` and `wget` replaced by stubs that log every
  invocation and exit 1 — still `pass`, 15/15, and the log file was never created.
- **The broken seam fails the drill**: with the waiting terms removed from `quiescent`,
  `verify-arrival` returns `fail` on `arrival_waiting_work_is_not_arrival`
  (*a direction with waiting work read 'arrived'*), plus `arrival_question_keys` and
  `arrival_all_live_renders_no_line`. Restored → `pass`, 15/15.

### Discovered Insights

- **Insight**: `sed`'s greedy leading `.*` makes `s/.*"slug": *"X",.*"field": *\([0-9]*\).*/\1/p`
  match the **last** `"field"` on the line and capture empty, because `[0-9]*` accepts zero
  digits.
  **Context**: the sibling drills use `[^}]*` to stay inside the JSON object; copying that, plus
  `[0-9][0-9]*`, is what makes a numeric field extraction from `jq -c` output correct.
- **Insight**: a body containing a comma cannot be extracted with `tr ',' '\n'`, which is how the
  sibling drills split key/value pairs out of compact JSON.
  **Context**: the arrival body has one. A direct `sed -n 's/.*"body": *"\(<prefix>[^"]*\)".*/\1/p'`
  over the whole output is what survives punctuation in the value.
