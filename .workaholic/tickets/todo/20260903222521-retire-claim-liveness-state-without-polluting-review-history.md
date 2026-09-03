---
created_at: 2026-09-03T22:25:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: carry-claim-liveness-off-the-review-branch
merge_policy:
verification_handoff:
---

# Retire claim liveness state without polluting review history

## Overview

Give the separate liveness carrier the same lifecycle as its claim. Merge, deliberate release,
supersession, and recovery must leave no live-looking orphan, while cleanup failures remain visible
and never alter the work branch or destroy recoverable work.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/disaster-recovery.md` — cleanup must preserve recoverable work

## Key Files

- `plugins/workaholic/skills/drive/scripts/release-claim.sh` — deliberate claim teardown.
- `plugins/workaholic/skills/drive/scripts/archive.sh` — work progress and final push seam.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — merged and superseded lifecycle readings.
- `plugins/workaholic/skills/branching/scripts/` — merge paths that finish claims.
- `scripts/e2e/loop-drill.sh` — end-to-end claim lifecycle proof.

## Implementation Steps

1. Enumerate every terminal claim path and define which one deletes the carrier and which one only
   reports it for a later safe cleanup.
2. Delete the carrier as part of deliberate release and after proved merge/supersession, guarded by
   the carrier's expected identity so cleanup cannot remove a new runner's beat.
3. Make a failed cleanup non-destructive and named; keep the work branch and worktree recoverable.
4. Update the claim contract and ticket workflow to state that liveness is separate and disposable.
5. Drill claim, repeated beat, work commit, resume, merge, and release; assert no heartbeat commit is
   present on the pull-request branch and no terminal carrier remains.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every terminal lifecycle either removes the carrier or reports the exact carrier still standing.
- Review history contains claim/work commits only, with zero heartbeat commits after repeated beats.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- Cleanup is compare-and-delete, never an unqualified deletion of mutable shared state.

## Considerations

- A legacy heartbeat commit is history and is not rewritten; the guarantee applies after cutover.
- A cleanup failure delays collection but must never release or overwrite an active claim.
