---
created_at: 2026-06-16T07:39:37+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash: 2ab5754
category: Added
depends_on:
---

# Add an anti-spelunking guard to the work plugin commands

## Overview

When a session loads the work plugin via `--plugin-dir` (the launch mode in
`scripts/claude.sh`), the command skills are already in context — `work:ticket`
preloads `core:create-ticket`/`core:branching`/`core:gather`, `work:drive`
preloads `core:drive`, all anchored to `${CLAUDE_PLUGIN_ROOT}`. The correct
behavior is to **invoke the loaded skill directly**.

In practice an agent instead filesystem-spelunked: it grepped `~/.claude`, found
a **stale global marketplace install** (`~/.claude/plugins/marketplaces/workaholic/`,
v1.0.40, dated before the drivin/trippin→work consolidation), ran that install's
obsolete `sh/` scripts, and guessed dead plugin namespaces (`drivin:ticket`,
`drivin:drive`) — wandering for minutes before finally calling `work:ticket`.
The stale tree on disk made the wrong path look real, so the failure is not pure
hallucination: the obsolete namespace was physically present to be found.

Add a short, explicit guard block to the work command `**Notice:**` headers that
(1) states the skill is already loaded and reached only through
`${CLAUDE_PLUGIN_ROOT}`, (2) prohibits reaching into `~/.claude/plugins/marketplaces/`
or any global install, (3) prohibits guessing obsolete namespaces (`drivin`,
`trippin`) — the only valid namespaces are `core:`, `work:`, `standards:` — and
(4) directs the agent to ask the user, not hunt the filesystem, if a skill seems
missing. This is instructional prose only: thin command, no script, no hook.

## Key Files

- `plugins/work/commands/ticket.md` - PRIMARY. Header block (L10–18) already
  carries `**Notice:**`, `**CRITICAL:**`, `**Policy Lens**`; add the guard as a
  sibling bold paragraph in the same region.
- `plugins/work/commands/drive.md` - PRIMARY. Header block (L8–14); guard slots
  in right after the existing `**Notice:**` (L10).
- `plugins/work/commands/report.md` - Parity. Has a `**Notice:**` (L10).
- `plugins/work/commands/ship.md` - Parity. Has a `**Notice:**` (L12).
- `plugins/work/commands/trip.md` - Parity. Has a `**Notice:**` (L10).
- `CLAUDE.md` - The existing `### Skill Script Path Rule` (L147–166) is the
  closest norm; reuse its framing and, optionally, add a short sibling
  subsection so the guard has a repo-wide authored home the per-command Notices
  can echo.

## Related History

Prior work covered authoring-time path correctness and the rename that produced
the obsolete namespaces, but no prior ticket adds a runtime behavioral guard for
this failure mode.

- [26-the-absolute-path-claude-plugins-marketplaces.md](.workaholic/concerns/archive/26-the-absolute-path-claude-plugins-marketplaces.md) - The exact stale `~/.claude/plugins/marketplaces/...` path class, resolved only at authoring time by the `${CLAUDE_PLUGIN_ROOT}` migration.
- [34-add-automated-validation-that-all-claude.md](.workaholic/concerns/archive/34-add-automated-validation-that-all-claude.md) - Deferred ask for static validation that `${CLAUDE_PLUGIN_ROOT}/../<plugin>/` refs resolve to declared deps; this ticket is the runtime-behavior complement.
- [33-the-consolidated-drive-skill-in-drivin.md](.workaholic/concerns/archive/33-the-consolidated-drive-skill-in-drivin.md) - From the drivin→work consolidation; establishes `drivin`/`trippin` as obsolete namespaces — the dead names the guard tells agents never to guess.
- [drive-20260213-131416.md](.workaholic/stories/drive-20260213-131416.md) - Added the `Skill Script Path Rule` to CLAUDE.md and swept 39 files onto `${CLAUDE_PLUGIN_ROOT}`; primary precedent for how the project codifies plugin-path rules.

## Implementation Steps

1. Draft a single canonical guard paragraph in the established Notice voice, e.g.:
   *"The skills this command needs are already loaded via its `skills:` frontmatter
   and reached only through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded
   namespace (`core:`, `work:`, `standards:`). NEVER read or run anything under
   `~/.claude/plugins/marketplaces/` or any other global install, and NEVER guess
   a plugin/skill namespace — the names `drivin` and `trippin` are obsolete
   (merged into `work`). If a needed skill is not in context, ask the user which
   plugins are loaded; do not search the filesystem for it."*
2. Add the guard to `plugins/work/commands/ticket.md` and `drive.md` (primary).
3. Add the same guard to `report.md`, `ship.md`, `trip.md` for parity, in each
   file's existing header region.
4. Optionally add a short sibling subsection under CLAUDE.md's `${CLAUDE_PLUGIN_ROOT}`
   policy area (near L147–166) titled to cover "don't reach into global installs /
   don't guess obsolete namespaces," so the per-command Notices have one source to
   echo and future commands inherit it.
5. Keep it prose-only — no script, no conditional shell, no new agent file
   (Thin-commands principle). `work` has no `skills/` dir and is excluded from
   `dist/`, so no rebuild is required.

## Considerations

- The guard must not introduce any path-probing or conditional inline shell —
  that would violate the Shell Script Principle in `CLAUDE.md`. It is pure
  instruction text. (`CLAUDE.md` Shell Script Principle)
- Keep it terse; commands are thin orchestration (~50–100 lines). One short
  paragraph per file, ideally sourced from one canonical wording. (`CLAUDE.md`
  "Thin commands, comprehensive skills")
- Cross-plugin references must stay in the canonical `${CLAUDE_PLUGIN_ROOT}/../core/...`
  form (declared dependency); the guard reinforces this contract rather than
  adding a new path. (`plugins/work/commands/ticket.md` pre-check lines)
- This is a documentation/instruction guard; it reduces but cannot fully prevent
  an agent ignoring instructions. The durable complement is removing the stale
  installs from disk (environment cleanup) and the static validation deferred in
  concern #34 — note both in the commit body but keep this ticket scoped to the
  command guard. (`~/.claude/plugins/marketplaces/` — outside the repo)
- standards:implementation reachability lens: the goal is a single stable
  contract (`${CLAUDE_PLUGIN_ROOT}`-resolved skill) the AI agent reaches reliably,
  not multiple drifting paths. (`plugins/standards/skills/implementation/`)

## Final Report

Development completed as planned. Added an identical `**Plugin boundary — do not
spelunk:**` paragraph after the `**Notice:**` in all five `work` commands
(`ticket`, `drive`, `report`, `ship`, `trip`), and added a canonical `### Plugin
Boundary Rule` subsection to `CLAUDE.md` (after the Skill Script Path Rule) that
the notices echo. Prose-only — no scripts, hooks, or agent files; `work` has no
`skills/` dir and is excluded from `dist/`, so no rebuild was required.

### Discovered Insights

- **Insight**: The `drivin`/`trippin` namespace confusion is reinforced by stale
  global marketplace installs physically present on disk
  (`~/.claude/plugins/marketplaces/workaholic/` v1.0.40), not pure model
  hallucination. The instructional guard is one layer; the durable complements
  are (a) deleting stale installs from the environment and (b) the static
  `${CLAUDE_PLUGIN_ROOT}/../<plugin>/`-resolves-to-declared-dependency validation
  deferred in concern #34.
  **Context**: A future agent debugging "wrong skill loaded" should check for
  shadowing global installs before assuming a source bug.
