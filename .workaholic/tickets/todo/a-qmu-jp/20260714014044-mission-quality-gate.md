---
created_at: 2026-07-14T01:40:42+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
commit_hash:
category: Added
depends_on: [20260714011847-mission-create-worktree-kickoff.md, 20260714014043-mission-worktree-port-assignment.md]
mission:
---

# Per-Mission Quality Gate (Documentation / Live-App Check)

## Overview

Give a **mission** its own quality gate — the objective check that says the mission's outcome is actually good, distinct from the per-ticket gates. A mission declares, in its `mission.md`, a **gate type** and target:

- `documentation` — a docs-content/behavior check (the mission's documentation renders and reads correctly).
- `live-app` — a running-app feature check (the mission's feature works in the live app).

Because the mission runs in its own worktree with a **unique port base** (from the port-assignment ticket), the gate is verified by Claude Code driving that worktree's running dev/docs server with the **Playwright plugin** — and, since every worktree serves on a different port, several missions' gates can be checked concurrently without collision. The gate declaration is surfaced to `/drive` (so a mission's work is judged against it) and can be reflected in the mission's `## Acceptance`.

workaholic's responsibility is the **declaration + the verification convention + the port to hit**; the actual server-start command is the project's (declared once, e.g. a `## Deploy`/serve convention in the project's `CLAUDE.md`), so this stays project-agnostic.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the gate declaration lives in the mission schema (`mission.md`), read via the mission scripts; verification orchestration is command/agent-level, reusing the Playwright plugin. Applies to all code work.
- `workaholic:implementation` / `policies/objective-documentation.md` — the gate must be **objective and checkable** (a named URL/route + an asserted condition), not a vague "looks good"; it is recorded in the mission, not improvised.
- `workaholic:design` / `policies/self-explanatory-ui.md` — the gate type and target must be readable from the mission without reading code, so any drive knows how the mission is judged.
- `workaholic:operation` / `policies/ci-cd.md` — the live check runs against the served worktree; it must target the worktree's assigned port and never a hardcoded one.

## Key Files

- `plugins/workaholic/skills/mission/SKILL.md` - Extend the mission schema with the gate declaration (`gate:` type + target/assertion), documented in the Schema section. mission is **built** → `build.mjs` rebuild required.
- `plugins/workaholic/skills/mission/scripts/create.sh` - Scaffold the gate declaration (empty/typed) into new `mission.md` so a mission created via the worktree flow carries it. Built → rebuild.
- `plugins/workaholic/commands/mission.md` - The create flow (worktree ticket) prompts for / records the mission gate alongside Goal/Scope/Acceptance.
- `plugins/workaholic/skills/drive/SKILL.md` - Surface the owning mission's gate when driving a missioned ticket, so implementation is judged against it (read-only reference; the Playwright run is the developer/agent's verification step).
- `plugins/workaholic/skills/branching/scripts/allocate-worktree-port.sh` / the worktree `.env` - Source of the port the live check targets (from the port ticket).
- Playwright plugin (`mcp__plugin_playwright_playwright__*`) - The tool that drives the served worktree for a `live-app`/`documentation` check.
- `CLAUDE.md`, `README.md` - Document the per-mission quality gate and the Playwright-on-worktree-port verification (same commit).

## Related History

Missions already track progress via a derived `## Acceptance` checklist; per-ticket Quality Gates were made mandatory recently. This ticket adds the **mission-level** gate and ties it to the worktree's unique port so the check can actually be run (and run concurrently) via Playwright.

Past tickets that touched similar areas:

- [20260714014043-mission-worktree-port-assignment.md](.workaholic/tickets/todo/a-qmu-jp/20260714014043-mission-worktree-port-assignment.md) - Supplies the per-worktree port the live check targets.
- [20260714011847-mission-create-worktree-kickoff.md](.workaholic/tickets/todo/a-qmu-jp/20260714011847-mission-create-worktree-kickoff.md) - The create flow that will capture the gate declaration.

## Implementation Steps

1. Add a `gate:` declaration to the mission schema (`mission/SKILL.md`): `type` (`documentation` | `live-app`), a `target` (route/URL relative to the worktree's served port), and a one-line `assert` describing what must hold. Keep progress (`checked/total`) derived and separate.
2. Scaffold the gate into `create.sh` (typed but unfilled) and capture it in the `commands/mission.md` create flow (alongside Goal/Scope/Acceptance).
3. Document the verification convention: to run a mission's gate, start the project's dev/docs server on the worktree's assigned port (project-declared serve command), then use the Playwright plugin to load the `target` and assert the condition. Surface the gate in `drive/SKILL.md` for missioned tickets.
4. Update `CLAUDE.md`/`README.md`. Rebuild (`build.mjs`, mission is built), then `verify.mjs`, `validate-metadata.mjs`, `posix-lint`, `test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `mission.md` carries a parseable `gate:` declaration (`type` ∈ {`documentation`, `live-app`}, a `target`, an `assert`); an invalid/empty type is rejected or clearly flagged.
- A mission script (or `list.sh`/a small reader) exposes the gate declaration so `/drive` can surface it; the `target` is resolved against the worktree's assigned port (from the port ticket), never a hardcoded port.
- The `mission` build target is rebuilt (`outputs/` diff committed); `verify.mjs`/`posix-lint` clean.
- The Playwright-driven check of a served worktree is demonstrated once in-session (not hermetic, since it needs a running server + browser).

**Verification method** — the commands/tests/probes that prove them:

- A new `node scripts/test-workflow-scripts.mjs` case asserts the gate declaration round-trips through `create.sh`/the schema reader (parsed type/target/assert) and that the resolved target uses the worktree's assigned port. Non-interactive, no browser/network.
- `node scripts/build-plugins/build.mjs` (mission rebuild) + `verify.mjs` + `validate-metadata.mjs` + `posix-lint` pass.
- In-session: create a mission, start its worktree's server on the assigned port, and use the Playwright plugin to verify the declared `target` — demonstrating the live gate end-to-end.

**Gate** — what must pass before approval:

- Full local suite green (`test-workflow-scripts.mjs` incl. the schema round-trip, `build.mjs` outputs committed, `verify.mjs`/`validate-metadata.mjs`/`posix-lint`).
- One end-to-end Playwright verification of a mission's gate against its worktree's port is demonstrated in-session.

## Considerations

- Server-start is project-owned: workaholic declares the gate and the port; it must not hardcode how any specific project starts its server — reference a project-declared serve convention (`plugins/workaholic/skills/mission/SKILL.md`).
- Playwright is not hermetic: keep the automated gate to the schema round-trip; the live browser check is an in-session demonstration, clearly marked (`scripts/test-workflow-scripts.mjs`).
- Keep the gate declaration in the built `mission` schema but keep worktree/Playwright orchestration in the command/agent layer, so the portable `mission` skill does not gain Claude-only browser/worktree logic (`plugins/workaholic/skills/mission/SKILL.md`).
- This ticket has genuine open design (how the project's server-start is declared and invoked); if it grows, split the schema part (declaration) from the verification-run part at drive time (`plugins/workaholic/commands/mission.md`).
