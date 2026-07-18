---
created_at: 2026-07-18T19:15:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
---

# validate-ticket resolves the mission in the ticket's own checkout

## Overview

`hooks/validate-ticket.sh`'s mission-relation check resolves slugs via `mission_resolve`, which reads `.workaholic/missions/...` **relative to the hook's cwd** (the session's working directory). A ticket written into a mission worktree (`.worktrees/<slug>/.workaholic/tickets/todo/<user>/`) from a session whose cwd is the main tree is validated against the **main tree's** missions — where a worktree-local mission does not exist — producing a false `mission relation does not resolve` error for a perfectly valid ticket. Observed 2026-07-18 while writing a missioned ticket into `.worktrees/monitor-e2e-alpha/` (the mission existed in that worktree's `.workaholic/missions/active/`): the sanctioned mission layout keeps `mission.md` inside the mission worktree until its branch merges, so every main-session write of a worktree ticket hits this.

Fix: derive the ticket's own repository root from `tool_input.file_path` (e.g. `git -C "$(dirname "$file_path")" rev-parse --show-toplevel`, with a plain-path fallback) and resolve the mission relative to **that** root, not the cwd. The same cwd assumption should be audited in the hook's other checks (the `todo/<user>/` scoping already keys off the path itself, so the mission block appears to be the only cwd-dependent one).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — path resolution must respect the worktree layout the mission model prescribes
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX sh hook conventions (`#!/bin/sh -eu`, posix-lint conformant)

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` - the mission-relation block (`mission_resolve` sourced from `skills/mission/scripts/lib/resolve.sh`) resolves relative to cwd
- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` - `mission_resolve` uses relative `.workaholic/missions/...` paths by design; the hook must `cd` into the ticket's root (subshell) before calling it, rather than changing the lib
- `scripts/test-workflow-scripts.mjs` - `testValidateTicketMission` covers the main-tree case; add the worktree case (ticket + mission both inside a worktree, hook invoked with cwd = main root)

## Related History

The mission-worktree layout (mission.md living inside `.worktrees/<slug>/` until merge) postdates the hook's mission-relation check; the check was written against the main-tree layout and never re-audited for worktree-resident tickets.

## Implementation Steps

1. In the mission-relation block of `validate-ticket.sh`, resolve the ticket file's own repo root (`git -C <ticket-dir> rev-parse --show-toplevel`, falling back to cwd when git is unavailable) and run the `mission_resolve` loop inside a `( cd <that-root> && … )` subshell.
2. Add a smoke test: a worktree-resident missioned ticket validates cleanly when the hook runs with cwd = main root; a genuinely dangling slug still exits 2.
3. Re-run `node scripts/test-workflow-scripts.mjs` and posix-lint.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A ticket in `.worktrees/<slug>/.workaholic/tickets/todo/<user>/` whose `mission:` resolves inside that worktree's own `.workaholic/missions/{active,archive}/` passes the hook when the hook's cwd is the main tree.
- A slug that resolves in neither the ticket's checkout still exits 2 with the existing error message.

**Verification method** — the commands/tests/probes that prove them:

- New assertions in `scripts/test-workflow-scripts.mjs` (worktree-resident pass + dangling-slug reject) are green; the full suite stays green.
- `sh plugins/workaholic/hooks/posix-lint.sh` reports zero findings.

**Gate** — what must pass before approval:

- The suite and posix-lint are green, and the exact 2026-07-18 reproduction (write a missioned ticket into a mission worktree from a main-tree session) no longer errors.

## Considerations

- The hook is Claude-Code-only with no `outputs/` footprint; no rebuild needed (`plugins/workaholic/hooks/`)
- `/monitor`'s drive leaves mint `deferred` tickets inside mission worktrees from sessions whose cwd may be the main root — this defect would false-flag every one of them, so it directly protects the monitor flow (`plugins/workaholic/skills/monitor/SKILL.md` §2)
