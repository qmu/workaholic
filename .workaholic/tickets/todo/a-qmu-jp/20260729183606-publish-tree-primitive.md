---
created_at: 2026-07-29T18:36:06+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy: review
claim: work-20260730-171125
---

# Publish-tree primitive: write an artifact to main without touching the working tree

## Overview

Today the two human-facing artifact sources cut a git ref *before* any artifact is written: `/ticket` calls `branching/scripts/create.sh` when it finds itself on `main`, and `/mission` calls `branching/scripts/create-mission-worktree.sh` and performs every write inside `.worktrees/<slug>/`. Neither pushes. The result is that a ticket or a mission exists only on a local, unpushed ref that no other runner, no other machine, and no fresh clone can see — which is exactly why [drive-loop-runbook.md](docs/drive-loop-runbook.md) §6 already lists "approved missions exist but nothing is claimed" with the cause "its tickets live in an unmerged worktree", and why [claim.sh](plugins/workaholic/skills/drive/scripts/claim.sh) carries a comment tolerating a mission with no `mission.md` in the main tree.

The target model is the one `/propose` already implements: **an artifact is published to `main`; the executor is the only thing that creates a branch and a worktree, at claim time.** That completes decision I6 in [loop-engineering-workflow.md](docs/loop-engineering-workflow.md) ("a worktree is born at claim time and torn down when its PR-unit ships"), which `drive/SKILL.md` and `mission/SKILL.md` already state as doctrine while `commands/mission.md` still contradicts it.

`/propose` can guard on "on `main` with a clean tree, else abort" because it is a headless cron batch. `/ticket` and `/mission` cannot: a developer types them at any moment, most often while mid-work on a branch with a dirty tree. Aborting there would make the sources unusable exactly when they are most useful. **The decided answer is that publication never depends on, and never disturbs, the caller's checkout**: the artifact is written, committed, and pushed inside a dedicated, git-ignored *publish tree* checked out at `origin/main`, and the caller's branch and uncommitted work are left untouched.

This ticket builds that primitive and nothing else. The two callers land in the tickets that depend on this one.

## Policies

- `workaholic:implementation` / [directory-structure.md](plugins/workaholic/skills/implementation/policies/directory-structure.md) — the new scripts belong in `skills/branching/scripts/`, alongside the other ref-manipulating scripts, not in a new top-level area.
- `workaholic:implementation` / [coding-standards.md](plugins/workaholic/skills/implementation/policies/coding-standards.md) — POSIX `#!/bin/sh -eu` per [rules/shell.md](plugins/workaholic/rules/shell.md); all conditional logic lives in the script, never inline in command markdown.
- `workaholic:implementation` / [command-scripts.md](plugins/workaholic/skills/implementation/policies/command-scripts.md) — the publish sequence is consolidated into runnable scripts so a human, `/ticket`, `/mission`, and CI all perform it identically.
- `workaholic:implementation` / [infrastructure-as-code.md](plugins/workaholic/skills/implementation/policies/infrastructure-as-code.md) — every piece of coordination state stays derivable from git refs. The publish tree holds no state of its own; it is reconstructible from `origin/main` at any moment and disposable.
- `workaholic:implementation` / [operational-planning.md](plugins/workaholic/skills/implementation/policies/operational-planning.md) — the recovery behaviour is worked backward from the concrete failure scenarios enumerated under Implementation Steps and Considerations, not from an abstract target.
- `workaholic:implementation` / [domain-layer-separation.md](plugins/workaholic/skills/implementation/policies/domain-layer-separation.md) — the publish sequence lives once, in these scripts; callers are thin. Do not let `/ticket` and `/mission` each re-implement fetch/commit/push.
- `workaholic:design` / [sacrificial-architecture.md](plugins/workaholic/skills/design/policies/sacrificial-architecture.md) — a change of this size gets a new lettered decision in `docs/loop-engineering-workflow.md`, not a silent rewrite of `CLAUDE.md` prose.
- `workaholic:planning` / [terminology.md](plugins/workaholic/skills/planning/policies/terminology.md) — "publish tree" is a new term and must be minted once, defined in `branching/SKILL.md`, and used identically everywhere. It is **not** a claim worktree and must never be described as one.

## Key Files

- `plugins/workaholic/skills/branching/scripts/` — where the new scripts land.
- [check.sh](plugins/workaholic/skills/branching/scripts/check.sh) — existing `{on_main, branch}` reporter; a pure reader that needs no change and is reused.
- [check-workspace.sh](plugins/workaholic/skills/branching/scripts/check-workspace.sh) — existing clean-tree reporter, reused by `sync-main.sh`.
- [create-mission-worktree.sh](plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh) — the reference for the worktree mechanics to copy: fetch-first (L84-95), base resolution to a SHA (L109-116), `git worktree add` (L122), git-excludes wiring via `lib/ensure-git-excludes.sh`. Do **not** extend this script — it stays the *claim* worktree creator.
- [cleanup-mission-worktree.sh](plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh) — the reference for a teardown that refuses a dirty worktree (L37-46).
- [commit.sh](plugins/workaholic/skills/commit/scripts/commit.sh) — the universal commit wrapper. **L130-135 rejects a detached HEAD**, which is the constraint that decides the publish tree's shape (see Implementation Steps).
- [commands/propose.md](plugins/workaholic/commands/propose.md) — step 1 performs the on-main/clean/fetch/ff-only guard with inline git in command markdown; `sync-main.sh` replaces it.
- [branching/SKILL.md](plugins/workaholic/skills/branching/SKILL.md) — where the publish-tree term and lifecycle are defined.
- [loop-engineering-workflow.md](docs/loop-engineering-workflow.md) — the lettered decision log; the new decision is recorded here.
- [test-workflow-scripts.mjs](scripts/test-workflow-scripts.mjs) — the hermetic suite; `makeClaimFixture` (~L7187) is the two-clone fixture pattern to reuse.

## Related History

The repository has already run this argument once and settled it on the executor side: the 2026-07-28 decision round introduced claims (G3) and ruled that worktrees are claim-born and ship-torn (I6), leaving creation-time branching as the surviving remnant of the pre-claim design. `/propose` then shipped as the working proof that a mission artifact needs no worktree at all.

- [20260129012614-auto-branch-on-ticket.md](.workaholic/tickets/archive/feat-20260128-220712/20260129012614-auto-branch-on-ticket.md) - Introduced `/ticket`'s auto-branch-when-on-main behaviour (the origin of what this change reverses)
- [20260714011846-mission-worktree-primitive.md](.workaholic/tickets/archive/work-20260714-000543/20260714011846-mission-worktree-primitive.md) - Defined `create-mission-worktree.sh` / `cleanup-mission-worktree.sh` and the worktree lifecycle I6 later replaced
- [20260714011847-mission-create-worktree-kickoff.md](.workaholic/tickets/archive/work-20260714-000543/20260714011847-mission-create-worktree-kickoff.md) - Made `/mission create` spin up a worktree; note it already superseded an earlier in-tree branch-on-create step, so this placement has been revised once before
- [20260728221802-add-claim-protocol-scripts.md](.workaholic/tickets/archive/work-20260728-221717/20260728221802-add-claim-protocol-scripts.md) - Built `claim.sh` / `list-claims.sh` / `lib/claims.sh`, the mechanism that already creates the branch and worktree at drive time
- [20260728210302-add-proposal-batch-command-and-skill.md](.workaholic/tickets/archive/work-20260728-210259/20260728210302-add-proposal-batch-command-and-skill.md) - The working precedent: scaffold a mission into the main checkout, commit, push, never prompt

## Implementation Steps

1. **Record the decision first.** Add a new lettered decision to [loop-engineering-workflow.md](docs/loop-engineering-workflow.md): artifact creation publishes to `main`; the executor's claim is the only creator of a branch or a worktree; the publish tree is the mechanism that decouples publication from the caller's checkout. Reference I6 as the decision this completes. Per `sacrificial-architecture`, the reason is recorded where a later reader will look for it, not only in `CLAUDE.md`.

2. **Add `skills/branching/scripts/sync-main.sh`.** Brings the *current* checkout's `main` up to date, emitting JSON and never prompting or merging:
   - `{"ok": true, "base": "origin/main", "sha": "<sha>", "advanced": <bool>}` on success.
   - `{"ok": false, "reason": "not_on_main" | "dirty_workspace" | "diverged" | "no_origin"}` otherwise.
   - Implemented by composing the existing `check.sh` and `check-workspace.sh` readers plus `git fetch origin main` and a fast-forward-only update. Never merges, never rebases, never stashes.
   - This is the script that replaces the inline git in `commands/propose.md` step 1 (step 7 below) and that `/drive` will call in a dependent ticket.

3. **Add `skills/branching/scripts/open-publish-tree.sh`.** Prepares a checkout of `origin/main` that is independent of the caller's working tree:
   - Requires an `origin` remote and **fails loudly** without one (`{"ok": false, "reason": "no_origin"}`). A publication nobody else can see is not a publication — this mirrors `claim.sh`'s writer-fails-loudly stance.
   - `git fetch origin main`, resolve `origin/main` to a SHA.
   - Materialise a worktree at a fixed, git-ignored path `<repo_root>/.publish/` on a fixed local branch **`publish-main`**, reset hard to the resolved SHA.
   - **The branch is named, not detached, and that is load-bearing**: `commit.sh` refuses a detached HEAD (L130-135), and the publish commit must go through `commit.sh` so it inherits the subject gate and the trailers. The name is deliberately *not* `work-*` — `work-*` means claim branch, `claims_scan` keys on it, and a publish tree must never be mistakable for a claim. The branch is local-only and is never pushed as a branch (see step 4).
   - Idempotent: an existing publish tree is reset to the new SHA rather than recreated. **Refuse when it holds uncommitted changes** (`{"ok": false, "reason": "dirty_publish_tree"}`) — a reset that silently discards a half-written artifact from an interrupted run is the failure this refusal exists to prevent.
   - Wire `.publish/` into the repo's git excludes through the existing `lib/ensure-git-excludes.sh` seam, exactly as `.worktrees/` is wired.
   - Emit `{"ok": true, "path": "<absolute path>", "branch": "publish-main", "base": "origin/main", "sha": "<sha>"}`.

4. **Add `skills/branching/scripts/publish-tree-commit.sh`.** Commits what the caller wrote into the publish tree and lands it on `main`:
   - Run `commit.sh` with the caller's structured arguments **inside the publish tree** (a `( cd <path> && … )` subshell, the same shape `/mission` uses today and which `guard-working-directory.sh` explicitly tolerates). The subject gate, staging semantics, and `Co-Authored-By` trailer are inherited unchanged.
   - Push with `git push origin publish-main:main` — the *commit* reaches `main`; the branch name never leaves the machine.
   - **Non-fast-forward handling**: another session or the cron loop may have pushed between the fetch and the push. On rejection, re-fetch, rebase the publish tree's commits onto the new `origin/main`, and retry **once**. If it still fails, report `{"ok": false, "reason": "diverged"}` and leave the commit intact in the publish tree so nothing is lost.
   - Emit `{"ok": true, "sha": "<pushed sha>", "retried": <bool>}` on success.

5. **Add `skills/branching/scripts/close-publish-tree.sh`.** Removes the publish worktree and deletes the local `publish-main` branch. Refuses a dirty tree (`{"ok": false, "reason": "dirty_publish_tree"}`) so an interrupted run's unpublished work is never destroyed by a bookkeeping call — the same stance `cleanup-mission-worktree.sh` takes. A publish tree left behind by a failed run is recoverable state, not garbage.

6. **Document the term in [branching/SKILL.md](plugins/workaholic/skills/branching/SKILL.md).** One section defining the publish tree, its lifecycle (`open → write → publish-tree-commit → close`), and the sentence that keeps the vocabulary honest: *a publish tree is not a claim worktree — it holds no unit, is never pushed as a branch, and is disposable at any moment.* Also state that `create.sh` and `create-mission-worktree.sh` remain the branch/worktree creators for **claims only**.

7. **Refactor `commands/propose.md` step 1 to call `sync-main.sh`.** This removes inline git from command markdown (a standing violation of the Shell Script Principle) and proves the new script against the one caller that already needs it. `/propose`'s observable behaviour — abort with `not_on_main` / `dirty_workspace` / `diverged`, never merge, never prompt — must be unchanged.

8. **Rebuild and re-verify the generated artifacts.** `branching` is a script-bearing skill inside the `outputs/workflows` closure, so run the argument-less `node scripts/build-plugins/build.mjs` and commit the result.

9. **Update the docs that describe the touched area in this same change** — [CLAUDE.md](CLAUDE.md) (the claim-protocol section's statement of who creates branches and worktrees) and [branching/SKILL.md](plugins/workaholic/skills/branching/SKILL.md). Doc updates for `/ticket`, `/mission`, and `/drive` belong to the tickets that change them.

## Quality Gate

**Acceptance criteria**

- `sync-main.sh` returns `ok: true` with `advanced: true` when the local `main` is behind `origin/main` and fast-forwards it; returns `ok: false` with the exact reason for each of `not_on_main`, `dirty_workspace`, `diverged`, `no_origin`, and mutates nothing in those cases.
- `open-publish-tree.sh` on a clone whose HEAD is a **dirty feature branch** produces a publish tree at `origin/main` and leaves `git status` in the caller's checkout byte-identical (same branch, same staged set, same untracked set, same file contents). This is the ticket's central invariant.
- A file written under `<publish>/.workaholic/…` and committed via `publish-tree-commit.sh` appears on `origin/main`, and appears **nowhere** in the caller's checkout until it fast-forwards.
- The publish commit's subject passes `skills/commit/scripts/check-subject.sh` and the commit carries the `Co-Authored-By` trailer — i.e. it demonstrably went through `commit.sh`, not a hand-rolled `git commit`.
- Concurrent-publish case: when `origin/main` advances between `open-publish-tree.sh` and `publish-tree-commit.sh`, the push succeeds via the single rebase-and-retry and reports `retried: true`; both commits are present on `origin/main` and neither is lost.
- Divergence that survives the retry reports `reason: "diverged"` and leaves the local commit intact and recoverable in the publish tree.
- `open-publish-tree.sh` against a publish tree holding uncommitted changes reports `dirty_publish_tree` and discards nothing; `close-publish-tree.sh` refuses the same case.
- `open-publish-tree.sh` is idempotent: two consecutive calls yield one worktree at the current `origin/main`, not two.
- `.publish/` is git-ignored — it never appears in `git status` of the primary tree.
- No `work-*` branch and no `.worktrees/` entry is created by any script in this ticket.
- Without an `origin` remote, `open-publish-tree.sh` fails loudly rather than writing locally.
- Every new script is POSIX `#!/bin/sh -eu` and passes `hooks/posix-lint.sh`.
- `commands/propose.md` contains no inline `git fetch` / conditional; `/propose`'s three abort reasons are unchanged.
- The new decision is recorded in `docs/loop-engineering-workflow.md`; `branching/SKILL.md` defines the publish tree and states it is not a claim worktree.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, extended with hermetic tests for each criterion above. The two-clone `makeClaimFixture` pattern (~L7187) is the model for the concurrent-publish and divergence cases: clone A opens a publish tree, clone B pushes to `origin/main`, clone A publishes.
- `bash plugins/workaholic/hooks/posix-lint.sh` conforming over the new scripts; the suite additionally runs under `dash` where available.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` all clean, with no uncommitted `outputs/` diff afterwards (the `Outputs Freshness` workflow fails on any).
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- A live rehearsal against a **throwaway clone** (never this repository itself — an unattended run must not push scratch commits to its `origin/main`): from a dirty feature branch, open a publish tree, write a scratch file, publish it, and confirm both that it reached `origin/main` and that the feature branch's diff is untouched — then revert the scratch commit.

**Gate**

- The full `## Local Verification` command set from [CLAUDE.md](CLAUDE.md) passes.
- The caller-checkout-untouched invariant is asserted by a named test, not only by the live rehearsal.
- The docs listed in the final implementation step tell the truth about the code as merged.

**Decided** (recorded rather than asked; override at review time):

- `Decided:` the publish tree is a **fixed path (`.publish/`) on a fixed local branch (`publish-main`)**, reset per open, rather than a per-invocation throwaway — one predictable location is inspectable and recoverable after a crash, and reset-per-open makes staleness impossible.
- `Decided:` the publish branch is **named `publish-main`, never `work-*`** — `work-*` is the claim vocabulary that `claims_scan` keys on, and an ambiguous name here would let a publish tree be misread as an in-flight claim.
- `Decided:` verification is the **hermetic suite plus one live rehearsal against a throwaway clone** — the change alters the cron loop's own plumbing, so proving it against a throwaway fixture alone would leave the real path untested; a rehearsal here is cheap because the repository is its own consumer.
- `Decided:` `create.sh` and `create-mission-worktree.sh` are **left unchanged** — they remain the claim-side creators; this ticket adds a parallel primitive rather than overloading the claim vocabulary.

## Considerations

- **A publish tree is not a claim worktree, and the docs must never blur them** (`plugins/workaholic/skills/branching/SKILL.md`). `.worktrees/<unit-id>/` is claim-born and ship-torn and holds a unit; `.publish/` holds nothing and is disposable. If the two ever share a directory or a branch prefix, `list-claims.sh` and `release-claim.sh` become ambiguous.
- **`check-worktrees.sh` will start reporting the publish tree** while it is open (`plugins/workaholic/skills/branching/scripts/check-worktrees.sh`). Its only consumer is `/ticket`'s Step 0 guard, which a dependent ticket removes; if any other consumer appears, the publish tree must be excluded from the count rather than the guard re-tuned.
- **The mission lens keys on worktree basename** (`plugins/workaholic/hooks/mission-lens.sh`). A session whose cwd is inside `.publish/` would be treated as "a worktree owning no mission" and surface nothing — correct by accident, but worth an explicit check, since publish trees are short-lived and no session should ever live in one.
- **`/fb` has the same latent invisibility** (`plugins/workaholic/commands/fb.md` step 4 commits without pushing, and never guards on `main`). A feedback recorded on a work branch never reaches `/propose`'s cursor, which reads records *merged to main*. This is deliberately **out of scope** — the request was tickets and missions — but the primitive built here is what a follow-up would use, and the gap should be raised rather than silently inherited.
- **Rebase-and-retry-once is a bounded answer to a rare race** (step 4). A busier repository may need a retry loop; a loop was not chosen now because an unbounded retry hides sustained divergence that a human should see. If `diverged` starts appearing in practice, revisit the bound rather than raising it blindly.
