---
created_at: 2026-07-14T01:18:46+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 1h
commit_hash: 575f3a4
category: Changed
depends_on: [20260714011846-mission-worktree-primitive.md]
mission:
---

# /mission close Removes the Mission's Persistent Worktree

## Overview

`/mission close <slug>` is the point where a mission ends — and, under the persistent-worktree model, the only sanctioned point that removes the mission's worktree. Add the teardown: when a mission is closed (achieved or abandoned), after the existing close (flip `status`, closing changelog line, move the mission dir to `archive/`), **remove its `.worktrees/<slug>/` worktree** via the foundation primitive `branching/scripts/cleanup-mission-worktree.sh "<slug>"`.

Because a mission worktree persists across many branches (each merged and re-cut from `main` by `/ship`), `close` is the natural and only place it should be torn down. The teardown is best-effort and non-destructive: it removes only a **clean, registered** worktree and prunes it; if the worktree has uncommitted work or is missing, it reports that and does not force-remove (the mission still closes). This teardown orchestration lives in `commands/mission.md`'s close path (Claude-only), not in the built `mission/scripts/close.sh`, to keep the `mission` skill portable — `close.sh` continues to own only the status/changelog/archive mutation.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — reuse `cleanup-mission-worktree.sh` via `${CLAUDE_PLUGIN_ROOT}`; the teardown is command-level orchestration, no hand-rolled `git worktree`. Applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` for any shell; no inline conditionals in the command. Applies to all code work.
- `workaholic:operation` / `policies/recovery.md` — teardown is best-effort and never discards uncommitted work; a missing/dirty worktree does not block the mission close (graceful, recoverable).

## Key Files

- `plugins/workaholic/commands/mission.md` - The "## `close <slug>` — end a mission" section gains the worktree-teardown step **after** `close.sh` succeeds; scoped to close only. Claude-only → no rebuild.
- `plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh` - The foundation primitive (from the depended-on ticket) that removes `.worktrees/<slug>/`.
- `plugins/workaholic/skills/mission/scripts/close.sh` - **Unchanged** — keeps owning status/changelog/archive only, so the built `mission` skill needs no rebuild and stays portable.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` - Note that closing a mission also tears down its worktree, in the same commit.

## Related History

`close.sh` is the single sanctioned way to end a mission (flip status, closing changelog, move to `archive/`). This ticket adds the worktree teardown as a command-level step around it, mirroring how the create ticket keeps worktree orchestration in the command rather than the built script.

Past tickets that touched similar areas:

- [20260714011846-mission-worktree-primitive.md](.workaholic/tickets/todo/a-qmu-jp/20260714011846-mission-worktree-primitive.md) - Supplies `cleanup-mission-worktree.sh` this ticket depends on.
- [20260714011847-mission-create-worktree-kickoff.md](.workaholic/tickets/todo/a-qmu-jp/20260714011847-mission-create-worktree-kickoff.md) - Creates the persistent worktree this close tears down.

## Implementation Steps

1. In `commands/mission.md`'s close path, after a successful `close.sh` (`closed: true`), run `cleanup-mission-worktree.sh "<slug>"` and report its status alongside the archived path.
2. On `close.sh` reporting `already_closed`/`not_found`, do **not** attempt teardown (nothing to end). On teardown failure (dirty/missing worktree), report it but treat the mission as closed.
3. Leave `close.sh` and the list/create/summary paths untouched.
4. Update docs. Run `build.mjs` (expect **no** `outputs/` diff — only the command changed), `verify.mjs`, `posix-lint`, `test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Given an active mission with a `.worktrees/<slug>/` worktree, running the close orchestration (`close.sh <slug> achieved` then `cleanup-mission-worktree.sh <slug>`) flips the mission to `achieved`, moves it to `archive/`, **and** removes the `.worktrees/<slug>/` worktree (no longer registered).
- If the worktree is already gone, close still succeeds and the teardown is a reported no-op (idempotent).
- The teardown never removes a worktree with uncommitted changes; in that case the mission still closes and the dirty worktree is reported, not force-removed.
- `close.sh` and `mission/scripts/` are unchanged, so `build.mjs` yields no `outputs/` diff.

**Verification method** — the commands/tests/probes that prove them:

- A new `node scripts/test-workflow-scripts.mjs` case seeds a temp repo with an active mission + its `.worktrees/<slug>/` worktree, runs `close.sh` then `cleanup-mission-worktree.sh`, and asserts: status `achieved` in `archive/`, worktree removed, and a re-run is a no-op. A dirty-worktree variant asserts close-succeeds-without-force-remove. Non-interactive, no network.
- `node scripts/build-plugins/build.mjs` no `outputs/` diff; `verify.mjs` + `validate-metadata.mjs` + `posix-lint` pass.

**Gate** — what must pass before approval:

- Full local suite green (`test-workflow-scripts.mjs`, `build.mjs` no `outputs/` diff, `verify.mjs`/`validate-metadata.mjs`/`posix-lint`).
- The close-removes-worktree and idempotent/dirty-safe behaviors are demonstrated in-session (hermetic test counts).
- Docs updated.

## Considerations

- Order matters: tear down the worktree **after** the mission is safely archived, so a teardown failure never leaves a half-closed mission (`plugins/workaholic/commands/mission.md`).
- Do not force-remove: a dirty mission worktree at close time signals unshipped work; report it and let the developer decide, rather than discarding it (`plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh`).
- Keep the teardown in the command, not `close.sh`, so the built `mission` skill stays worktree-free and portable (`plugins/workaholic/skills/mission/scripts/close.sh`).

## Final Report

Development completed as planned. `commands/mission.md`'s close path now runs `cleanup-mission-worktree.sh "<slug>"` after a successful `close.sh`, scoped to `closed: true` only. `close.sh` is unchanged (built `mission` skill untouched → no `outputs/` diff). Hermetic test proves close archives the mission and the teardown removes its worktree, is idempotent when already gone, and — with a dirty worktree — the mission still closes while the teardown refuses to discard the unshipped work; 496 passed / 0 failed, build/verify/posix-lint clean.
