---
created_at: 2026-07-14T01:40:42+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
commit_hash: ed775ca
category: Changed
depends_on: [20260714011846-mission-worktree-primitive.md, 20260714011847-mission-create-worktree-kickoff.md]
mission:
---

# Assign a Unique Local Port Base per Mission Worktree

## Overview

When a mission worktree is created, assign it a **unique local port base** so that several worktrees can run their dev/docs servers **at the same time without colliding on `localhost`**. This is what lets concurrent worktree development actually run in parallel, and lets Claude Code drive each worktree's running server with the Playwright plugin independently (the verification path the per-mission quality gate builds on).

Design:

- **Collision-free allocation.** On mission-worktree creation, allocate the next free port base by scanning the port bases already assigned to existing `.worktrees/*` worktrees and picking the next unused slot from a fixed start (e.g. base `PORT_START + N*STRIDE`, `STRIDE` large enough to cover a worktree's dev + docs + any aux ports). Allocation is recorded per worktree so it is stable across restarts.
- **Config carried in the worktree.** Write the assigned ports into the worktree so the project's own dev/docs server picks them up. The natural carrier is the worktree's `.env` (which `ensure-worktree.sh` already copies in) — set a small, generic set of variables (e.g. a `WORKAHOLIC_PORT_BASE` plus conventional derived `…_DEV_PORT` / `…_DOCS_PORT`), so a project's serve scripts read them with the project's own env precedence. workaholic supplies the **convention and the unique numbers**; the project decides which server binds which variable.
- **Generic, no project internals.** This is a workaholic-side convention; it names no specific project or its serve scripts.

Note on "workloads": each worktree is treated as an independent workload with its own port configuration — the config lives **in that worktree**, not in a shared file that would reintroduce collisions.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — allocation is a bundled `branching` script (not built) referenced via `${CLAUDE_PLUGIN_ROOT}`; port config is written into the worktree, not hand-edited. Applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`, no bashisms; `posix-lint`-checked. Applies to all code work.
- `workaholic:operation` / `policies/ci-cd.md` — the port convention governs how the running system is served locally; it must be deterministic and free of collisions so parallel worktrees each serve cleanly.
- `workaholic:design` / `policies/self-explanatory-ui.md` — the assigned ports must be discoverable (reported on worktree creation and readable from the worktree's `.env`) so the developer/agent knows where each worktree serves.

## Key Files

- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` - The mission-worktree creator (from the primitive ticket): after `git worktree add` + `.env` copy, call the port allocator and write the assigned port variables into the worktree's `.env`; include the ports in its JSON output. branching is not built → no rebuild.
- `plugins/workaholic/skills/branching/scripts/allocate-worktree-port.sh` - New allocator: scan existing `.worktrees/*` `.env` port bases, return the next free base (POSIX, deterministic).
- `plugins/workaholic/skills/branching/scripts/ensure-worktree.sh` - Existing `.env` copy precedent; the port write extends the same "carry config into the worktree" idea.
- `plugins/workaholic/skills/branching/SKILL.md` - Document the per-worktree port convention (variable names, allocation, that a project's serve scripts read them).
- `CLAUDE.md`, `README.md` - Note the per-worktree port convention for mission worktrees (same commit).
- `scripts/test-workflow-scripts.mjs` - Hermetic allocation test (see Quality Gate).

## Related History

The worktree toolkit already copies the root `.env` into each new worktree (`ensure-worktree.sh`); this ticket extends that "carry config into the worktree" pattern with a **unique** port base so concurrent worktrees do not fight over the same `localhost` ports. It is the mechanism the per-mission quality-gate ticket (docs/live-app checks via Playwright) depends on.

Past tickets that touched similar areas:

- [20260714011846-mission-worktree-primitive.md](.workaholic/tickets/todo/a-qmu-jp/20260714011846-mission-worktree-primitive.md) - Creates the mission worktree this ticket assigns a port base to.
- [20260713144839-worktree-copies-root-env.md](.workaholic/tickets/archive/work-20260713-144839/20260713144839-worktree-copies-root-env.md) - Established the `.env`-into-worktree copy this extends.

## Implementation Steps

1. Add `branching/scripts/allocate-worktree-port.sh`: scan `.worktrees/*/.env` for existing `WORKAHOLIC_PORT_BASE` values, compute the next free base from `PORT_START + N*STRIDE`, emit `{port_base, dev_port, docs_port}` (derived by fixed offsets). Deterministic and collision-free.
2. In `create-mission-worktree.sh`, after the `.env` copy, run the allocator and append/override the port variables in the worktree's `.env`; add the ports to the script's JSON output so creation reports them.
3. Document the convention in `branching/SKILL.md` (variable names, allocation, project-reads-them) and note it in `CLAUDE.md`/`README.md`.
4. Run `posix-lint`, `test-workflow-scripts.mjs`, `build.mjs` (expect no `outputs/` diff — branching not built), `verify.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Creating two mission worktrees in a repo yields **two distinct** port bases (and distinct derived dev/docs ports), each written into that worktree's `.env`.
- Allocation is collision-free against already-assigned bases (a third worktree gets a base not equal to either existing one) and stable (re-reading a worktree's `.env` returns the same base).
- The port base and derived ports are reported in `create-mission-worktree.sh`'s JSON output.
- Scripts pass `posix-lint`; `build.mjs` yields no `outputs/` diff.

**Verification method** — the commands/tests/probes that prove them:

- A new `node scripts/test-workflow-scripts.mjs` case seeds a temp repo, runs `allocate-worktree-port.sh` / the create flow for two/three worktrees, and asserts distinct bases, collision-free next-allocation, `.env` contents, and JSON output. No network.
- `sh plugins/workaholic/hooks/posix-lint.sh` conforming; `node scripts/build-plugins/build.mjs` no `outputs/` diff; `verify.mjs`/`validate-metadata.mjs` pass.

**Gate** — what must pass before approval:

- Full local suite green (`test-workflow-scripts.mjs` incl. the new case, `posix-lint`, `build.mjs` no diff, `verify.mjs`/`validate-metadata.mjs`).
- Two concurrently-created worktrees are shown serving on different ports in-session (hermetic allocation test counts; a live two-server demo is the stretch check).

## Considerations

- Variable names / carrier location need a final call at drive time: the default here is the worktree `.env` with `WORKAHOLIC_PORT_BASE` + derived ports; confirm whether a project expects a different variable or a dedicated config file before locking it in (`plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh`).
- Keep it project-agnostic: workaholic assigns numbers and a convention; it must not hardcode any specific project's server names or ports (`plugins/workaholic/skills/branching/SKILL.md`).
- Port exhaustion / reuse: after a worktree is removed, its base should become allocatable again; base the allocation on currently-registered worktrees, not an ever-growing counter (`plugins/workaholic/skills/branching/scripts/allocate-worktree-port.sh`).
- `.env` is a copy per worktree, so writing ports there keeps worktrees independent — do not centralize port state in a shared file (`plugins/workaholic/skills/branching/scripts/ensure-worktree.sh`).

## Final Report

Development completed as planned. Confirmed with the developer the carrier is the worktree `.env`. Added `allocate-worktree-port.sh` (next free base `4100 + k*10`, scanning live `.worktrees/*/.env` so freed bases reuse) and wired `create-mission-worktree.sh` to write `WORKAHOLIC_PORT_BASE`/`_DEV_PORT`/`_DOCS_PORT` into the worktree `.env` and report them. Hermetic test: distinct bases per worktree, allocator avoids assigned ones, docs=base+1, `.env` carries the base, a removed worktree's base is reallocated; 503 passed / 0 failed, build/verify/metadata/posix-lint clean.

### Discovered Insights

- **Insight**: Writing ports into the worktree `.env` required also excluding `.env` (not just `.worktrees/`) via `.git/info/exclude` — otherwise the newly-written `.env` registers as an untracked "dirty" file and blocks `reset-mission-worktree.sh` / `cleanup-mission-worktree.sh` (which refuse dirty worktrees). The exclude guard now covers both patterns.
  **Context**: This is why the earlier ship-reset and close tests kept passing without per-test `.gitignore` after ports were added — the shared exclude keeps the worktree clean by construction.
