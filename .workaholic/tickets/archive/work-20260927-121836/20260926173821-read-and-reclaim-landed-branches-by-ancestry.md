---
created_at: 2026-09-26T17:38:21+09:00
status: done
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

## Final Report

Development completed as planned. `survey-worktrees.sh` already read `merged` by ancestry, so a merge-committed clean worktree now reads `reclaimable`; `reap-worktrees.sh --apply` additionally removes the reaped worktree's local `work-*` branch when its tip is an ancestor of `origin/<base>` (`git update-ref -d <ref> <tip>`, never `-D`), reporting `branch_removed` / `branch_kept_reason`. The new `branching/scripts/prune-landed-branches.sh [--apply]` names every local `work-*` branch and removes only those proved landed (`ancestor`, or `content_landed` via `content-reached-base.sh`), keeping `checked_out`, `not_landed` and `no_base` by name. Squash-era headers and docs (CLAUDE.md, branching SKILL, step-worktree-sweep, moderate workflow, claims reference, runbook) now state the ancestry reading. `cleanup-mission-worktree.sh` already deletes the claim's local branch at teardown and is unchanged.

### Discovered Insights

- **Insight**: a dry run against this repository's root checkout proves only 2 of the 21 unchecked-out local `work-*` branches landed (`content_landed`); 19 read `not_landed` because `content-reached-base.sh` requires the branch's whole patch to reverse-apply on today's base, which later edits to the same lines defeat.
  **Context**: the pre-ruling squash-landed backlog is only partly provable by content; the rest stays named rather than guessed about, and the pruner was not applied to the root checkout by this unattended run.
- **Insight**: the sweep test pinned "the removed worktree's branch ref is still present"; the safety property it guarded is that no commit is lost, which ancestry preserves, so the pin now asserts the landed branch is removed and its tip stays reachable from the base.
  **Context**: a pin on a mechanism (ref survives) rather than the property (commit reachable) had to move with the ruling.

## Archive delivery evidence

Implementation archived; delivery is pending verification. This is not a landed claim.

Pre-archive head: `13b7e98b2ff8ca99f90e7970ea194f6bd565a531`; observed base: `cef35848fa1d171699fb8d1812c1471a47222d3f`.

Committed-tree assessment (does not cover uncommitted implementation):

```json
{"branch":"work-20260927-121836","head":"13b7e98b2ff8ca99f90e7970ea194f6bd565a531","base":"cef35848fa1d171699fb8d1812c1471a47222d3f","state":"pending","reason":"review_required","tree":"ea04e9a6ee786434e87d718403021e51951c6f6f","paths":["CLAUDE.md","docs/agentic-loop-redesign.md","plugins/workaholic/commands/implement.md","plugins/workaholic/skills/branching/scripts/prune-landed-branches.sh","plugins/workaholic/skills/branching/scripts/reap-worktrees.sh","plugins/workaholic/skills/commit/SKILL.md","plugins/workaholic/skills/commit/scripts/commit.sh","plugins/workaholic/skills/drive/SKILL.md","plugins/workaholic/skills/drive/reference/routing.md","plugins/workaholic/skills/drive/scripts/attribute-base-red.sh","plugins/workaholic/skills/gather/scripts/merge-commit-body.sh","plugins/workaholic/skills/gather/scripts/merge-method.sh","plugins/workaholic/skills/moderate/scripts/persist-log.sh","plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh","plugins/workaholic/skills/ship/scripts/merge-pr.sh","scripts/test-workflow-scripts.mjs","scripts/tests/agentic-loop/delivery-report.test.mjs"],"delivery_claim":"assessment_only_not_a_retirement_proof"}
```

Worktree/index paths at archival (including expected implementation):

```text
 D .workaholic/tickets/todo/20260926173821-read-and-reclaim-landed-branches-by-ancestry.md
 M CLAUDE.md
 M docs/drive-loop-runbook.md
 M outputs/workflows/skills/catch/branching/scripts/reap-worktrees.sh
 M outputs/workflows/skills/catch/commit/scripts/commit.sh
 M outputs/workflows/skills/catch/drive/scripts/attribute-base-red.sh
 M outputs/workflows/skills/catch/gather/scripts/merge-commit-body.sh
 M outputs/workflows/skills/catch/gather/scripts/merge-method.sh
 M outputs/workflows/skills/catch/ship/scripts/extract-deferred-concerns.sh
 M outputs/workflows/skills/catch/ship/scripts/merge-pr.sh
 M outputs/workflows/skills/create-ticket/branching/scripts/reap-worktrees.sh
 M outputs/workflows/skills/create-ticket/commit/scripts/commit.sh
 M outputs/workflows/skills/create-ticket/drive/scripts/attribute-base-red.sh
 M outputs/workflows/skills/create-ticket/gather/scripts/merge-commit-body.sh
 M outputs/workflows/skills/create-ticket/gather/scripts/merge-method.sh
 M outputs/workflows/skills/create-ticket/ship/scripts/extract-deferred-concerns.sh
 M outputs/workflows/skills/create-ticket/ship/scripts/merge-pr.sh
 M outputs/workflows/skills/drive/SKILL.md
 M outputs/workflows/skills/drive/branching/scripts/reap-worktrees.sh
 M outputs/workflows/skills/drive/commit/scripts/commit.sh
 M outputs/workflows/skills/drive/drive/scripts/attribute-base-red.sh
 M outputs/workflows/skills/drive/gather/scripts/merge-commit-body.sh
 M outputs/workflows/skills/drive/gather/scripts/merge-method.sh
 M outputs/workflows/skills/drive/reference/claims.md
 M outputs/workflows/skills/drive/reference/routing.md
 M outputs/workflows/skills/drive/ship/scripts/extract-deferred-concerns.sh
 M outputs/workflows/skills/drive/ship/scripts/merge-pr.sh
 M outputs/workflows/skills/mission/branching/scripts/reap-worktrees.sh
 M outputs/workflows/skills/mission/commit/scripts/commit.sh
 M outputs/workflows/skills/mission/drive/scripts/attribute-base-red.sh
 M outputs/workflows/skills/mission/gather/scripts/merge-commit-body.sh
 M outputs/workflows/skills/mission/gather/scripts/merge-method.sh
 M outputs/workflows/skills/mission/ship/scripts/extract-deferred-concerns.sh
 M outputs/workflows/skills/mission/ship/scripts/merge-pr.sh
 M outputs/workflows/skills/ship/branching/scripts/reap-worktrees.sh
 M outputs/workflows/skills/ship/commit/scripts/commit.sh
 M outputs/workflows/skills/ship/drive/scripts/attribute-base-red.sh
 M outputs/workflows/skills/ship/gather/scripts/merge-commit-body.sh
 M outputs/workflows/skills/ship/gather/scripts/merge-method.sh
 M outputs/workflows/skills/ship/ship/scripts/extract-deferred-concerns.sh
 M outputs/workflows/skills/ship/ship/scripts/merge-pr.sh
 M outputs/workflows/skills/story/branching/scripts/reap-worktrees.sh
 M outputs/workflows/skills/story/commit/scripts/commit.sh
 M outputs/workflows/skills/story/drive/scripts/attribute-base-red.sh
 M outputs/workflows/skills/story/gather/scripts/merge-commit-body.sh
 M outputs/workflows/skills/story/gather/scripts/merge-method.sh
 M outputs/workflows/skills/story/ship/scripts/extract-deferred-concerns.sh
 M outputs/workflows/skills/story/ship/scripts/merge-pr.sh
 M plugins/workaholic/skills/branching/SKILL.md
 M plugins/workaholic/skills/drive/reference/claims.md
 M plugins/workaholic/skills/moderate/reference/workflow.md
 M plugins/workaholic/skills/moderate/scripts/step-worktree-sweep.sh
?? .workaholic/tickets/archive/work-20260927-121836/20260926173821-read-and-reclaim-landed-branches-by-ancestry.md
?? outputs/workflows/skills/catch/branching/scripts/prune-landed-branches.sh
?? outputs/workflows/skills/create-ticket/branching/scripts/prune-landed-branches.sh
?? outputs/workflows/skills/drive/branching/scripts/prune-landed-branches.sh
?? outputs/workflows/skills/mission/branching/scripts/prune-landed-branches.sh
?? outputs/workflows/skills/ship/branching/scripts/prune-landed-branches.sh
?? outputs/workflows/skills/story/branching/scripts/prune-landed-branches.sh
```
