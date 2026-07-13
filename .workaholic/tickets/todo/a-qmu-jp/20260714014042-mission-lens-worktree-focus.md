---
created_at: 2026-07-14T01:40:42+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
depends_on: [20260714011846-mission-worktree-primitive.md, 20260714011847-mission-create-worktree-kickoff.md]
mission:
---

# Mission Lens Focuses on the Current Worktree's Mission

## Overview

Make `hooks/mission-lens.sh` **worktree-aware**. Once each mission has its own dedicated worktree (`.worktrees/<mission-slug>/`, from the mission-worktree feature), the lens should stop reminding you about missions that **other worktrees** own — inside a mission's worktree you are already focused on that mission, so surfacing the rest is pure noise (observed: the lens currently lists every active mission assigned to you, including ones that belong to other worktrees).

New scoping rule (still gated on `assignee == git config user.email`, as today):

- **Inside a mission worktree** (`git rev-parse --show-toplevel` resolves to `…/.worktrees/<slug>` whose `<slug>` is an active mission): surface **only that one mission**.
- **In the main tree (or a non-mission worktree)**: surface only missions that do **not** have a dedicated worktree (a mission whose `.worktrees/<slug>` is a registered worktree is "owned" by that worktree and stays silent everywhere else). Missions with no worktree keep showing as today.

This applies to both events the lens fires on (`UserPromptSubmit` model context, `Stop` user nudge) — the scoping is computed once and used for both.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the change stays inside `hooks/mission-lens.sh` and reuses the mission/branching conventions; no new script. Applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`, no bashisms (the hook already is); machine-checked by `posix-lint.sh`. Applies to all code work.
- `workaholic:design` / `policies/modeless-design.md` — the lens is an orientation aid, not a nag; scoping it to the current worktree's mission keeps it low-noise and relevant, never hijacking the turn.

## Key Files

- `plugins/workaholic/hooks/mission-lens.sh` - The hook: add current-worktree detection (`git rev-parse --show-toplevel` → is it `…/.worktrees/<slug>`?) and the "mission owns a worktree" check (`git worktree list` contains `.worktrees/<slug>`); apply the scoping rule before printing. Claude-Code-only, no `outputs/` footprint (lives in `hooks/`, not built) → no rebuild.
- `plugins/workaholic/skills/mission/scripts/progress.sh`, `next-acceptance.sh` - Still used to render each surfaced mission's `checked/total` + next item (unchanged; reuse).
- `plugins/workaholic/skills/branching/scripts/list-all-worktrees.sh` - Reference for reading `git worktree list`; the hook can read it directly or reuse the same detection.
- `CLAUDE.md` - The "Always-on mission lens" section describes the assignee gate; extend it to state the new worktree-focus scoping (same commit).
- `scripts/test-workflow-scripts.mjs` - Hermetic test for the scoping (see Quality Gate).

## Related History

The mission lens was built to surface active missions assigned to the current `git config user.email` on `UserPromptSubmit` (model context) and `Stop` (user nudge). The mission-worktree feature (dependency tickets) gives each mission its own worktree, which makes per-worktree focus both possible and desirable.

Past tickets that touched similar areas:

- [20260714011847-mission-create-worktree-kickoff.md](.workaholic/tickets/todo/a-qmu-jp/20260714011847-mission-create-worktree-kickoff.md) - Establishes the `.worktrees/<slug>` ↔ mission mapping this scoping keys on.
- [20260714000528-command-summary-mode.md](.workaholic/tickets/archive/work-20260714-000543/20260714000528-command-summary-mode.md) - Recent per-user mission scoping via `assignee`/`git user.email` (same identity gate reused here).

## Implementation Steps

1. In `mission-lens.sh`, resolve the current worktree root (`git rev-parse --show-toplevel`); if it is `…/.worktrees/<slug>` and `<slug>` is an active mission, set `current_mission=<slug>`.
2. Read registered worktrees (`git worktree list --porcelain` or `list-all-worktrees.sh`) once; build the set of slugs that own a `.worktrees/<slug>` worktree.
3. When iterating active missions assigned to the current user, apply the scoping rule: in a mission worktree show only `current_mission`; otherwise show only missions whose slug is **not** in the worktree-owned set.
4. Keep the `assignee == git user.email` gate and the `progress.sh`/`next-acceptance.sh` rendering unchanged.
5. Update the CLAUDE.md "Always-on mission lens" section. Run `posix-lint`, `test-workflow-scripts.mjs`, `build.mjs` (expect **no** `outputs/` diff — hooks are not built).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- In a repo with three active missions assigned to the current user — `alpha` (has `.worktrees/alpha`), `beta` (has `.worktrees/beta`), `gamma` (no worktree) — running the lens **from inside `.worktrees/alpha`** surfaces **only `alpha`**.
- Running the lens **from the main tree** surfaces **only `gamma`** (both `alpha` and `beta` are worktree-owned and stay silent).
- Missions assigned to another email are never surfaced (existing gate intact).
- `mission-lens.sh` stays POSIX-conforming; `build.mjs` yields no `outputs/` diff.

**Verification method** — the commands/tests/probes that prove them:

- A new `node scripts/test-workflow-scripts.mjs` case seeds a temp repo with the three missions and registers `.worktrees/alpha` + `.worktrees/beta` worktrees, then invokes `mission-lens.sh` (feeding the `Stop`/`UserPromptSubmit` event JSON on stdin) once with CWD in `.worktrees/alpha` and once in the main tree, asserting the surfaced-mission set each time. No network.
- `sh plugins/workaholic/hooks/posix-lint.sh` conforming; `node scripts/build-plugins/build.mjs` no `outputs/` diff.

**Gate** — what must pass before approval:

- Full local suite green (`test-workflow-scripts.mjs` incl. the new case, `posix-lint`, `build.mjs` no diff, `verify.mjs`/`validate-metadata.mjs`).
- The worktree-focus and main-tree behaviors are demonstrated in-session (hermetic test counts).

## Considerations

- Do not weaken the identity gate: scoping is **additional** to `assignee == git user.email`, never a replacement (`plugins/workaholic/hooks/mission-lens.sh`).
- Detection must be cheap — the lens runs on every turn/stop; read `git worktree list` once and avoid per-mission subprocess storms (`plugins/workaholic/hooks/mission-lens.sh`).
- A mission whose worktree was removed (post-close) correctly falls back to "no worktree → shows in main tree" until the mission itself is closed; ensure the fallback is graceful (`plugins/workaholic/skills/branching/scripts/list-all-worktrees.sh`).
