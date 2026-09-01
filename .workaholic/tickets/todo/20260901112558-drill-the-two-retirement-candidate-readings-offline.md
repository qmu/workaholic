---
created_at: 2026-09-01T11:25:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260901112558-bound-the-ci-delete-act-by-the-new-candidates.md
mission: leave-only-live-work-in-the-unmerged-branch-list
merge_policy:
verification_handoff: 
---

# Drill the two retirement candidate readings offline

## Overview

PROPOSED. The two new candidate classes feed a **destructive** act, and the repository's rule for
that is a drill with a breaker row written against the behaviour rather than against a return
shape (`docs/loop-drill-runbook.md` §9). Without one, the drill register classifies the mechanism
`unproved` and `test-workflow-scripts.mjs` fails on a drill it cannot classify.

The behaviour to break is precise: a branch that must **not** be deleted being offered as a
candidate, or the act taking a candidate whose proof moved between the list and the act.

## Policies

- `workaholic:implementation` / `policies/testing.md` — a proof is a test that can fail
- `workaholic:safety` / `policies/change-management.md` — a destructive act is drilled before it ships

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; `verify-all` derives what it runs from its own
  `case` arms plus the register, so a new verb needs both.
- `docs/loop-drill-runbook.md` §9 — the drill register (one table, one reader), including the
  `bearing: "breaker"` column an unproved drill lacks.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check run is named
  after the drill; that is what lets `/moderate`'s `drill-health` step name it.

## Implementation Steps

1. Add `verify-retirement-candidates` to `loop-drill.sh`: a hermetic fixture repository with a
   stubbed pull-request transport, seeded with one branch per case — merged, closed-unmerged, open,
   no pull request, a live claim row over a merged pull request, and an unreadable read.
2. Assert the **candidate reading**: exactly the merged and the closed-unmerged branches are
   offered, each with its own `candidate_reason`; the live-row branch is offered under no class;
   the unreadable one contributes no candidate and names its reason.
3. Assert the **act**: a candidate whose pull-request state moved between the list and the act is
   refused by its own word with nothing deleted; a closed-unmerged branch still holding work is
   refused `branch_holds_work`; an already-gone branch answers `already_gone`.
4. Write the **breaker row** against behaviour: revert the live-row resolution to first-match and
   the drill must fail, because first-match returns the oldest — i.e. the dead — branch, which is
   the shape `list-retirable-claims.sh`'s header names as the one that would hand CI a branch a run
   is still driving.
5. Register the drill in `docs/loop-drill-runbook.md` §9 with its bearing, its hermetic
   classification and its failure-reason→file blame row, and add its matrix leg.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-retirement-candidates` passes offline, with no network and
  no credential.
- `verify-all` includes it and the register classifies it (not `skipped:unclassified`).
- The breaker in step 4 makes it fail; restoring the code makes it pass.
- `loop-drills.yml` gains one matrix leg named after the drill.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all` — one verdict per drill, non-zero only on a real failure.
- Apply the breaker, re-run, observe the failure, revert.
- `node scripts/test-workflow-scripts.mjs` — fails on an unclassified drill, so a pass proves the
  register row exists.

**Gate** — what must pass before approval:

- `sh scripts/e2e/loop-drill.sh verify-all` green.
- `node scripts/test-workflow-scripts.mjs` passes.

## Considerations

- The drill must stay hermetic: the pull-request state is the one fact it cannot derive from a
  local fixture, so it is stubbed at the `branch-pull-request-state.sh` seam rather than by faking a
  network. That is why the first ticket puts the read in its own script.
- Drilling the reading and the act in one verb is deliberate — the failure this exists to catch
  lives in the **gap** between them, which two separate drills would each pass.
