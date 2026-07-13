---
created_at: 2026-07-14T00:18:59+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# Start a Topic Branch on `/mission` Create, Like `/ticket`

## Overview

When `/mission "<title>"` creates a new mission, first start a topic branch **when on main** — exactly the way `/ticket` does before writing a ticket. Today `/mission` create writes the mission file with no branch handling, so a mission created from `main` lands on `main`.

Scope (decided with the developer):

- **Only the create path branches.** `/mission "<title>"` (create) gains the branch-if-on-main step. Bare `/mission` (list) and `/mission close <slug>` are **unchanged** — they never branch.
- **Branch-if-on-main only, no worktree guard.** This mirrors `/ticket`'s Step 1 branch step but **not** its Step 0 worktree guard — `/mission` gets no new `AskUserQuestion` prompt.
- **Reuse the existing primitive verbatim.** Run `branching/scripts/check.sh`; if `on_main` is true, create the branch **only** via `branching/scripts/create.sh` (the sole `work-YYYYMMDD-HHMMSS` creator). On a topic/work branch already, skip and create the mission on the current branch. A mission branch is an ordinary `work-*` branch — the mission `<slug>` has no bearing on the branch name.
- **Placement: the thin command.** The step goes in `commands/mission.md`'s create section, **before** the `create.sh` call — main-agent orchestration reusing the branching scripts, no new shell logic and no change to `create.sh` itself. This keeps the change command-only (Claude-only, not built → no `outputs/` rebuild), consistent with how `/ticket` orchestrates its branch step ahead of the ticket-writing skill.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the branch step reuses the existing `skills/branching/` primitives referenced via `${CLAUDE_PLUGIN_ROOT}`; no new script, conventional layout preserved. Applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — no inline git/conditional logic is added; the branch decision stays encapsulated in the pre-existing POSIX `check.sh`/`create.sh` scripts. Applies to all code work.

## Key Files

- `plugins/workaholic/commands/mission.md` - The create section ("## With a title — create a mission") gains the branch-if-on-main step **before** the `create.sh` call; list and close sections stay untouched. Its `skills:` frontmatter must add `workaholic:branching` (currently only `workaholic:mission` + `workaholic:gather`) so the scripts resolve at load time. Claude-only → no rebuild.
- `plugins/workaholic/skills/branching/scripts/check.sh` - Reused as-is: emits `{on_main, branch}`; gate the branch creation on `on_main`.
- `plugins/workaholic/skills/branching/scripts/create.sh` - Reused as-is: the sole `work-YYYYMMDD-HHMMSS` creator (`git checkout -b`); caller-agnostic naming, no mission-specific concern.
- `plugins/workaholic/skills/create-ticket/SKILL.md` - Reference for the exact two-script recipe (Step 1): the shape to copy into the mission create path.
- `plugins/workaholic/skills/mission/scripts/create.sh` - **Unchanged.** It only ever `git add`s, never branches; keeping the branch step at the command layer means this built script (and the rebuild it would trigger) is untouched.
- `plugins/workaholic/skills/mission/SKILL.md` - Documents the create flow. **If** a note about command-level branching is added here it is a built target and requires `node scripts/build-plugins/build.mjs`; the preferred minimal change keeps the branch note in the command + top-level docs and leaves this file (and its accurate `create.sh` description) alone.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` - The `/mission` behavior rows note that create now starts a topic branch on main, in the same commit (doc-update rule).

## Related History

`/ticket` already implements this exact step: `commands/ticket.md` Step 1 delegates to `create-ticket` SKILL.md Step 1, which runs `branching/scripts/check.sh` and — when `on_main` — `branching/scripts/create.sh`. Git history shows no prior mission branch handling; `mission/scripts/create.sh` has never touched branches. This is an unclaimed, straightforward parity enhancement, orthogonal to the just-created command summary-mode ticket (which only adds read-only dispatch and does not alter mission creation).

Past tickets that touched similar areas:

- [20260714000528-command-summary-mode.md](.workaholic/tickets/todo/a-qmu-jp/20260714000528-command-summary-mode.md) - Adds `summary` dispatch to /ticket,/trip,/mission; adjacent (same commands) but a distinct, non-create concern.
- [20260122150455-ticket-update-first-guidance.md](.workaholic/tickets/archive/main/20260122150455-ticket-update-first-guidance.md) - Changed command dispatch behavior (same layer: Infrastructure).

## Implementation Steps

1. Add `workaholic:branching` to `commands/mission.md`'s `skills:` frontmatter.
2. In the "## With a title — create a mission" section, **before** the existing `create.sh "$ARGUMENT"` call, add the branch step: run `branching/scripts/check.sh`; when `on_main` is true, run `branching/scripts/create.sh` and note the returned branch. On a work branch, skip. Mirror `create-ticket` Step 1 wording. Leave the list and close sections exactly as they are.
3. Do **not** modify `mission/scripts/create.sh` — the branch orchestration stays at the command layer, so no `outputs/` rebuild is triggered by this change.
4. Add the hermetic scenario test to `scripts/test-workflow-scripts.mjs` (see Quality Gate).
5. Update docs in the same commit: the `/mission` rows in `CLAUDE.md` and `README.md`, and the missions bullet in `.workaholic/README.md`, to state that `/mission` create starts a topic branch on main (bare list / close do not).
6. Run local verify: `node scripts/build-plugins/build.mjs` (expected: no `outputs/` diff, since only the command changed), then `verify.mjs`, `validate-metadata.mjs`, and `test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- In a throwaway repo checked out on `main`, running the create sequence (`check.sh` reports `on_main: true` → `create.sh`) leaves HEAD on a fresh branch matching `work-YYYYMMDD-HHMMSS`, and the mission `mission.md` is written on that branch (not on `main`).
- In a throwaway repo already on a `work-*` branch, the create sequence creates **no** new branch (`check.sh` reports `on_main: false`); the mission is written on the current branch.
- The list and close paths never create a branch (branch unchanged after invoking them).
- `commands/mission.md` frontmatter includes `workaholic:branching`; `mission/scripts/create.sh` is byte-for-byte unchanged, so `build.mjs` yields no `outputs/` diff.

**Verification method** — the commands/tests/probes that prove them:

- A new case in `node scripts/test-workflow-scripts.mjs` seeds throwaway repos (on `main` and on a `work-*` branch), drives the `check.sh` → `create.sh` sequence, and asserts the branch name pattern, the branch HEAD change (or absence), and that a bare/close invocation leaves the branch untouched. It never touches the working tree or the network.
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` run clean with no `outputs/` diff; `node scripts/build-plugins/validate-metadata.mjs` passes.
- `posix-lint` passes on any touched script.

**Gate** — what must pass before approval:

- The full local suite is green: `build.mjs` produces no `outputs/` diff, `verify.mjs` + `validate-metadata.mjs` + `test-workflow-scripts.mjs` all pass, posix-lint clean.
- The create-from-main (branches) and create-from-work-branch (does not) behaviors, plus bare/close leaving the branch untouched, are demonstrated in-session.
- The `/mission` rows in `CLAUDE.md`/`README.md` and `.workaholic/README.md` describe the new create-branch behavior.

## Considerations

- Keep the branch step strictly on the create path — a regression that branches on bare `/mission` (list) or `/mission close` would surprise the user and pollute branch history (`plugins/workaholic/commands/mission.md`).
- Reuse `branching/scripts/check.sh` + `create.sh` unchanged; do not name a branch, add a suffix, or write inline `git checkout` — `create.sh` is the sole sanctioned `work-*` creator and `guard-git-branch.sh` will block off-pattern creation (`plugins/workaholic/skills/branching/scripts/create.sh`).
- Prefer the command-only placement to avoid an `outputs/` rebuild; only touch `mission/scripts/create.sh` or the built `mission/SKILL.md` if genuinely needed, and rebuild if so (`scripts/build-plugins/build.mjs`).
- Worktree interaction is out of scope by decision: `create.sh` does a plain `git checkout -b` in the current worktree, which is correct for the on-main case; no worktree guard is added (`plugins/workaholic/commands/mission.md`).
- A mission can also be created implicitly via `/ticket`'s mission-association flow, but that path only *associates existing* missions, so the branch-on-create concern is scoped to the `/mission` command's own create mode (`plugins/workaholic/skills/create-ticket/SKILL.md`).
