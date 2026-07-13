---
created_at: 2026-07-14T01:18:46+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
commit_hash: dfd9b1e
category: Changed
depends_on: [20260714011846-mission-worktree-primitive.md]
mission:
---

# /ship Preserves a Mission Worktree and Re-Branches from Main

## Overview

Make `/ship` treat a **mission worktree** differently from an ordinary drive/trip worktree. Today `/ship`'s worktree cleanup deletes the worktree after the PR merges (`cleanup-worktree.sh`). Under the persistent-mission model that is wrong: the mission's worktree must **survive** the merge and be reused for the mission's next batch.

New `/ship` behavior when the shipped branch lives in a `.worktrees/<slug>/` **mission** worktree (dir name is a mission slug, not `work-*` — detected via `list-all-worktrees.sh`'s type tag from the foundation ticket):

1. Merge and deploy exactly as today (unchanged).
2. **Do not delete** the worktree. Instead, in that worktree, check out `main`, fast-forward it to the just-merged tip, and cut a **fresh `work-YYYYMMDD-HHMMSS` branch** off `main` so the worktree is immediately ready for the next drive.
3. Keep the gitignored-file sync step as today, but end with the worktree **retained** (not removed).

Ordinary (non-mission) `work-*`/`trip-*` worktrees keep the existing merge-then-cleanup behavior — this change is scoped to mission worktrees only. The mission worktree is removed only by `/mission close` (separate ticket).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — reuse the `branching` worktree scripts and `ship` scripts via `${CLAUDE_PLUGIN_ROOT}`; the mission-vs-ordinary branch is a small orchestration decision, extracted to a script, not inline shell. Applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`, no bashisms; the re-branch step reuses `create.sh`'s naming rule so the new branch is gate-conformant. Applies to all code work.
- `workaholic:operation` / `policies/ci-cd.md` — the ship/merge/deploy path is unchanged; only the post-merge worktree disposition changes, and it must leave a clean, drive-ready worktree without discarding uncommitted work.

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` - The worktree-cleanup step of the ship flow; add the mission-worktree branch: detect a mission worktree and re-branch instead of cleaning up. ship is built → **rebuild required** if the SKILL.md or its scripts change.
- `plugins/workaholic/skills/ship/scripts/` - Where a small `reset-mission-worktree.sh` (checkout main, ff, cut fresh `work-*`) or an extension to the existing cleanup routing would live; reuse `branching/create.sh`'s naming.
- `plugins/workaholic/skills/branching/scripts/cleanup-worktree.sh` - The existing delete-on-merge path that must be **bypassed** for mission worktrees (keep it for ordinary ones).
- `plugins/workaholic/skills/branching/scripts/list-all-worktrees.sh` - Source of the mission-worktree type tag (from the foundation ticket) the ship flow keys on.
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - `/ship`'s trip-worktree sync+cleanup lives adjacent; ensure the mission-worktree branch does not disturb trip cleanup.
- `CLAUDE.md`, `README.md` - Update the `/ship` behavior note (mission worktrees are preserved and re-branched, not deleted) in the same commit.

## Related History

`/ship`'s worktree cleanup (sync gitignored files out, then `cleanup-worktree.sh <branch>`) was built for the ephemeral `/trip` worktree. The persistent-mission model (from the create ticket) requires the opposite disposition for mission worktrees. This ticket adds the fork; it does not change trip/drive worktree cleanup.

Past tickets that touched similar areas:

- [20260714011846-mission-worktree-primitive.md](.workaholic/tickets/todo/a-qmu-jp/20260714011846-mission-worktree-primitive.md) - Supplies the mission-worktree convention + type detection this ticket depends on.
- [20260714011847-mission-create-worktree-kickoff.md](.workaholic/tickets/todo/a-qmu-jp/20260714011847-mission-create-worktree-kickoff.md) - Creates the persistent worktree this ship behavior preserves.

## Implementation Steps

1. In the ship worktree step, detect whether the shipped branch's worktree is a mission worktree (dir under `.worktrees/` whose name is a slug, via `list-all-worktrees.sh`'s type tag).
2. For a mission worktree: after merge + the gitignored-file sync, run a `reset-mission-worktree.sh` that, inside the worktree, checks out `main`, fast-forwards to the merged tip, and cuts a fresh `work-YYYYMMDD-HHMMSS` branch (reuse `create.sh` naming) — leaving the worktree retained and drive-ready. Skip `cleanup-worktree.sh`.
3. For an ordinary worktree: unchanged (existing merge-then-cleanup).
4. Update docs. Rebuild (`build.mjs`) since `ship` is a built target; run `verify.mjs`, `validate-metadata.mjs`, `posix-lint`, `test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Given a `.worktrees/<slug>/` mission worktree on a `work-*` branch that is "merged" (simulated), the ship worktree step leaves the worktree **present** and registered, with `main` checked out and fast-forwarded and a **new** `work-YYYYMMDD-HHMMSS` branch cut off `main` (drive-ready).
- Given an ordinary `work-*`/`trip-*` worktree, the existing cleanup behavior is unchanged (the worktree is removed as today).
- No uncommitted work is discarded; the re-branch never runs destructive git.
- `ship` build target rebuilt (`outputs/` diff committed); `verify.mjs`/`posix-lint` clean.

**Verification method** — the commands/tests/probes that prove them:

- A new `node scripts/test-workflow-scripts.mjs` case builds a temp repo with a mission worktree, simulates the merge, runs the mission-worktree reset routine, and asserts the worktree persists with `main` + a fresh `work-*` branch; a companion assertion confirms an ordinary worktree still gets cleaned up. Non-interactive, no network/`gh`.
- `node scripts/build-plugins/build.mjs` (ship rebuild) + `verify.mjs` + `validate-metadata.mjs` + `posix-lint` pass.

**Gate** — what must pass before approval:

- Full local suite green (`test-workflow-scripts.mjs`, `build.mjs` outputs committed, `verify.mjs`/`validate-metadata.mjs`/`posix-lint`).
- The mission-worktree-preserved-and-re-branched vs ordinary-worktree-cleaned-up behaviors are demonstrated in-session (hermetic test counts).
- Docs updated.

## Considerations

- Detection must be robust: distinguishing a mission worktree from a drive/trip one relies on the `.worktrees/<slug>` naming and the foundation ticket's type tag — do not misclassify a legitimately `work-*`-named worktree as a mission one (`plugins/workaholic/skills/branching/scripts/list-all-worktrees.sh`).
- Re-branch safety: only re-branch a **clean** worktree; if the merged worktree still has uncommitted work, surface it rather than force-switching (`ship` flow).
- `/ship` deploy/verify/merge ordering is unchanged — this only alters the post-merge worktree disposition; do not reorder the ship gates (`plugins/workaholic/skills/ship/SKILL.md`).
- ship is a built, cross-agent skill; keep worktree specifics minimal there and lean on `branching` scripts so portability is preserved (`plugins/workaholic/skills/ship/SKILL.md`).

## Final Report

Development completed as planned. Added `branching/scripts/reset-mission-worktree.sh` (cuts a fresh `work-*` branch off `main` inside the same worktree, refuses dirty) and taught trip-protocol's ship-flow cleanup step to **reset** a mission worktree instead of deleting it (ordinary `work-*` worktrees still get `cleanup-worktree.sh`). Hermetic test proves the mission worktree survives a simulated merge, gets a fresh main-based branch, and an ordinary worktree still cleans up; 487 passed / 0 failed, build/verify/metadata/posix-lint clean.

### Discovered Insights

- **Insight**: `.worktrees/` is **NOT** auto-ignored by git — `git status` shows `?? .worktrees/` and `git add -A` in the main tree **embeds** `.worktrees/<slug>` as a gitlink ("adding embedded git repository"). The earlier "no gitignore needed" assumption was wrong. Fixed by having `create-mission-worktree.sh` add `.worktrees/` to `.git/info/exclude` (repo-local, shared across worktrees, untracked — no commit side-effect).
  **Context**: Any main-tree `git add -A` (drive `archive.sh`, sweeps) while a worktree exists would otherwise corrupt a commit with a stray gitlink. **The pre-existing `ensure-worktree.sh` (trip/drive worktrees) has the same latent embedding risk and does NOT add the exclude — a follow-up should apply the same `.git/info/exclude` guard there.**
- **Insight**: `git checkout -b <new> main` works inside a worktree even though `main` is checked out in the primary tree, because the base is used only as a start-point (not checked out). This is what lets the reset renew the branch without a "main already checked out" conflict.
