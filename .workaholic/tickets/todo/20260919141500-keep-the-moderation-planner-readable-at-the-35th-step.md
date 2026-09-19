---
created_at: 2026-09-19T14:15:00+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy: review
verification_handoff:
claim: work-20260919-195549
---

# Keep the moderation planner readable at the 35th step

## Overview

Minted from ticket `20260919133719` (pin the moderation registry by name), whose add/remove/swap
probes exposed this. It is **outside that ticket's scope** — that one changes two test files and
nothing else — so it is recorded here rather than fixed opportunistically.

**Measured, twice, on `f9d7448fb`.** Append a 35th step to
`plugins/workaholic/skills/moderate/scripts/steps.json` and the moderation planner stops answering
on the **second** tick:

```
$ sh runtime-plan.sh prepare  --root $D --now 10000 > first.json
$ sh plan-steps.sh --input first.json | jq .data.count
35                                   # the cold tick is fine
$ sh runtime-plan.sh complete --root $D --now 10000 --executed "<all 35 ids>"   # exit 0
$ sh runtime-plan.sh prepare  --root $D --now 10001 > second.json
$ sh plan-steps.sh --input second.json
jq: error (at <unknown>): Cannot index string with string "seconds"
                                     # empty stdout, exit 0
```

At the tree's real **34** steps the same sequence is green (`second.json` 999 bytes, planner
2961 bytes of output). At 35 the planner answers **nothing**. The visible symptom in the suite is
`scripts/tests/agentic-loop/polling-cost.test.mjs:97` failing
`SyntaxError: Unexpected end of JSON input` — that line parses the planner's stdout.

**Both scripts are untouched by the ticket that found this**, which is what makes it a property of
the planner rather than of a test: the reproduction above calls only `runtime-plan.sh` and
`plan-steps.sh` directly, with no test runner involved.

**The cause is NOT established and is deliberately not asserted here.** Two signals were observed
and they do not obviously agree, so both are recorded rather than one being chosen:

- One run cut `runtime-plan.sh prepare`'s stdout at **exactly 1024 bytes** (34 steps → 999 bytes,
  intact; 35 steps → 1024 bytes, cut mid-object).
- A later run produced a `second.json` that **ended cleanly** at 1024 bytes and still drove
  `plan-steps.sh` to `Cannot index string with string "seconds"` — a **shape** error, something
  being a string where an object was expected, which truncation alone does not explain.

`RECORD_MAX_BYTES` in `runtime/scripts/state.sh` is **1048576**, not 1024, so the ceiling repaired
by ticket `20260919120809` is not this boundary. The stored snapshot
(`.git/workaholic/runtime/v1/snapshots/moderate-steps/meta.json`) measured 1050 bytes at 35 steps.

**Why this matters now.** The registry reached 34 on 2026-09-19 (`worktree-sweep`, PR #1224). The
35th step is an ordinary, expected addition, and on this evidence it breaks the planner's
second-tick reading — the one that exists to stop a step running twice inside its hour. The cost
of ignoring it is that the next step addition lands green in the by-name pin and silently disables
cadence de-duplication.

## Policies

- `workaholic:implementation` / `policies/test.md` — the failure must be visible at the site of the
  defect; an empty planner answer read as "no steps selected" is the opposite of visible.
- `workaholic:implementation` / `policies/error-handling.md` — a reader that cannot parse its input
  must say so by name, not answer empty with exit 0. `plan-steps.sh` currently does the latter.
- `workaholic:operation` / `policies/ci-cd.md` — the condition is latent and only fires on a future
  commit, so the repair must include a regression that fails today's tree if reintroduced.
- `workaholic:implementation` / `policies/coding-standards.md` — style of the touched shell scripts.

## Key Files

- `plugins/workaholic/skills/moderate/scripts/runtime-plan.sh` — 50 lines; emits the planner input.
- `plugins/workaholic/skills/moderate/scripts/plan-steps.sh` — the reader that answers empty.
- `plugins/workaholic/skills/runtime/scripts/state.sh` — `RECORD_MAX_BYTES` (1 MiB) and the
  snapshot read/write both sides use.
- `plugins/workaholic/skills/moderate/scripts/steps.json` — 34 steps; the fixture that must grow.
- `scripts/tests/agentic-loop/polling-cost.test.mjs` — where the symptom surfaces (line 97).

## Related History

`CLAUDE.md`, *Architecture Policy*, records the 2026-09-19 repair of a different size boundary in
`state.sh` (the `MAX_ARG_STRLEN` argv cap, ticket `20260919120809`), where an unbounded value
travelling by `argv` failed silently in three distinct ways. This has the same shape — a record
that grows past a bound and a reader that answers in silence — at a different bound, and the
repaired script's own lesson (*every unbounded value travels by file*) is the first place to look.

## Implementation Steps

1. Reproduce with the shell sequence in the Overview, at 34 and at 35 steps, and record both.
2. Establish which of the two signals is the cause: instrument where `prepare`'s stdout is produced
   and where the 1024 boundary comes from, and separately find which field `plan-steps.sh` indexes
   with `"seconds"` and what it holds at 35 steps. Do not repair before this is settled.
3. Repair the cause. If a bound is involved, carry the value by file as `state.sh` already does
   rather than raising a constant.
4. Make `plan-steps.sh` refuse by name instead of answering empty — an unreadable input is not
   "no steps selected", and the direction of that error is the dangerous one.
5. Add a regression that grows the registry fixture past today's size, so the next genuine step
   addition cannot reintroduce it.
6. Run the full `CLAUDE.md` *Local Verification* set.

## Considerations

- **Do not "fix" this by capping the registry.** The registry is meant to grow; the planner is what
  must keep up.
- **Do not change `steps.json` as part of this.** The 35th step is a fixture here, not a feature.
- The `polling-cost.test.mjs` row that surfaces the symptom must keep deriving its cold-tick
  expectation from the registry (ticket `20260919133719`); this ticket must not reintroduce a
  literal count to make a test pass.

## Quality Gate

**Acceptance criteria**

- The shell sequence in the Overview answers a parseable planner result at 35 steps, and at 40.
- `plan-steps.sh` given an input it cannot read answers a **named** reason with a non-zero-or-typed
  refusal, never empty stdout with exit 0.
- A regression exists that fails on today's tree if the cause is reintroduced, and its failure
  message names the condition rather than a count.
- `node --test scripts/tests/agentic-loop/*.test.mjs` green at 34 steps and at the grown fixture.

**Verification method**

- The Overview's sequence, run at 34, 35 and 40 steps, output recorded in the branch story.
- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/build.mjs`,
  `node scripts/build-plugins/verify.mjs`, `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `sh scripts/e2e/loop-drill.sh verify-all` — its `moderate_steps` row derives from the registry.

**Gate**

- The cause is **named** in the branch story, with the measurement that establishes it. A repair
  whose story cannot say which of the two signals was the cause does not pass this gate.
- No literal step count is introduced anywhere.
- No constraint over persisted data is tightened without exercising the upgrade path against a
  legacy snapshot record (`rules/general.md`) — the runtime snapshot store is persisted state, so
  if its shape changes, a record written by today's version must still be read back.
