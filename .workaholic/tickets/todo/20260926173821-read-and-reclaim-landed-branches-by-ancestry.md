---
created_at: 2026-09-26T17:38:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: merge-pull-requests-so-landed-branches-read-as-merged
merge_policy:
verification_handoff: 
---

# Read and reclaim landed branches by ancestry

## Overview

Once every merge is a merge commit (previous ticket), a landed branch's tip is an ancestor of
`main`, so ancestry answers "did this land" again. Make the readers that were written around the
squash exception use it: `survey-worktrees.sh`'s `merged` (`ahead == 0`) now turns true for a
landed unit, so the hourly `worktree-sweep` reclaims its worktree; and the local `work-*` branches
the developer saw piling up (about 22 today) are named and removed once proved landed, so a
landed branch stops looking unfinished.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/survey-worktrees.sh`, `reap-worktrees.sh` — `merged` by ancestry; confirm a merge-committed unit reads `reclaimable` when clean.
- `plugins/workaholic/skills/moderate/scripts/step-worktree-sweep.sh` — its header states landed branches are permanently `merged: false` under squash; update to the new behaviour.
- `plugins/workaholic/skills/branching/scripts/content-reached-base.sh`, `drive/scripts/claim-merged.sh`, `drive/reference/claims.md` — squash-specific proof paths; keep them for already squash-landed branches and state ancestry as the first proof.
- `plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh` — the ship-time teardown; delete the local branch too once its tip is an ancestor of `origin/main`.
- `CLAUDE.md` (*Claim protocol*: "Under squash merges a landed branch stays `merged: false`").

## Implementation Steps

1. Reproduce: in a fixture, merge a claim branch with a merge commit and run `survey-worktrees.sh`; confirm `merged: true` and `reclaimable: true` when clean (and that the unmerged case is unchanged).
2. Update the squash-era headers and the CLAUDE.md sentence to the ancestry reading; `superseded` stays tree-derived.
3. Local branches: when a worktree is reaped or a unit is shipped, delete the local `work-*` branch whose tip is an ancestor of `origin/main` (`git branch -d`, never `-D`), idempotently and refusing by word otherwise.
4. Already squash-landed local branches (the ~22 the developer saw): name them through the existing tree proof (`content-reached-base.sh`) and remove only those proved landed; a branch that is not proved stays and is named.
5. Update the suite and the drill that covers the sweep.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A merge-committed, clean claim worktree reads `merged: true` / `reclaimable: true` and the hourly sweep removes it; its local branch is deleted with `git branch -d`.
- A branch not proved landed is never deleted and is named with its reason.
- No document still says landed branches stay `merged: false`.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic fixture in `scripts/test-workflow-scripts.mjs` covering merge-committed, squash-landed and unlanded branches.
- `sh scripts/e2e/loop-drill.sh verify-all` passes.

**Gate** — what must pass before approval:

- The local proof set (`branching/scripts/local-proof.sh`) answers `ok: true`.

## Considerations

- Deleting local branches is a write outside the claim oracle (which reads remote branches only), so it changes no claim verdict; it must still never use `-D` or delete a branch holding work found on no other ref.
- `delete_branch_on_merge` stays on, so remote branches keep disappearing at merge.
