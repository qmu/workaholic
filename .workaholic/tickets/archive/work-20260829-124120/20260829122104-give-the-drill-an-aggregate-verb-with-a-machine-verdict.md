---
created_at: 2026-08-29T12:21:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Give the drill an aggregate verb with a machine verdict

## Overview

Give `loop-drill.sh` one aggregate verb that runs the set ticket 1 measured hermetic and
emits a machine verdict per drill — `pass`, `fail`, or `skipped:<reason>` — plus one exit
status, non-zero only on a real failure. Today each drill is invoked by hand, one at a
time, and its result is a JSON line a person reads; nothing composes them, so there is no
artifact a CI step or a `/moderate` step could read. **A skip is a named fact, never a
silent pass**: a drill that could not run must be visibly absent from the green set.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — a named refusal, never a swallowed one
- `workaholic:operation` / `policies/observability.md` — the verdict is the artifact every later ticket reads

## Key Files

- `scripts/e2e/loop-drill.sh` — gains the verb; the dispatcher's `case` is the enumeration
  it runs over, and `emit_err`/`add_row`/the exit-code table are the contract it composes
- `docs/loop-drill-runbook.md` — ticket 1's classification, which decides which rows the
  verb runs and which it reports as `skipped`

## Implementation Steps

1. Add one dispatched command (`verify-all`, or the name the implementation settles on)
   beside the existing rows, taking `--json` like every other, and register it in `USAGE`
   and in the `case "$CMD"` dispatcher so the enumeration stays single-sourced.
2. Derive the set it runs from the dispatcher plus ticket 1's classification — never a
   second hand-kept list, which is exactly the drift ticket 8 is written to catch.
3. Map each drill's existing exit code onto the verdict with no new vocabulary: `0` →
   `pass`; `1` → `fail`; `3`/`4` → `skipped:<the drill's own reason word>` (`gh_unavailable`,
   `identity_unresolved`, `not_a_repo`, `inbox_dirty`, …); `5` → `skipped:not_run_yet`; a
   row ticket 1 classified as needing the server → `skipped:needs_server`, without
   invoking it at all.
4. Emit one JSON document: per drill its verdict, its reason where skipped, and its
   duration; plus totals. Exit non-zero **only** when at least one drill verdict is
   `fail` — a wholly skipped run is not a pass and not a failure, and says so.
5. Bound the run: a per-drill timeout, reported as `fail` with its own reason rather than
   hanging the caller, since ticket 4 puts this on every push.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The verb runs with no key, no network, no `gh` and no `qfs`, and completes.
- Every drill in the run carries exactly one of `pass` / `fail` / `skipped:<reason>`; no
  drill is silently absent.
- Exit status is non-zero if and only if at least one verdict is `fail`.
- A skipped drill is never counted toward the passing total.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh <the verb> --json` in an environment with `gh` removed
  from `PATH` and no network, read for the per-drill verdicts and the totals.
- A deliberately broken drill copy, to prove the exit status turns non-zero.

**Gate** — what must pass before approval:

- Verdicts for every dispatched `verify-*` row, a non-zero exit proved over a real
  failure, and a zero exit proved over a run whose only non-passes are skips.

## Considerations

- The verb runs drills that each build their own throwaway fixture, so the wall-clock cost
  is the sum; ticket 4 must decide what CI can afford, and the per-drill timeout here is
  what keeps that bounded.
- Verdict naming is deliberately the drill's **existing** exit vocabulary rather than a
  new one — a second vocabulary for the same fact is how the two drift.

## Final Report

Development completed as planned.

`loop-drill.sh verify-all` runs the set the register classifies as runnable here and emits
one JSON document: per drill a verdict, its reason where skipped, its breaker state, its
kind, the mission that shipped it and its duration, plus totals. It exits non-zero **only**
when at least one verdict is `fail`.

The set is derived from the dispatcher's own `case` arms plus the register — never a second
list — and the verdict vocabulary is the drill's **existing** exit vocabulary rather than a
new one: `0` → `pass`, `1` → `fail`, `3`/`4` → `skipped:<the drill's own reason word>`, `5`
→ `skipped:not_run_yet`, a timeout → `fail` with reason `timeout`, anything else → `fail`
with `unexpected_exit_<n>`. A `needs_server` row is `skipped:needs_server` and is never
invoked at all. A drill the register does not classify is `skipped:unclassified`, which is
what makes ticket 8's reachability pin meaningful: a new drill is either run or
deliberately classified, never silently absent.

Two flags beyond `--json`: `--only <drill>` narrows the run (CI uses it per matrix leg),
`--kind <k>[,<k>]` selects by classification (CI passes `hermetic`), and `--list` answers
the set the verb would run **without invoking any of it**, so CI builds its matrix in one
cheap call. `--timeout` bounds each drill; without `timeout` on `PATH` the run reports
`bounded: false` rather than pretending.

Measured over this checkout with no `gh`, no network and no key: 30 drills, **19 proved,
9 unproved, 0 failed, 2 skipped**, exit 0, ~2m20s sequential.

### Discovered Insights

- **Insight**: A failing verdict carries the **rows that went false**, not the whole
  document and not just the fact that one did. `one_line` truncates at 400 characters, so a
  whole-document detail routinely cut off before reaching the failing row — the one thing a
  reader needs.
  **Context**: This is what makes a red CI leg diagnosable without reproducing the fixture
  locally, which is the friction the verb exists to remove.

- **Insight**: `needs_server` must be named **before** the `--kind` filter, or a drill
  skipped for the strongest possible reason reports `kind_needs_server` — the reason of
  whichever set that run happened to ask for.
  **Context**: The general shape: when a row can be excluded by two rules, the one that is
  a property of the row must win over the one that is a property of the caller.
