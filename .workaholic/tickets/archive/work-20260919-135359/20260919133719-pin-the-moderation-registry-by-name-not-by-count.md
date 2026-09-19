---
created_at: 2026-09-19T13:37:19+09:00
status: done
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy: auto
verification_handoff:
claim: work-20260919-135359
---

# Pin the moderation registry by name, not by a count that goes stale

## Overview

`main` is red. The `validate` check on `d8c22c694` answers `total_count: 51`, `success: 50`,
`failure: 1`, and the failing run is `validate` — the job whose last step is
`node --test scripts/tests/agentic-loop/*.test.mjs`
(`.github/workflows/validate-plugins.yml:105`).

The cause is diagnosed and confirmed, not inferred from the colour. The moderation step registry
`plugins/workaholic/skills/moderate/scripts/steps.json` now holds **34** steps; the newest is
`worktree-sweep`, added by PR #1224 when the worktree reaper was finally given a caller. **33** is
written as a bare integer in three assertions:

- `scripts/tests/agentic-loop/delivery-report.test.mjs:73` — `assert.equal(registry.steps.length,33)`
- `scripts/tests/agentic-loop/delivery-report.test.mjs:74` — `assert.equal(new Set(registry.steps.map(x=>x.id)).size,33)`
- `scripts/tests/agentic-loop/polling-cost.test.mjs:86` — `…data.count,33`

Reproduced locally on the untouched base: `node --test scripts/tests/agentic-loop/delivery-report.test.mjs`
fails `P8 maintenance registry is ordered and complete` with `AssertionError … 34 !== 33`. A sibling
`[Implement]` runner independently confirmed the same two rows fail on `4b6b2e444`, so no in-flight
change causes this.

**Two things this ticket records accurately and does not overstate.** First, `main` does **not**
gate merges on remote CI (`development_main_local_proof`), so this red blocks no unit — but it is
the ground every unit lands on, and a base left red over a stale constant trains everyone to ignore
the colour, which is the failure that makes the next real red invisible. Second, `CLAUDE.md` states
that *base-health detection does not itself queue a fix* and that repair enters through the
diagnosed ask and specification path. **This ticket is that path**: the cause was measured in the
tree (the registry's own length, the three literals, a local reproduction), not read off the check's
colour.

`git log -S` shows all three literals arrived in one commit — `0ef45bad5` "Complete the agentic loop
redesign (#1080)" — and have never been edited since. They therefore went stale on the **first**
step addition after that commit, which is exactly what a bare integer guarantees.

**The repository has already learned this lesson, in this same registry.** `scripts/e2e/loop-drill.sh:1326`
derives the expected count from `steps.json` and carries the reason in a 2026-08-26 comment:

> THE EXPECTED COUNT IS DERIVED FROM `run.sh`'s OWN `STEPS`, NOT WRITTEN HERE (2026-08-26).
> It was a literal — nine, then ten — and it went stale every single time a step was added …
> The property worth drilling was never the number; it is that EVERY registered step contributes
> a reported line.

`scripts/test-workflow-scripts.mjs` reached the same shape from the other side: its `moderateSteps()`
helper (line 31) returns the id list, and every one of its fourteen consumers asserts **membership
and ordinal position by name** — `moderateSteps().includes("worktree-sweep")` (line 28209, added by
#1224 itself), `steps.indexOf("base-health") < steps.indexOf("human-checkin")`,
`assertEq("every step run.sh drives has a stated contract", missing, [])`. Not one of them pins a
count. The two `node --test` rows are the only place in the repository that still does.

## Policies

- `workaholic:implementation` / `policies/test.md` — its Responsibility is this defect verbatim:
  an operation that treats *counts* or green statuses as a substitute for reliability, "without it
  being visible what each individual test verifies", is not permitted. `assert.equal(length, 33)`
  makes the count the assertion and leaves what is verified invisible; the failure message
  `34 !== 33` names nothing a reader can act on.
- `workaholic:implementation` / `policies/objective-documentation.md` — the replacement assertion
  must state the property objectively (which steps are registered, in what order) rather than a
  magic number whose meaning lives in nobody's head.
- `workaholic:operation` / `policies/ci-cd.md` — inspections must "show … test failures … at the
  site of the change". A deliberate registry addition that fails an unrelated test file, with a
  message naming no step, moves the failure away from its site; that is the property being repaired.
- `workaholic:implementation` / `policies/coding-standards.md` — style of the touched test files.
- `workaholic:implementation` / `policies/directory-structure.md` — the assertions stay in the two
  files that already own these facts; no new shared module.

## Key Files

- `scripts/tests/agentic-loop/delivery-report.test.mjs` — lines 71-76, `P8 maintenance registry is
  ordered and complete`; holds two of the three literals.
- `scripts/tests/agentic-loop/polling-cost.test.mjs` — lines 80-92, `P5 maintenance cadence state
  selects no unchanged step twice inside its hour`; holds the third, and already reads `steps.json`
  one line below it (line 87) to build its `--executed` list.
- `plugins/workaholic/skills/moderate/scripts/steps.json` — the registry, now 34 steps.
- `plugins/workaholic/skills/moderate/scripts/plan-steps.sh` — emits `data.count` as the length of
  the **selected** step list, not the registry's.
- `scripts/e2e/loop-drill.sh` — line 1326; already derives, and carries the recorded reason.
- `scripts/test-workflow-scripts.mjs` — line 31, `moderateSteps()`; the repository's established
  by-name shape and its fourteen consumers.
- `.github/workflows/validate-plugins.yml` — line 105, the `validate` job step that is red.

## Related History

The same stale-literal defect was already diagnosed and repaired once against this exact registry,
on the drill side, and its comment predicted this recurrence. The suite side converged independently
on name-based assertions. This ticket finishes the convergence in the two files that were written
after both lessons and inherited neither.

## Implementation Steps

1. **Reproduce and localize first.** Run `node --test scripts/tests/agentic-loop/*.test.mjs` on the
   current base and record which rows fail and with what message. Confirm the two failures are the
   registry-length row and the planner-count row, and nothing else.

2. **Establish whether the two numbers are the same fact.** They are not, and the implementation
   must not fix them with the same edit. `plan-steps.sh:13` emits
   `data:{steps:.,count:length}` over the steps it **selected**; the selection filter (lines 9-11)
   admits every step whose id is absent from `last_run` with reason `first_run`. The polling-cost
   fixture's first `prepare` has an empty `last_run`, so every registered step is selected and the
   count coincides with the registry's length. The delivery-report row asserts the **registry's own
   size**; the polling-cost row asserts **that a cold tick selects all of them**. One is a fact
   about a data file, the other a fact about a script under test.

3. **`delivery-report.test.mjs` — assert a named, ordered set.** Declare the expected id list beside
   the test, in registry order, with a comment saying that adding a step means adding it here and
   that this is deliberate:

   ```js
   // The registry is a contract, so it is pinned BY NAME (2026-09-19). A bare `length` pin went
   // stale the first time a step was added (`worktree-sweep`, PR #1224) and failed with `34 !== 33`,
   // naming nothing. `loop-drill.sh:1326` recorded the same lesson in 2026-08-26.
   const EXPECTED_STEPS = ['open-log','blocked-tick','inbound-sweep','workload-logs','merge-conflicts',
     'issue-triage','stuck-prs','doc-drift','release-status','note-cadence','strategy-pace',
     'direction-health','date-will-not-hold','stalled-units','raced-units','undrivable-units',
     'standing-rulings','undelivered-units','handoff-units','thread-reconcile',
     'stranded-publications','operator-pulls','retire-claims','worktree-sweep','closable-missions',
     'unrecorded-missions','base-health','drill-health','cadence-lapse','strategy-digest',
     'question-answers','unanswered-asks','file-findings','human-checkin'];
   ```

   Replace line 73's `assert.equal(registry.steps.length,33)` with
   `assert.deepEqual(ids, EXPECTED_STEPS)` over `const ids = registry.steps.map(x=>x.id)`.

4. **Replace the duplicate check with an invariant, not a constant.** Line 74 becomes
   `assert.equal(new Set(ids).size, ids.length, 'a step id is registered twice')`. This carries no
   number at all and keeps working at step 35.

5. **Extend, do not replace, the assertions that carry recorded measurements.** Keep
   `registry.steps[0].id === 'open-log'` and `registry.steps.at(-1).id === 'human-checkin'` as their
   own assertions even though the `deepEqual` subsumes them: `human-checkin` being last is a pinned
   property with its own recorded reason (it asks with every finding in hand —
   `test-workflow-scripts.mjs`, `testModerateAskSurvivesDeadline`), and it must fail with its own
   message rather than inside a 34-element diff. Keep the per-row shape loop (line 75) unchanged.

6. **`polling-cost.test.mjs` — derive, because here deriving is not tautological.** The file already
   reads `steps.json` at line 87. Hoist that read to a local `const registry = JSON.parse(readFileSync(
   join(skills,'moderate/scripts/steps.json'),'utf8'));` before line 86, use `registry.steps` for the
   existing `--executed` list, and make line 86:

   ```js
   assert.equal(JSON.parse(run(['sh',planner,'--input',firstInput]).stdout).data.count,
     registry.steps.length, 'a cold tick selects every registered step');
   ```

   The script under test is `plan-steps.sh`, not `steps.json`, so comparing its output to the
   registry proves a real property — "all of them" — rather than restating the file to itself.
   Leave line 91's `count, 0` alone: zero is a fact about the second tick, not about the registry.

7. **Do not introduce a shared constant across the two files.** Step 2 established they assert
   different facts; a single shared `STEP_COUNT` would re-couple them and would reinstate exactly
   the failure mode being removed — one edit silently satisfying two unrelated assertions.

8. **Leave `loop-drill.sh:1326` and `test-workflow-scripts.mjs`'s `moderateSteps()` untouched.**
   Both already have the right shape; confirm by reading, and record in the story that neither
   pins a literal count.

9. Run the full local verification set from `CLAUDE.md` *Local Verification* and confirm `validate`'s
   step would pass on this tree.

## Considerations

**What each option catches and what it stops catching** — recorded so the choice is not re-litigated
(`scripts/tests/agentic-loop/delivery-report.test.mjs`):

| Option | Still catches | Stops catching | Failure message |
| --- | --- | --- | --- |
| Literal count (today) | a net change in size | a swap (one step removed, one added), a rename, a reorder | `34 !== 33` — names nothing |
| Derive from `steps.json` | nothing; `length === length` | every accidental change, which is the whole point of the row | never fires |
| **Named ordered set (chosen)** | accidental addition, removal, rename, reorder, duplicate | nothing the literal caught | names the exact id that moved |
| Literal + one shared constant | a net change in size | the same as the literal, and now one edit satisfies two unrelated facts | `34 !== 33`, in two files |

The named set is the only option that is strictly stronger than what is there now while making the
failure actionable. Its stated cost is honest and is not hidden: **a deliberate step addition still
requires an edit here.** That is intended — the row exists so that a registry change is deliberate —
and the difference from today is that the edit is one line in a list that says what it is for, and
the failure names `worktree-sweep` rather than an integer.

- This is the shape `test-workflow-scripts.mjs` already uses for classification rows in both
  directions — a word a script emits with no row fails, and a row classifying a word nothing emits
  fails. `deepEqual` over the ordered id list is that same bidirectional pin at the registry grain
  (`scripts/test-workflow-scripts.mjs` line 31 and its fourteen consumers).

- The `worktree-sweep` addition in PR #1224 did add a by-name assertion
  (`scripts/test-workflow-scripts.mjs:28209`) — the author followed the established shape. The gap
  is that the two `node --test` files are a separate runner that the same change never reached.
  Nothing in this ticket makes those two files import from `test-workflow-scripts.mjs`; coupling two
  test runners would be a worse defect than the one being fixed.

- `.github/workflows/validate-plugins.yml:105` wraps the run in
  `timeout --signal=TERM --kill-after=30s 5m`. These edits change no runtime, so the bound is not
  touched.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `node --test scripts/tests/agentic-loop/*.test.mjs` is green on a tree whose `steps.json` carries
  the current **34** steps, with zero failing rows.
- Appending a fabricated step to `steps.json` makes **something** fail, and the failure message
  **names the step id**. After the change this is `delivery-report.test.mjs`'s `deepEqual`, whose
  diff prints the added id.
- Removing any step from `steps.json` likewise fails, naming the removed id.
- Swapping two steps' order fails — a case the current literal count does not catch at all.
- `polling-cost.test.mjs` derives its expectation and therefore **passes** in the add/remove probes
  above. This is correct, not a regression: it asserts that the planner selects everything on a cold
  tick, which stays true at any registry size. State it in the story so the asymmetry is not read as
  a hole.
- No literal step count remains anywhere in `scripts/tests/agentic-loop/`.
- `registry.steps.at(-1).id === 'human-checkin'` still fails with its own message when violated.

**Verification method** — the commands/tests/probes that prove them:

- `node --test scripts/tests/agentic-loop/*.test.mjs` — green.
- `node scripts/test-workflow-scripts.mjs` — green (the registry's by-name consumers are untouched
  and must stay so).
- The add/remove/swap probes run against a scratch copy of `steps.json`, reverted after; capture
  each failure message and quote the id it named in the branch story.
- `sh scripts/e2e/loop-drill.sh verify-all` — its `moderate_steps` row already derives from
  `steps.json` (line 1326) and must remain derived and green.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — no generated
  output should move, since only test files change; a diff here means something unexpected was
  touched.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` — conforming.

**Gate** — what must pass before approval:

- Every command above is green, run in this checkout, with the add/remove/swap probe output recorded
  in the branch story rather than asserted in prose.
- The `validate` check passes on the resulting branch, and the story states that `main`'s red is
  cleared by this change and names the check run.
- The change touches only `scripts/tests/agentic-loop/delivery-report.test.mjs` and
  `scripts/tests/agentic-loop/polling-cost.test.mjs`. `steps.json` is **not** edited — the registry
  is correct and the tests were wrong.
- Existing assertions carrying recorded measurements are extended, never replaced: the `open-log` /
  `human-checkin` bookends and the per-row shape loop survive with their own messages.
- No constraint over persisted data is tightened here, so the legacy-fixture rule
  (`rules/general.md`) does not apply; say so rather than leaving it unaddressed.

## Final Report

Development completed as planned. `main`'s `validate` red is cleared: the two stale `33` literals
in `scripts/tests/agentic-loop/` are gone and `node --test scripts/tests/agentic-loop/*.test.mjs`
is green at 147/147 on the 34-step registry.

The two numbers were repaired with different edits, as step 2 required. `delivery-report.test.mjs`
now pins the registry as a named, ordered `EXPECTED_STEPS` list compared with `deepEqual`, and its
duplicate check became the number-free invariant `new Set(ids).size === ids.length`. The `open-log`
/ `human-checkin` bookends and the per-row shape loop were kept beside it, so a violated bookend
still fails with its own message rather than inside a 34-element diff. `polling-cost.test.mjs`
hoists the `steps.json` read it already performed one line below and derives its cold-tick
expectation from `registry.steps.length`; no shared constant was introduced.

Add / remove / swap probes were run against a scratch copy of the registry, restored after each.
All three fail `delivery-report.test.mjs` naming the exact id: `+ 'fabricated-probe'` (add),
`- 'retire-claims'` (remove), and both `+ 'release-status'` / `- 'release-status'` (swap — a case
the literal count could not catch at all). `loop-drill.sh:1326` and `test-workflow-scripts.mjs`'s
`moderateSteps()` were read and confirmed to pin no literal count; neither was touched.

### Discovered Insights

- **Insight**: `polling-cost.test.mjs`'s derived cold-tick assertion passes all three probes, but
  under the *add* probe the row as a whole still fails — at the pre-existing second-tick assertion
  (`data.count, 0`), not at the derived one.
  **Context**: The ticket predicted the derived assertion would pass, and it does: measured
  directly, `plan-steps.sh` answers `data.count == 35` on a cold tick over a 35-step registry. What
  fails is the *second* tick, where `plan-steps.sh` emits empty stdout and
  `jq: error … Cannot index string with string "seconds"`. Both scripts involved
  (`runtime-plan.sh`, `plan-steps.sh`) are untouched by this change, and the same sequence is green
  at the tree's real 34 steps — so this is a latent property of the planner that the 35th step will
  expose, not a regression here. Minted as ticket `20260919141500`; deliberately not repaired
  opportunistically, since its cause is not yet established and two observed signals disagree.

- **Insight**: A registry pinned by name is strictly stronger than one pinned by length and costs
  one list edit per deliberate step addition.
  **Context**: The literal caught only a *net* size change — a swap, a rename and a reorder all
  passed it — and failed with `34 !== 33`, naming nothing a reader can act on. The repository had
  already learned this twice against this same registry (`loop-drill.sh`'s 2026-08-26 comment, and
  `test-workflow-scripts.mjs`'s fourteen by-name consumers); the two `node --test` files were the
  last place still counting.
