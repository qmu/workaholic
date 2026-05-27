---
created_at: 2026-05-27T14:21:31+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort: 1h
commit_hash: 94ca753
category: Changed
depends_on: [20260527142130-relocate-cross-agent-output-into-dist.md]
---

# Expose the workflow skills to OpenCode via a shared generated plugin

## Overview

OpenCode is the third supported coding agent (alongside Claude Code and Codex). Verification (step 1) established that OpenCode needs **no bespoke plugin format** — it natively discovers the universal `SKILL.md` format from `.agents/skills/`, `.claude/skills/`, and `.opencode/skills/`, and the `vercel-labs/skills` CLI installs skills into exactly those locations.

Therefore, rather than a per-agent `dist/opencode/` mirror, this ticket adopts a **single neutral generated plugin dir** (`dist/workflows/`) that serves every non-Claude agent: Codex via its co-located `.codex-plugin/plugin.json`, and OpenCode + Cursor + 40 others via the `skills` CLI reading the root `.claude-plugin/marketplace.json`. One generated artifact, two manifests pointing at it, zero per-agent duplication.

## Key Files

- `tools/build-portable-skills/build.mjs` - rename the assembled output dir `dist/codex` → `dist/workflows` (neutral); it already contains `.codex-plugin/plugin.json` + self-contained `skills/`
- `.agents/plugins/marketplace.json` - repoint the `workflows` plugin `source.path` → `./dist/workflows`
- `.claude-plugin/marketplace.json` - add a non-internal `workflows` plugin entry (`source: ./dist/workflows`, skills listed) so the `skills` CLI exposes the self-contained workflow skills to OpenCode and other agents
- `dist/workflows/` - the renamed generated plugin (output of this ticket)

## Implementation Steps

1. **(done) Verify OpenCode's discovery format.** OpenCode has first-party skills support and loads `SKILL.md` skills from `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` (project + `~/.config/opencode` global). No `.codex-plugin`-style manifest; scripts referenced relative to skill root. The generated self-contained skills already satisfy this. See Discussion.
2. In `build.mjs`, rename the assembled-plugin constant and output from `dist/codex` to `dist/workflows`; update header comments and the assemble-function name/logs. The closure/rewrite/`publicizeSkillMd` pipeline is unchanged.
3. Rebuild, `git rm` the old `dist/codex/`, and stage the new `dist/workflows/`.
4. Repoint `.agents/plugins/marketplace.json` `workflows.source.path` → `./dist/workflows`.
5. Add a `workflows` plugin entry to `.claude-plugin/marketplace.json` (mirroring the `standards` entry shape) so the `skills` CLI scans `dist/workflows/skills/` and exposes the self-contained, non-internal skills cross-agent. Give it a description that clarifies it is the portable cross-agent build (Claude Code users install `core`/`work` instead).
6. Build and verify: `node tools/build-portable-skills/build.mjs` then `verify.mjs`; confirm `dist/workflows/skills/` is self-contained (no `${CLAUDE_PLUGIN_ROOT}`). Preview the CLI exposure with `npx skills add . --list` if available.

## Considerations

- The same accepted trade-off applies: the workflow skills are self-contained copies generated from `plugins/core`; there is no cross-skill sharing in the spec.
- **Claude double-install risk**: `.claude-plugin/marketplace.json` is read by both Claude Code and the `skills` CLI. The new `workflows` entry must be opt-in (Claude users use `core`); its description should steer Claude users away to avoid installing duplicate workflow skills alongside `core`.
- The `.codex-plugin/plugin.json` co-located inside `dist/workflows/` is harmless to the `skills` CLI (which scans only `skills/`).
- The CLAUDE.md "Known limitation: built skills retain Claude-namespaced `skills:` preloads" note is **stale** — `publicizeSkillMd` strips the `skills:` block. Correct this in the docs ticket (T4).

## Discussion

### Revision 1 - 2026-05-27T14:30:00+09:00

**User decision** (via drive question): expose OpenCode through a *shared skills dir + the `skills` CLI*, not a literal `dist/opencode/` mirror.

**Verification finding**: OpenCode reads the universal `SKILL.md` format natively ([OpenCode skills docs](https://opencode.ai/docs/skills/), [DeepWiki sst/opencode](https://deepwiki.com/sst/opencode/5.7-skills-system)); the `skills` CLI installs to `.agents/skills/` where OpenCode looks. No bespoke OpenCode manifest is needed.

**Direction change**: replaced "add a per-agent `dist/opencode/` target" with "rename `dist/codex` → neutral `dist/workflows` and expose it via the root `.claude-plugin/marketplace.json` so one generated plugin serves Codex + OpenCode + 40 agents."

## Final Report

Development completed with the redirected design. `npx skills add . --list` discovers 10 skills (4 Standards + 6 Workflows: create-ticket, drive, report, ship, review-sections, write-release-note); `verify.mjs` resolves all 45 references; both manifests parse; the internal script-bearing `core` skills stay hidden.

### Discovered Insights

- **Insight**: One generated plugin dir can satisfy two unrelated install systems at once — Codex reads `dist/workflows/.codex-plugin/plugin.json` while the `skills` CLI scans `dist/workflows/skills/` and ignores the dotfile manifest.
  **Context**: This is why no per-agent `dist/<agent>/` proliferation is needed; future agents that read the universal `SKILL.md` format are served by the existing `skills` CLI exposure with zero new build targets.
- **Insight**: `.claude-plugin/marketplace.json` is dual-read by Claude Code (installs plugins) and the `skills` CLI (exposes non-internal skills). Adding a generated `workflows` entry exposes it cross-agent but also lists it for Claude Code, where it would duplicate `core`.
  **Context**: The opt-in description is the only guard today; a future improvement could be a marketplace mechanism to mark an entry "skills-CLI only." Worth noting in the docs (T4).
