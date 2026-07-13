---
created_at: 2026-07-14T01:18:46+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 4h
commit_hash:
category: Changed
depends_on: [20260714011846-mission-worktree-primitive.md]
mission:
---

# /mission Create Spins Up a Persistent Worktree, Statement, and Kickoff Tickets

## Overview

Change `/mission "<title>"` create so it makes the mission **drive-ready in a dedicated, persistent worktree**. Every new mission (the default — no opt-in) runs this flow:

1. Derive the mission **slug from the title** — a human-readable, feature-explaining name (e.g. `"Real-time Notifications"` → `real-time-notifications`). This is the worktree directory name; it is **not** a `work-*` branch name.
2. Create the persistent worktree at `.worktrees/<slug>/` on a fresh `work-YYYYMMDD-HHMMSS` branch off `main`, via the foundation primitive `branching/scripts/create-mission-worktree.sh "<slug>"` (from the depended-on ticket).
3. Write the mission statement (`mission.md`) **inside that worktree** (run `mission/scripts/create.sh` with the worktree as CWD), then work with the developer to fill `## Goal`/`## Scope`/`## Acceptance`.
4. Create the **kickoff tickets** inside the worktree — **one at a time through the full `/ticket` (create-ticket) workflow** (three-mode discovery + the mandatory Quality-Gate interrogation per ticket), each stamped `mission: <slug>` and written to the worktree's `.workaholic/tickets/todo/<user>/`, ordered via `depends_on`.
5. Commit the mission statement and the kickoff tickets inside the worktree (via `commit/scripts/commit.sh`, keeping the subject policy-conformant and the `Co-Authored-By` trailer).

Result: the developer opens the `.worktrees/<slug>/` worktree and can immediately `/drive` an ordered, mission-linked queue. This **replaces** the in-tree branch-on-create step shipped earlier on this branch (ticket `20260714001859`); that step's `check.sh` → `create.sh` (a `git checkout -b` in the current tree) is removed in favor of the worktree flow. Bare `/mission` (list), `/mission summary`, and `/mission close` are unchanged here. Existing missions already running on `main` or another worktree are tolerated; this only governs new `/mission` creates.

**Do not instruct the developer to `cd`** (standing feedback): report the worktree path and rely on `/drive`'s existing auto-routing into worktrees. All worktree/kickoff orchestration lives in `commands/mission.md` (Claude-only) so the built, cross-agent `mission` skill stays portable.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — orchestration in the thin command reusing `branching`/`create-ticket`/`commit` scripts via `${CLAUDE_PLUGIN_ROOT}`; no `git worktree` hand-rolled in the `.md`. Applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — any new/edited shell (e.g. the shared slug helper) is POSIX `#!/bin/sh -eu`; no inline conditionals in the command. Applies to all code work.
- `workaholic:design` / `policies/modeless-design.md` — creating the worktree is the default (chosen), but the flow must stay low-friction and self-explanatory: report the worktree path and the ready-to-drive queue, never hand the developer a `cd` instruction.
- `workaholic:development` / `policies/overnight-ai.md` — the dedicated worktree is what enables parallel/overnight development per mission; the kickoff queue must be ordered and drive-ready so an autonomous `/drive` can run it.

## Key Files

- `plugins/workaholic/commands/mission.md` - The "## With a title — create a mission" section is rewritten: remove the `check.sh` → `create.sh` branch step; add the worktree → mission.md → kickoff-`/ticket` → commit orchestration, scoped to the create path only. Claude-only → no rebuild.
- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` - The foundation primitive (from the depended-on ticket) this flow calls to make `.worktrees/<slug>/`.
- `plugins/workaholic/skills/mission/scripts/create.sh` - Scaffolds `mission.md`; run it with the worktree as CWD so the file lands inside. Its slug derivation must match the worktree dir name — extract a shared `mission/scripts/slug.sh "<title>"` (single slug rule) that both `create.sh` and the command's worktree-naming use. **Touching `mission/scripts/` requires `build.mjs`.**
- `plugins/workaholic/skills/create-ticket/SKILL.md` - The kickoff tickets go through this full Workflow (discovery + Quality-Gate interrogation), written to the worktree's `todo/<user>/` with `mission: <slug>`.
- `plugins/workaholic/skills/gather/scripts/ticket-metadata.sh` - Supplies `author`/`user_slug`/`filename_timestamp` for both `mission.md` and each kickoff ticket, resolved against the worktree CWD.
- `plugins/workaholic/skills/commit/scripts/commit.sh` - Commits `mission.md` + kickoff tickets inside the worktree with a policy-conformant subject.
- `plugins/workaholic/hooks/validate-ticket.sh`, `guard-ticket-structure.sh` - Kickoff tickets must land in `<worktree>/.workaholic/tickets/todo/<user>/` (the hooks match on path suffix, so a worktree-nested path passes).
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` - Update the `/mission` behavior (create now builds a persistent worktree + kickoff queue, superseding the branch-on-create note) in the same commit.

## Related History

Ticket `20260714001859` (shipped earlier on this branch) gave `/mission` create an in-tree topic branch on main and explicitly scoped worktrees out; this ticket reverses that decision per the developer's persistent-mission-worktree model. Kickoff-ticket generation mirrors the trip Decomposition gate (a goal → ordered, `mission:`-linked tickets), but here each ticket is produced through the full `/ticket` flow rather than a trip Constructor.

Past tickets that touched similar areas:

- [20260714001859-mission-branch-on-create.md](.workaholic/tickets/archive/work-20260714-000543/20260714001859-mission-branch-on-create.md) - The branch-on-create step this supersedes (same file: `commands/mission.md` create path).
- [20260714000528-command-summary-mode.md](.workaholic/tickets/archive/work-20260714-000543/20260714000528-command-summary-mode.md) - Recent `/mission` dispatch change (same command; keep summary/list/close modes intact).

## Implementation Steps

1. Extract the mission slug rule into `mission/scripts/slug.sh "<title>"` and have `create.sh` use it, so the worktree dir name and the mission slug come from one source (rebuild required).
2. In `commands/mission.md` create path: remove the branch-on-main step; add — (a) derive slug via `slug.sh`; (b) `create-mission-worktree.sh "<slug>"` → note `worktree_path`/`branch`; (c) run `mission/scripts/create.sh "$ARGUMENT"` with the worktree as CWD; guide filling Goal/Scope/Acceptance; (d) run the full create-ticket Workflow for each kickoff ticket (discovery + Quality-Gate interrogation), writing to the worktree's `todo/<user>/` with `mission: <slug>` and `depends_on` ordering; (e) `commit.sh` the mission.md + tickets inside the worktree.
3. Report the worktree path and the ordered kickoff queue; tell the developer it is ready to `/drive` there — **without** a `cd` instruction (rely on `/drive` auto-routing). Leave list/summary/close modes untouched.
4. Handle the already-on-a-worktree / dirty-tree cases gracefully (a worktree needs a clean, committed base; surface a clear message rather than failing mid-flow).
5. Update `CLAUDE.md`/`README.md`/`.workaholic/README.md`. Run `build.mjs` (rebuild for the `mission` slug change), `verify.mjs`, `validate-metadata.mjs`, `posix-lint`, `test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Running the create orchestration for a mission titled e.g. `"Real-time Notifications"` produces a `.worktrees/real-time-notifications/` worktree (descriptive slug, **not** `work-*`) on a `work-YYYYMMDD-HHMMSS` branch off `main`.
- `mission.md` exists and is **committed** inside that worktree at `.workaholic/missions/active/real-time-notifications/mission.md`; the mission slug equals the worktree dir name (shared `slug.sh`).
- The kickoff ticket(s) are **committed** inside the worktree under `.workaholic/tickets/todo/<user>/`, each carrying `mission: real-time-notifications`; running `list-todo.sh` with the worktree as CWD returns exactly that ordered set (drive-ready).
- The main working tree is untouched (HEAD/branch unchanged, `git status` clean); no branch-on-create `git checkout -b` runs in the main tree.
- `mission/scripts/create.sh` change is reflected in `outputs/` (rebuild committed); `verify.mjs`/`posix-lint` clean.

**Verification method** — the commands/tests/probes that prove them:

- A new `node scripts/test-workflow-scripts.mjs` case seeds a temp repo, drives the create sequence's scriptable core (`slug.sh` → `create-mission-worktree.sh` → `create.sh` in the worktree → write a kickoff ticket with `mission:` → `commit.sh`), and asserts the worktree/branch/slug, that `mission.md` and the ticket are committed inside the worktree, that in-worktree `list-todo.sh` returns the kickoff set, and that the main tree is unchanged. Non-interactive, no network.
- `node scripts/build-plugins/build.mjs` regenerates `outputs/` (mission slug change) with a committed diff; `verify.mjs` + `validate-metadata.mjs` + `posix-lint` pass.

**Gate** — what must pass before approval:

- Full local suite green (`test-workflow-scripts.mjs`, `build.mjs` outputs committed, `verify.mjs`/`validate-metadata.mjs`/`posix-lint`).
- A live in-session create demonstrates the worktree + committed mission.md + committed kickoff queue that `/drive` can run, and shows bare `/mission`/summary/close still behave.
- Docs updated to describe the new create behavior.

## Considerations

- The full `/ticket` flow per kickoff ticket is interactive and heavy (discovery + Quality-Gate interrogation each); the automated gate exercises the scriptable core, while the interactive decomposition is validated by the in-session demo (`plugins/workaholic/skills/create-ticket/SKILL.md`).
- Slug collisions: if `.worktrees/<slug>` or the mission slug already exists, refuse and report (mirror `create.sh`'s exists-guard) rather than clobbering (`plugins/workaholic/skills/mission/scripts/create.sh`).
- CWD discipline: `create.sh`, the kickoff `/ticket` writes, and `commit.sh` must all run against the **worktree** tree, not the main tree; the `guard-working-directory.sh` advisory prefers a `( cd <worktree> && … )` subshell over moving the persistent cwd (`plugins/workaholic/hooks/guard-working-directory.sh`).
- Never instruct `cd`; rely on `/drive` worktree auto-routing (standing feedback) (`plugins/workaholic/commands/mission.md`).
- Keep worktree/kickoff prose out of the built `mission` SKILL.md to preserve portability; only the `slug.sh` extraction touches the built skill (`plugins/workaholic/skills/mission/SKILL.md`).
