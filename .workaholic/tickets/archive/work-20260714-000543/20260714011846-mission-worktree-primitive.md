---
created_at: 2026-07-14T01:18:46+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
commit_hash: 58844ad
category: Added
depends_on:
mission:
---

# Mission-Keyed Persistent Worktree Primitive

## Overview

Add the worktree primitive that the new mission flow builds on: a **mission-named, long-lived** worktree under `.worktrees/<mission-slug>/`, holding an ordinary `work-YYYYMMDD-HHMMSS` branch inside. This is the foundation ticket — `/mission` create, `/ship`, and `/mission close` (the three dependent tickets) all compose these scripts.

The developer's lifecycle model (confirmed): **the worktree is scoped to the mission and persists until the mission ends**; the *branch* inside it is disposable — cut from `main`, driven, merged, then a fresh `main`-based branch is checked out into the **same** worktree, repeated. So the directory is keyed by the mission slug (not the branch), which the existing `.worktrees/<branch>` toolkit does not support.

New scripts (in the `branching` skill — **not** a build target, so no `outputs/` rebuild; and worktree logic must stay out of the built, cross-agent `mission` skill for portability):

- `branching/scripts/create-mission-worktree.sh "<slug>" [base-branch]` — mint a `work-YYYYMMDD-HHMMSS` branch off `base-branch` (default the repo's base branch, normally `main`) and `git worktree add` it at `.worktrees/<slug>/`, copying the root `.env` in (as `ensure-worktree.sh` does). Emits `{worktree_path, branch, slug}`. The slug is validated (`^[a-z0-9][a-z0-9-]*$`), the branch stays policy-conformant (so `guard-git-branch.sh` and `create.sh`'s naming rule are honored), and the path is keyed by the **slug**.
- `branching/scripts/cleanup-mission-worktree.sh "<slug>"` — `git worktree remove` the `.worktrees/<slug>/` worktree, prune, and delete its current branch. Emits a status JSON. Used by `/mission close`.

`list-all-worktrees.sh` / `list-worktrees.sh` should recognize a `.worktrees/<slug>` dir (non-`work-*` name) as a **mission** worktree in their type detection, so downstream (`/ship`, `/drive` routing) can tell a mission worktree from an ordinary drive/trip one.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the primitive lives in the conventional `skills/branching/scripts/` location, referenced via `${CLAUDE_PLUGIN_ROOT}`; `.worktrees/` is the already-sanctioned parallel-work layout. Applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — new scripts are POSIX `#!/bin/sh -eu`, no bashisms, machine-checked by `posix-lint.sh` and the dash smoke tests. Applies to all code work.
- `workaholic:operation` / `policies/recovery.md` — worktree create/remove must be recoverable and idempotent-friendly (never destroy uncommitted work; `git worktree remove` only a clean, registered worktree), consistent with the existing `cleanup-worktree.sh` posture.

## Key Files

- `plugins/workaholic/skills/branching/scripts/ensure-worktree.sh` - The existing branch-keyed one-shot (`git worktree add -b <branch> .worktrees/<branch> HEAD` + copy `.env`); model `create-mission-worktree.sh` on it but key the path by the slug and the branch by a freshly minted `work-*` name, and base off `main` (not `HEAD`).
- `plugins/workaholic/skills/branching/scripts/create.sh` - The sole `work-YYYYMMDD-HHMMSS` namer; reuse its naming rule (or call it) so the branch name stays gate-conformant. Note it does `git checkout -b` in the current tree, so the worktree script must instead `git worktree add -b` — do not chain the two blindly.
- `plugins/workaholic/skills/branching/scripts/cleanup-worktree.sh` - The branch-keyed cleanup precedent (`git worktree remove` + prune + delete branch); `cleanup-mission-worktree.sh` mirrors it but resolves the path from the **slug**.
- `plugins/workaholic/skills/branching/scripts/list-all-worktrees.sh`, `list-worktrees.sh` - Add mission-worktree type detection (dir name is a slug, not `work-*`).
- `plugins/workaholic/skills/branching/SKILL.md` - Document the two new scripts and the mission-worktree convention (`.worktrees/<slug>`, work-* branch inside, persists until mission close). branching is not built → no rebuild.
- `scripts/test-workflow-scripts.mjs` - Hermetic worktree scenario test (see Quality Gate).

## Related History

The `.worktrees/` layout and the worktree toolkit already exist for `/trip` and `/drive` (`ensure-worktree.sh`, `adopt-worktree.sh`, `cleanup-worktree.sh`, all keyed by the `work-*` branch name); the root-`.env` copy convention was set by an earlier ticket. This foundation ticket generalizes that toolkit from branch-keyed to **slug-keyed** for the mission use case, without changing the existing branch-keyed scripts.

Past tickets that touched similar areas:

- [20260713144839-worktree-copies-root-env.md](.workaholic/tickets/archive/work-20260713-144839/20260713144839-worktree-copies-root-env.md) - Established `.worktrees/` as the parallel-work layout and `ensure-worktree.sh` as the creation protocol (same toolkit).
- [20260714001859-mission-branch-on-create.md](.workaholic/tickets/archive/work-20260714-000543/20260714001859-mission-branch-on-create.md) - The in-tree branch-on-create step this worktree model supersedes (context for the dependent create ticket).

## Implementation Steps

1. Add `branching/scripts/create-mission-worktree.sh` (POSIX): validate the `<slug>` argument; resolve the base branch (default via the gather/branching context, normally `main`); mint a `work-YYYYMMDD-HHMMSS` branch name (reuse `create.sh`'s naming rule — extract a tiny shared namer if needed, or call it in a way that does not move the current tree's HEAD); run `git worktree add -b <branch> .worktrees/<slug> <base>`; copy the root `.env` into the worktree if present; emit `{worktree_path, branch, slug}`.
2. Add `branching/scripts/cleanup-mission-worktree.sh` (POSIX): resolve `.worktrees/<slug>`; if registered, `git worktree remove` it (refuse on a dirty worktree unless forced consistently with `cleanup-worktree.sh`), `git worktree prune`, delete the branch; emit a status JSON. Idempotent when the worktree is already gone.
3. Teach `list-all-worktrees.sh` / `list-worktrees.sh` to tag a `.worktrees/<slug>` dir as a mission worktree (type field), leaving `work-*`/`trip-*` detection intact.
4. Document both scripts and the `.worktrees/<slug>` convention in `branching/SKILL.md`.
5. Add the hermetic scenario test (see Quality Gate). Run `posix-lint`, `build.mjs` (expect **no** `outputs/` diff — branching is not built), `verify.mjs`, `test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- In a throwaway repo, `create-mission-worktree.sh "demo-mission"` creates `.worktrees/demo-mission/` as a registered git worktree whose checked-out branch matches `^work-\d{8}-\d{6}$`, based off `main` (the branch's merge-base is `main`'s tip), with the root `.env` copied in when present.
- The main working tree is unaffected: its HEAD/branch is unchanged and `git status` stays clean (the new worktree does not show as untracked).
- `cleanup-mission-worktree.sh "demo-mission"` removes the worktree and its branch; re-running it is a no-op (idempotent), and it never removes a worktree with uncommitted changes.
- `list-all-worktrees.sh` reports the `.worktrees/demo-mission` entry tagged as a mission worktree.
- Every new script passes `posix-lint`; `build.mjs` yields no `outputs/` diff (branching is not a build target).

**Verification method** — the commands/tests/probes that prove them:

- A new case in `node scripts/test-workflow-scripts.mjs` seeds a temp repo, runs `create-mission-worktree.sh`, asserts the worktree path/branch-name pattern/base/main-tree-untouched, then `cleanup-mission-worktree.sh` and asserts removal + idempotency. It never touches the working tree or the network.
- `sh plugins/workaholic/hooks/posix-lint.sh` reports conforming; `node scripts/build-plugins/build.mjs` produces no `outputs/` diff; `node scripts/build-plugins/verify.mjs` + `validate-metadata.mjs` pass.

**Gate** — what must pass before approval:

- Full local suite green: `test-workflow-scripts.mjs` (new assertions included), `build.mjs` no `outputs/` diff, `verify.mjs` + `validate-metadata.mjs` + `posix-lint` clean.
- The create/cleanup round-trip and main-tree isolation are demonstrated in-session (the hermetic test run counts).

## Considerations

- Branch-name invariant: the worktree's branch MUST be `work-YYYYMMDD-HHMMSS` (triple-enforced by `guard-git-branch.sh`, `create.sh`, and `ensure-worktree.sh`'s own regex). Only the *directory* is mission-named; never name a branch after the mission (`plugins/workaholic/skills/branching/scripts/create.sh`).
- Path-vs-branch split: the rest of the toolkit derives the worktree path from the branch; `cleanup-mission-worktree.sh` instead derives it from the slug. Keep the two cleanup scripts distinct so branch-keyed drive/trip cleanup is untouched (`plugins/workaholic/skills/branching/scripts/cleanup-worktree.sh`).
- A worktree branches from a committed base — `git worktree add -b … main` takes `main`'s tip; uncommitted changes in the main tree stay there. Base off `main` for a clean start (`plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh`).
- Keep worktree logic in `branching` (not built), never in the built `mission` skill, to preserve cross-agent portability of `outputs/workflows` (`plugins/workaholic/skills/mission/SKILL.md`).

## Final Report

Development completed as planned. Added `create-mission-worktree.sh` (mission-slug dir, work-* branch off main, `.env` copied) and `cleanup-mission-worktree.sh` (refuses dirty worktrees, idempotent), added `type: "mission"` detection to `list-all-worktrees.sh`, documented the convention in `branching/SKILL.md`, and covered it with a hermetic create/cleanup/type/dirty-refusal test (466 passed, 0 failed).

### Discovered Insights

- **Insight**: `list-all-worktrees.sh` had a latent bug — it dropped the **last** worktree. `$(git worktree list … )` strips trailing newlines, and the loop flushed a record only on a blank line, so the final entry never flushed. The new hermetic test exposed it; fixed by terminating the heredoc with an explicit blank line.
  **Context**: The script had no hermetic test before this ticket, so the drop went unnoticed (the primary/main tree is first in porcelain output, so the *missing* one was always a real worktree). Any consumer of `list-all-worktrees.sh` was silently missing its last worktree until now.
- **Insight**: `branching` is not a build *target* but it **is** in the build *closure* of `create-ticket`/`drive`/`report`/`ship`, so editing any `branching/scripts/*.sh` DOES require `node scripts/build-plugins/build.mjs` and commits an `outputs/` diff (the whole `branching/scripts/` dir is copied into each built skill). The ticket's "no rebuild" assumption was wrong; a rebuild is required for any branching-script change.
  **Context**: `computeClosure` copies a closure skill's entire `scripts/` dir, so a new/edited branching script propagates to `outputs/workflows/skills/{create-ticket,drive,report,ship}/branching/scripts/`.
