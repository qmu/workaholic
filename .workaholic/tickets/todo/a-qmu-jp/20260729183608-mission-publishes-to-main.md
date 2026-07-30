---
created_at: 2026-07-29T18:36:08+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Domain]
effort:
commit_hash:
category:
depends_on: [20260729183606-publish-tree-primitive.md]
mission:
merge_policy: review
claim: work-20260730-171125
---

# /mission publishes to main and stops creating a worktree at creation

## Overview

`/mission` currently builds a dedicated worktree before it writes anything. [commands/mission.md](plugins/workaholic/commands/mission.md) step 2 runs `branching/scripts/create-mission-worktree.sh`, and steps 3-5 then perform every write — the mission statement, the whole ordered ticket set, the approval, the `Kick off mission <slug>` commit — inside `( cd <worktree_path> && … )` subshells. Nothing is pushed. The replan path (step 2 of the replan flow) and the bare-`/mission` planning loop recreate the same worktree when it is absent.

That directly contradicts what the repository already decided and already documents. Decision I6 in [loop-engineering-workflow.md](docs/loop-engineering-workflow.md) states that a worktree is born at claim time and torn down when its PR-unit ships; [drive/SKILL.md](plugins/workaholic/skills/drive/SKILL.md)'s Claims section states it as doctrine ("a worktree is claim-born and ship-torn"). `commands/mission.md` is the unimplemented half. The cost is not merely inconsistency: a mission approved inside an unmerged worktree is invisible to `plan-units.sh`, which is precisely the failure [drive-loop-runbook.md](docs/drive-loop-runbook.md) §6 documents ("approved missions exist but nothing is claimed — its tickets live in an unmerged worktree") and which [claim.sh](plugins/workaholic/skills/drive/scripts/claim.sh) carries a comment tolerating.

This ticket makes `/mission` a pure **source**, matching `/propose` — which already scaffolds a draft mission into the main checkout, commits, and pushes, with no worktree and no prompt. Creation, replan, approval, and close all write into a publish tree checked out at `origin/main` and push there; the developer's branch and uncommitted work are untouched; `claim.sh` becomes the only creator of a branch or a worktree anywhere in the plugin.

## Policies

- `workaholic:implementation` / [directory-structure.md](plugins/workaholic/skills/implementation/policies/directory-structure.md) — missions keep `active/<slug>/` and `archive/<slug>/`; only the checkout changes.
- `workaholic:implementation` / [coding-standards.md](plugins/workaholic/skills/implementation/policies/coding-standards.md) — POSIX `#!/bin/sh -eu`; no new conditionals in command markdown.
- `workaholic:implementation` / [domain-layer-separation.md](plugins/workaholic/skills/implementation/policies/domain-layer-separation.md) — the mission scripts are already ref-agnostic (`create.sh`, `approve.sh`, `close.sh` are cwd-relative and never branch or commit). Only the orchestration's `cd` target changes; **do not push git logic down into them**.
- `workaholic:design` / [modeless-design.md](plugins/workaholic/skills/design/policies/modeless-design.md) — creating or replanning a mission stops requiring the developer to be in, or be moved into, a particular worktree.
- `workaholic:design` / [history-structures.md](plugins/workaholic/skills/design/policies/history-structures.md) — the mission `## Changelog` append and `## Acceptance` reconciliation must keep recording transitions; a mission published to `main` then claimed later must still read as a sequence, not a final state.
- `workaholic:implementation` / [operational-planning.md](plugins/workaholic/skills/implementation/policies/operational-planning.md) — the interrupted-mid-interrogation scenario is the one to work backward from: a mission statement written but its ticket set not yet emitted must not reach `main` half-formed.
- `workaholic:planning` / [ai-native-future.md](plugins/workaholic/skills/planning/policies/ai-native-future.md) — the human seam is preserved: `approve.sh` remains the only path to `status: approved` and the only place the `merge_policy` ruling is recorded, so publishing to `main` never means auto-approving.
- `workaholic:planning` / [terminology.md](plugins/workaholic/skills/planning/policies/terminology.md) — after this change, "worktree" in this plugin means a claim worktree and nothing else. Every mention of a *mission* worktree — including the name `create-mission-worktree.sh` and its stale comments — is reconciled in this change.
- `workaholic:implementation` / [objective-documentation.md](plugins/workaholic/skills/implementation/policies/objective-documentation.md) — `close.sh`'s header and `cleanup-mission-worktree.sh`'s comment already describe a retired close-time teardown; stale comments are defects and are corrected here.

## Key Files

- [commands/mission.md](plugins/workaholic/commands/mission.md) — create path steps 2-6 (worktree creation ~L100-106, the `cd`-wrapped scaffold ~L108-114, the ticket set ~L124, `approve.sh` ~L128-132, the in-worktree commit ~L136-140, the worktree-path report ~L142); replan path step 2 (~L64-70) and its "All writes happen in the worktree" line (~L70); the bare-view planning loop (~L165); the close path's already-correct "Close touches no worktree" (~L211).
- [mission/scripts/create.sh](plugins/workaholic/skills/mission/scripts/create.sh) — cwd-relative, never branches or commits. **No change needed**; only the caller's `cd` target moves.
- [mission/scripts/approve.sh](plugins/workaholic/skills/mission/scripts/approve.sh) — file-local; the approval floor (owner / Experience / Acceptance) and the `merge_policy` ruling are unchanged.
- [mission/scripts/close.sh](plugins/workaholic/skills/mission/scripts/close.sh) — the archive move; its header still claims `commands/mission.md` tears the worktree down after it succeeds, which contradicts `commands/mission.md` itself. Fix the prose.
- [branching/scripts/create-mission-worktree.sh](plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh) — loses its creation-time caller, leaving `claim.sh` as its only one. Its fetch-first base resolution stays load-bearing for claims.
- [branching/scripts/cleanup-mission-worktree.sh](plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh) — its header comment still references the retired close-time teardown.
- [mission/SKILL.md](plugins/workaholic/skills/mission/SKILL.md) — the Worktree lifecycle section; it already states the claim-born rule and now stops being contradicted by the command.
- [propose/scripts/scaffold-draft.sh](plugins/workaholic/skills/propose/scripts/scaffold-draft.sh) — the structural twin of `create.sh`, and the proof a mission scaffold needs no worktree.
- [test-workflow-scripts.mjs](scripts/test-workflow-scripts.mjs) — §8c `testMissionBranchOnCreate` (~L1651-1704) and §8f `testMissionCreateWorktreeFlow` (~L2103-2155) assert the behaviour being removed and must be rewritten; §8e's mission-lens worktree-focus case (~L2017) changes because an unclaimed mission no longer owns a worktree.
- [CLAUDE.md](CLAUDE.md), [README.md](README.md), [rules/workaholic.md](plugins/workaholic/rules/workaholic.md) — the `/mission` row and the missions section.

## Related History

- [20260714011847-mission-create-worktree-kickoff.md](.workaholic/tickets/archive/work-20260714-000543/20260714011847-mission-create-worktree-kickoff.md) - Introduced the creation-time worktree; note it already superseded an earlier in-tree branch-on-create step, so this placement has been revised once before and revising it again is in keeping
- [20260714011846-mission-worktree-primitive.md](.workaholic/tickets/archive/work-20260714-000543/20260714011846-mission-worktree-primitive.md) - Defined the worktree scripts and the "persists until the mission ends" lifecycle that I6 replaced with claim-born/ship-torn
- [20260728221801-unify-mission-status-and-merge-policy.md](.workaholic/tickets/archive/work-20260728-221717/20260728221801-unify-mission-status-and-merge-policy.md) - Established `approve.sh` as the only path to `status: approved` and the merge-policy ruling; those seams now run against main
- [20260717152506-mission-resolution-follows-the-ticket-not-cwd.md](.workaholic/tickets/archive/work-20260717-141501/20260717152506-mission-resolution-follows-the-ticket-not-cwd.md) - Cross-checkout mission resolution in `lib/resolve.sh`, complexity that exists only because missions live in worktrees
- [20260718191500-validate-ticket-resolves-mission-in-tickets-checkout.md](.workaholic/tickets/archive/work-20260716-152211/20260718191500-validate-ticket-resolves-mission-in-tickets-checkout.md) - The same class of workaround in the ticket hook
- [20260728210302-add-proposal-batch-command-and-skill.md](.workaholic/tickets/archive/work-20260728-210259/20260728210302-add-proposal-batch-command-and-skill.md) - `/propose`, the working precedent for a mission scaffolded into the main checkout and pushed

## Implementation Steps

1. **Replace the create path's step 2** in [commands/mission.md](plugins/workaholic/commands/mission.md): `create-mission-worktree.sh` becomes `branching/scripts/open-publish-tree.sh`. Steps 3, 4, 4b and 5 keep their `( cd <path> && … )` shape — only the path changes, from `.worktrees/<slug>/` to the publish tree. The mission scripts themselves are untouched.

2. **Publish the whole creation batch as one commit.** The mission statement, the entire ordered ticket set, and the approval all land in a single `publish-tree-commit.sh` call keeping the existing subject `Kick off mission <slug>`, then the publish tree closes. One commit, because the batch is one act: a mission whose statement reached `main` without its tickets is a mission `/drive` would survey as approved with an empty queue.

3. **Guard against publishing a half-formed mission.** If the interrogation is abandoned before the ticket set is emitted, nothing is committed and nothing is pushed; the publish tree retains the partial work and the developer is told plainly that the mission is **not on `main`**. Never publish a mission that has passed the approval floor but has no tickets.

4. **Apply the same change to the replan path** (step 2 and the "All writes happen in the worktree" line) and to the **bare-`/mission` planning loop**. Replan re-enters the interrogation against the mission as published on `main`, applies the delta, emits delta tickets, and publishes them; it never creates a worktree. The fetch-first rationale currently attached to worktree creation moves to the publish-tree open, which fetches by construction.

5. **Report a mission's location honestly.** Step 6 currently reports the worktree path. It now reports the mission path on `main` and the pushed commit, and states that `/drive` creates the worktree when it claims the mission. Do not report a path the developer cannot `cd` into.

6. **Leave the close path alone functionally, fix its prose.** `close.sh` already performs only the archive move and `commands/mission.md` already says "Close touches no worktree" — but `close.sh`'s header still says the command tears the worktree down afterwards, and `cleanup-mission-worktree.sh`'s header still references a close-time teardown. Both comments are stale and are corrected here. The close itself is published to `main` through the publish tree like any other mission write.

7. **Reconcile the worktree vocabulary.** After this change `create-mission-worktree.sh` has exactly one caller, `claim.sh`, and it creates a *claim* worktree keyed on a unit id — a mission slug is only one kind of unit id. Decide and record whether to rename it (`create-claim-worktree.sh`) with a compatibility note, or keep the name and document that it is claim-only. Either way `mission/SKILL.md`'s Worktree lifecycle section states the single rule: a worktree exists only for a claim.

8. **Rewrite the tests that encode the removed behaviour.** §8c `testMissionBranchOnCreate` and §8f `testMissionCreateWorktreeFlow` assert that a mission is absent from `main` and lives inside `.worktrees/<slug>`; both must be inverted to assert the opposite. §8e's mission-lens worktree-focus case changes because an unclaimed mission no longer owns a worktree — verify what the lens should now surface in the main tree and pin it.

9. **Update the docs in this same change**: the `/mission` row and the Architecture Policy / claim-protocol prose in [CLAUDE.md](CLAUDE.md), the missions section of [rules/workaholic.md](plugins/workaholic/rules/workaholic.md), [mission/SKILL.md](plugins/workaholic/skills/mission/SKILL.md), [README.md](README.md), and [.workaholic/README.md](.workaholic/README.md).

10. **Rebuild the generated artifacts** — `mission` and `branching` ship in `outputs/workflows`; run the argument-less `node scripts/build-plugins/build.mjs` and commit the result.

## Quality Gate

**Acceptance criteria**

- `/mission "<title>"` run from a **dirty feature branch** publishes the mission statement, its full ticket set, and its approval to `origin/main` in one commit, and leaves the caller's checkout byte-identical.
- No `.worktrees/<slug>/` directory and no `work-*` branch is created by any `/mission` path — create, replan, bare view, or close. `create-mission-worktree.sh` has exactly one caller in the tree after this change: `claim.sh`.
- A mission published this way is surveyed as claimable by `plan-units.sh` from a *different* clone that has fetched — the concrete failure `drive-loop-runbook.md` §6 documents no longer reproduces.
- `hooks/validate-mission.sh` passes on the published mission: the derived-owner / Experience / Acceptance floor holds at `status: approved`, and a `draft` is never blocked.
- Every published ticket in the mission's set carries the mission's `merge_policy` inherited per the mission-emitted rule, and any deliberate per-ticket divergence carries its `Decided:` line.
- An abandoned interrogation publishes **nothing** — `origin/main` is unchanged and the partial work is recoverable in the publish tree.
- Replan against a mission on `main` applies the delta and publishes the delta tickets without creating a worktree; a `carried` successor is fleshed out the same way.
- `close.sh` still performs only the archive move; the archived mission reaches `origin/main`; no worktree is torn down by close.
- Stale prose is gone: no comment in `close.sh` or `cleanup-mission-worktree.sh` claims a close-time worktree teardown.
- The mission lens behaves correctly for a mission that owns no worktree: an approved, unclaimed mission is surfaced in the main tree, and the worktree-focus rule still scopes a claim worktree's session to its own unit.
- Every document listed in implementation step 9 describes the new flow; no document still says `/mission` creates a worktree at creation.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with §8c and §8f rewritten to assert publication to `main` and the absence of any creation-time worktree, §8e re-pinned for the lens, and new cases for: caller checkout untouched from a dirty branch; a second clone's `plan-units.sh` claiming the mission; the abandoned-interrogation case publishing nothing; replan emitting delta tickets with no worktree.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` clean with no residual `outputs/` diff.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`; `bash plugins/workaholic/hooks/posix-lint.sh` conforming.
- `grep -rn 'create-mission-worktree' plugins/` shows `claim.sh` as the only caller (plus documentation).
- A live rehearsal against a **throwaway clone** (never this repository itself — an unattended run must not push scratch commits to its `origin/main`): create a throwaway mission from a dirty feature branch, confirm it is on `origin/main` with its tickets, confirm no `.worktrees/` entry appeared, confirm the feature branch is untouched, then close and archive it.

**Gate**

- The full `## Local Verification` command set from [CLAUDE.md](CLAUDE.md) passes.
- The two contradictory tests are rewritten, not deleted — the invariant flips, so the assertion flips.
- The dependency ([20260729183606-publish-tree-primitive.md](.workaholic/tickets/todo/a-qmu-jp/20260729183606-publish-tree-primitive.md)) is merged first.

**Decided** (recorded rather than asked; override at review time):

- `Decided:` the creation batch is **one commit**, not one per artifact — the mission and its ticket set are a single act, and a partially-landed batch would be surveyed by `/drive` as an approved mission with an empty queue.
- `Decided:` an abandoned interrogation **publishes nothing** — a half-formed mission on `main` is claimable, and a runner claiming a mission with no tickets is a worse outcome than losing an unfinished draft that the publish tree still holds.
- `Decided:` `close` also publishes through the publish tree — the archive move is a mission write like any other, and leaving it on the caller's checkout would reintroduce the exact invisibility this change removes.
- `Decided:` the mission scripts (`create.sh`, `approve.sh`, `close.sh`) are **not modified** — they are already ref-agnostic and cwd-relative; pushing git logic into them would duplicate the publish sequence and break the single-implementation rule.
- `Decided:` verification is the **hermetic suite plus one live rehearsal against a throwaway clone**, matching the sibling tickets.

## Considerations

- **The renaming decision in step 7 is deliberately left open with a recorded ruling required** (`plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh`). Renaming touches `claim.sh`, the tests, and several docs; keeping the name leaves a misnomer in the most load-bearing script of the claim protocol. Whichever is chosen, record the reason — a later reader will ask.
- **Cross-checkout mission resolution becomes mostly dead code** (`plugins/workaholic/skills/mission/scripts/lib/resolve.sh`, `plugins/workaholic/hooks/validate-ticket.sh`). It exists because missions lived in worktrees. It is **not** removed here: a claimed mission still lives in a claim worktree during a drive, so resolution still needs to follow the artifact. Simplifying `claim.sh`'s now-unnecessary tolerance belongs to the drive-side ticket, not this one.
- **The mission lens's worktree-focus rule loses its most common trigger** (`plugins/workaholic/hooks/mission-lens.sh`). Today an active mission usually owns a worktree and is therefore silent in the main tree; after this change an unclaimed mission owns none and surfaces in the main tree, which is the intent — but it changes what a developer sees on every turn, so pin the new behaviour in a test rather than discovering it in use.
- **`/mission` close and `/drive`'s archive both write mission state** (`plugins/workaholic/skills/drive/scripts/archive.sh` L94). Archive runs inside a claim worktree and mutates that checkout's `mission.md`, reaching `main` when the PR merges; close publishes directly. Both paths are correct, but a mission closed while a claim is in flight can produce a merge conflict on `mission.md`. Worth a note in the runbook.
- **`/fb` still commits without pushing and without a main guard** (`plugins/workaholic/commands/fb.md`). A feedback recorded on a work branch never reaches `/propose`'s cursor, which reads records merged to `main`. Out of scope here — the request was tickets and missions — but it is the same defect and the primitive now exists to fix it.
