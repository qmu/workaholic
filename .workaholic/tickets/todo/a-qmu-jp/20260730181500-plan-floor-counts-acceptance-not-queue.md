---
created_at: 2026-07-30T18:15:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy: review
claim: work-20260730-191139
---

# "Has a plan" is measured by acceptance-item count, so a proposal sketch can be approved and offered as a drivable unit with an empty queue

## Overview

Two floors are supposed to stop an unattended runner from claiming a mission it cannot drive: `approve.sh` refuses `no_plan`, and `plan-units.sh` excludes `no_plan` from the offer. Both measure the same thing — how many items the mission's `## Acceptance` section contains — and neither asks whether a single **ticket** exists to implement them. A `/propose` draft satisfies both by construction, because the proposal batch writes a *provisional acceptance sketch* into exactly that section.

Observed live on 2026-07-30 in this repository. `.workaholic/missions/active/adopt-a-git-flow-branching-model-with-durable-ship-records/mission.md` carries:

```yaml
status: approved
merge_policy: auto
tickets: []
```

and an `## Acceptance` section whose own first line reads:

> **PROPOSED sketch for discussion — not a plan.** Approval replans this mission to drive-ready.

`plan-units.sh` offers it as claimable (`0/8`, `merge_policy: auto`), and no ticket in `todo/` carries its `mission:` relation — the survey reported no `mission_member` exclusion for it. So `/drive` would claim the unit, create its worktree, run `list-todo.sh` inside it, find **nothing**, and report a unit with an empty queue. The `auto` policy makes it worse than a wasted tick: the run is authorized to merge whatever it produced, against acceptance criteria the mission itself labels as not a plan.

The gap between the two states matters. A mission with `0/0` acceptance is *correctly* excluded today (`total == 0` → `no_plan`), and the mission skill routes it to replan. A mission with `0/8` acceptance and zero tickets is indistinguishable from a fully-planned mission to every floor in the system, and it is exactly the shape `/propose` produces.

## Policies

- `workaholic:planning` / [ai-native-future.md](plugins/workaholic/skills/planning/policies/ai-native-future.md) — the governing policy. The human seam must survive the automation: `approve.sh` is the one place a developer asserts that every judgement call about *these exact tickets* was answered, and a floor that passes when there are no tickets removes the assertion's subject.
- `workaholic:implementation` / [observability.md](plugins/workaholic/skills/implementation/policies/observability.md) — the failure is silent and confident: the survey offers the unit with a healthy-looking `0/8`, and the empty queue is discovered only after a claim branch and worktree exist. The condition must be reported at survey time, with a reason.
- `workaholic:implementation` / [domain-layer-separation.md](plugins/workaholic/skills/implementation/policies/domain-layer-separation.md) — "does this mission have a drivable plan" must have one implementation that `approve.sh` and `plan-units.sh` both read, rather than two independent acceptance counts that can drift.
- `workaholic:implementation` / [objective-documentation.md](plugins/workaholic/skills/implementation/policies/objective-documentation.md) — whatever the floor becomes must be stated in verifiable terms (a queue count, not "looks ready"), and `no_plan`'s meaning is a user-facing contract named once in the skill and the runbook.
- `workaholic:implementation` / [coding-standards.md](plugins/workaholic/skills/implementation/policies/coding-standards.md) — POSIX `#!/bin/sh -eu` per [rules/shell.md](plugins/workaholic/rules/shell.md).

## Key Files

- [plan-units.sh](plugins/workaholic/skills/drive/scripts/plan-units.sh) — the `total -eq 0` → `no_plan` exclusion and the comment claiming it applies "the same floor `drive-authorized.sh` applies per ticket".
- [approve.sh](plugins/workaholic/skills/mission/scripts/approve.sh) — the approval floor (owner + `## Experience` + `## Acceptance`) and its `no_plan` refusal.
- [scaffold-draft.sh](plugins/workaholic/skills/propose/scripts/scaffold-draft.sh) and [commands/propose.md](plugins/workaholic/commands/propose.md) step 6 — the writer of the provisional acceptance sketch that satisfies the floor. The batch is correct to write one; the floor is wrong to count it.
- [mission/SKILL.md](plugins/workaholic/skills/mission/SKILL.md) — the *Approval* and *Lifecycle* sections state what `approved` asserts; whatever floor is chosen is stated there once.
- [progress.sh](plugins/workaholic/skills/mission/scripts/progress.sh) — the acceptance counter both floors read through.
- [read-relation.sh](plugins/workaholic/skills/mission/scripts/read-relation.sh) — the single reader for a ticket's `mission:` relation, which is how a queue count must be derived.
- [drive/SKILL.md](plugins/workaholic/skills/drive/SKILL.md) — the survey section and its statement that "every ticket in a claimed mission unit passes [the authorization floor] by construction", which this defect falsifies.
- [test-workflow-scripts.mjs](scripts/test-workflow-scripts.mjs) — `testPlanUnitsExclusions` covers `no_plan` for a `0/0` mission only; the `0/N`-with-no-tickets case has no coverage.

## Related History

- [20260728221801-unify-mission-status-and-merge-policy.md](.workaholic/tickets/archive/work-20260728-221717/20260728221801-unify-mission-status-and-merge-policy.md) - Established `approve.sh` as the only path to `status: approved` and defined its floor as owner + Experience + Acceptance
- [20260728221803-unify-drive-executor.md](.workaholic/tickets/archive/work-20260728-221717/20260728221803-unify-drive-executor.md) - Built `plan-units.sh` and moved the per-ticket authorization floor up to the offer, which is where the acceptance-count proxy became load-bearing
- [20260728210302-add-proposal-batch-command-and-skill.md](.workaholic/tickets/archive/work-20260728-210259/20260728210302-add-proposal-batch-command-and-skill.md) - Built `/propose`, whose provisional acceptance sketch is what satisfies the floor
- [20260729183608-mission-publishes-to-main.md](.workaholic/tickets/archive/work-20260730-171125/20260729183608-mission-publishes-to-main.md) - Made the whole creation batch one commit precisely so a mission's statement could never reach `main` without its tickets; this ticket closes the other route to the same end state

## Implementation Steps

1. **Add a single reader for "does this mission have a drivable queue"** under `mission/scripts/` — the count of tickets in `todo/` whose `mission:` relation names the slug, read through `read-relation.sh` (never re-parsed). Both floors call it; neither implements it.

2. **Make `plan-units.sh` exclude a mission with zero queued tickets**, with a **distinct** reason (e.g. `no_tickets`) rather than reusing `no_plan`. The two conditions call for different developer actions — `no_plan` means write the acceptance criteria, `no_tickets` means emit the ticket set — and the `excluded[]` vocabulary is a user-facing contract read in cron output.

3. **Decide whether `approve.sh` refuses the same condition, and record the ruling.** Refusing at approval is the stronger position (a mission is not approvable before its tickets exist) and matches what `commands/mission.md` step 4b already says. The argument against is a legitimate order-of-operations case — a developer approving a mission whose tickets are emitted in the same batch — which the create flow handles by approving *after* emission. Whichever is chosen, state it in `mission/SKILL.md`'s *Approval* section.

4. **Correct the two claims this defect falsifies.** `plan-units.sh`'s comment says its floor is "the same floor `drive-authorized.sh` applies per ticket"; `drive/SKILL.md` says "every ticket in a claimed mission unit passes it by construction". Both are false when the unit has no tickets. Rewrite them to describe the floor as implemented.

5. **Reconcile the live mission that surfaced this.** `adopt-a-git-flow-branching-model-with-durable-ship-records` is `approved` + `auto` with an unreplanned proposal sketch and no tickets. Do **not** silently demote it: report it, and leave the replan (which requires the developer's interrogation) as the developer's action. The fix here only stops it being *offered*; making it drivable is a planning act, not a code change.

6. **Add the coverage the current fixture lacks.** Extend `testPlanUnitsExclusions` with a mission at `0/N` acceptance and zero related tickets, asserting the new reason; and a mission at `0/N` **with** tickets, asserting it is still offered. Add the `approve.sh` case matching step 3's ruling.

## Quality Gate

**Acceptance criteria**

- A mission with a non-empty `## Acceptance` and **zero** tickets in `todo/` carrying its `mission:` relation is **not** offered by `plan-units.sh`, and appears in `excluded[]` with a reason distinct from `no_plan`. This is the criterion the ticket exists for.
- A mission with a non-empty `## Acceptance` and at least one related ticket is still offered, unchanged — the fix must not exclude a legitimately planned mission whose acceptance is merely unchecked.
- A `0/0` mission is still excluded as `no_plan`; the two reasons never collapse into one.
- The queue count is derived through `read-relation.sh` in **one** place that both floors call; neither `plan-units.sh` nor `approve.sh` counts relations itself.
- `approve.sh` behaves per the step-3 ruling, and that ruling is written in `mission/SKILL.md`'s *Approval* section with its reason.
- `plan-units.sh`'s "same floor as `drive-authorized.sh`" comment and `drive/SKILL.md`'s "passes it by construction" sentence describe the floor as it is actually implemented.
- The new reason appears in `docs/drive-loop-runbook.md` §6 with the developer action it implies (emit the ticket set via `/mission <instruction>` replan).
- Every new script is POSIX `#!/bin/sh -eu` and `hooks/posix-lint.sh` reports `conforming: true`.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, extended per implementation step 6: the `0/N`-with-no-tickets exclusion, the `0/N`-with-tickets non-exclusion, the unchanged `0/0` case, and the `approve.sh` case.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` clean with no residual `outputs/` diff (`drive` and `mission` ship in `outputs/workflows`).
- `bash plugins/workaholic/hooks/posix-lint.sh` conforming; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- A live read-only check against this repository: `plan-units.sh` no longer offers `adopt-a-git-flow-branching-model-with-durable-ship-records` and names the new reason for it.

**Gate**

- The full `## Local Verification` command set from [CLAUDE.md](CLAUDE.md) passes.
- The `0/N`-with-no-tickets case is covered by a **named** test — the existing fixture only expresses `0/0`, which is why this shipped.
- The step-3 ruling on `approve.sh` is recorded in the skill, not only in code.

**Decided** (recorded rather than asked; override at review time):

- `Decided:` a **new** `excluded[]` reason, not a widened `no_plan`. The two states imply different developer actions, and the reason vocabulary is read straight out of cron logs — collapsing them would make the log less actionable, which is the opposite of what `excluded[]` is for.
- `Decided:` `/propose` is **not** changed. Writing a provisional acceptance sketch is right and useful — it is what a human replans *from*. The defect is that a downstream floor counts it as a plan, so the floor is what moves.
- `Decided:` the live mission is **reported, not demoted**. Flipping another actor's approved mission back to `draft` from inside an unattended run would be an unattended run overriding a human ruling; the code stops offering it, and the developer replans it.
- `Decided:` this is a **bugfix**. An unattended run can currently claim, branch, and worktree a unit it cannot drive, under an `auto` merge policy — that is a correctness hole in the authorization chain, not a usability wrinkle.

## Considerations

- **`merge_policy: auto` is what raises the severity.** An empty-queue claim under `review` wastes a tick and a worktree. Under `auto`, the run holds authority to merge, and the only thing standing between it and merging an invented plan is that there are no tickets to invent from — a safety property that comes from absence rather than from a gate.
- **This is the other route to the state ticket 20260729183608 closed.** That ticket made the mission creation batch one commit so a statement could never reach `main` without its tickets. The same end state is reachable through `/propose` plus an approval, and closing this is what makes that invariant hold from both directions.
- **The `0/N`-with-tickets case must stay offered, and it is the common one.** Every legitimately planned mission starts at `0/N` with a full queue; a fix that keys on `checked == 0` instead of on the queue count would exclude every mission at the moment it becomes drivable.
- **Step 3 is a genuine order-of-operations question, not a formality.** `commands/mission.md`'s create flow already approves *after* emitting the set, so refusing at approval costs nothing there — but a developer approving a hand-authored mission in two sittings would hit it. The `/mission approve` route's step 2 (replan to drive-ready first) is the answer, and the ruling should say so rather than leaving the interaction to be rediscovered.
