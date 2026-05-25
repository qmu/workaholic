---
created_at: 2026-05-25T20:55:29+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Package core and standards Skills for Cross-Agent Installation

## Overview

Make the `core` and `standards` skills installable and discoverable by non-Claude coding agents (Cursor, OpenCode, OpenAI Codex, Pi) following the cross-agent Agent Skills standard demonstrated by `github.com/cloudflare/skills`. That standard keeps skills at `skills/<name>/SKILL.md` (+ optional `references/`), duplicates a per-agent plugin manifest in the plugin root (`.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, etc.), and ships an `npx skills` installer that copies skills into each agent's discovery directory (`~/.claude/skills`, `~/.cursor/skills`, `~/.config/opencode/skills`, `~/.codex/skills`, `~/.pi/agent/skills`).

This ticket covers **packaging and manifests**. The companion ticket `20260525205530-audit-claude-specific-refs-in-portable-skills.md` covers auditing and fixing the Claude-Code-specific references inside the SKILL.md bodies so they actually resolve on other agents.

**Scope reality (read before estimating):** The premise that "core and standards contain only skills, so they are inherently portable" is only half true.

- `plugins/standards/skills/` (4 skills: `leading-accessibility`, `leading-availability`, `leading-security`, `leading-validity`) **are** genuinely portable today — verified pure prose with no `scripts/` directories, no `${CLAUDE_PLUGIN_ROOT}`, no cross-plugin `../` paths, and no `core:`/`standards:`/`work:` namespaced references. These ship as-is.
- `plugins/core/skills/` (14 skills) are **not** inherently portable. They are Claude-Code-workflow-coupled: every one of the 12 skills that contains shell uses `${CLAUDE_PLUGIN_ROOT}` to invoke bundled `scripts/`, several use `core:`/`standards:` namespaced skill preloads, and the workflow skills (`drive`, `ship`, `report`, `create-ticket`, `trip-protocol`) describe Claude-Code-only mechanics (subagents, slash commands, hooks). Only a subset is usable as standalone Agent Skills.

The `work` plugin is explicitly **out of scope** — it depends on Claude-Code-only features (subagents via `Task`/`subagent_type`, slash commands, hooks, Agent Teams `/trip`).

## Key Files

- `.claude-plugin/marketplace.json` - Root marketplace manifest (Claude-Code-specific). Lists `core`, `standards`, `work` with `source: ./plugins/<name>`. New per-agent manifests must stay version-synced with this file.
- `plugins/core/.claude-plugin/plugin.json` - Core manifest (`name`, `description`, `version: 1.0.48`, `dependencies: []`, `author`). Template for the duplicated per-agent manifests.
- `plugins/standards/.claude-plugin/plugin.json` - Standards manifest (`version: 1.0.48`, `dependencies: []`). Same shape as core.
- `plugins/standards/skills/` - 4 portable leading-* skills. Frontmatter uses `name`, `description`, `user-invocable: false`. Ship unchanged.
- `plugins/core/skills/` - 14 skills, each `skills/<name>/SKILL.md` + most with a `scripts/` directory. The portable subset must be selected here.
- `README.md` - Documents `claude` / `/plugin marketplace add qmu/workaholic` install only. Needs a cross-agent install section (`npx skills`, per-agent discovery dirs).
- `CLAUDE.md` - "Project Structure", "Plugin Dependencies", and "Version Management" sections must reflect the new manifests and any restructure.

## Related History

The portability blockers in `core` are a known, recurring class of issue: skill script paths have been migrated before (from relative `.claude/skills/` to absolute, then to `${CLAUDE_PLUGIN_ROOT}`), and the `standards` plugin was split out of the workflow plugin precisely to isolate the qualitative/policy layer — which is what makes the leading-* skills cleanly portable today.

Past tickets that touched similar areas:

- [20260328152057-create-standards-plugin.md](.workaholic/tickets/archive/drive-20260326-183949/20260328152057-create-standards-plugin.md) - Created the standards plugin by extracting the qualitative/policy layer; established the no-command, skills-only shape that makes leading-* portable (same plugins).
- [20260213131504-enforce-absolute-paths-for-skill-scripts.md](.workaholic/tickets/archive/drive-20260213-131416/20260213131504-enforce-absolute-paths-for-skill-scripts.md) - Codified the Skill Script Path Rule; documents the runtime path-resolution failure mode that recurs across agents (same class of bug).
- [20260213131505-audit-replace-relative-skill-script-paths.md](.workaholic/tickets/archive/drive-20260213-131416/20260213131505-audit-replace-relative-skill-script-paths.md) - The audit-and-replace companion pattern this ticket pair mirrors (same workflow shape: rule/foundation + audit).

## Implementation Steps

1. **Select the portable core subset.** Audit the 14 `core` skills and classify each as portable (standalone-useful + no Claude-Code-workflow coupling once references are fixed) vs. Claude-Code-only. Candidates for portable: knowledge skills like `commit`, `system-safety`, `check-deps`, `discover`, `create-ticket`. Almost-certainly Claude-Code-only: `drive`, `ship`, `report`, `trip-protocol`, `branching`, `gather`, `validate-writer-output`, `review-sections`, `write-release-note` (these encode subagent/command/hook/worktree mechanics). Document the classification; only portable skills get cross-agent manifests/install entries.

2. **Decide the packaging layout.** Follow the cloudflare/skills convention: keep skills at `skills/<name>/SKILL.md`. Do NOT relocate or rename the existing `plugins/<plugin>/skills/` trees (that would break Claude Code and the `work` plugin's cross-plugin references). Instead, add per-agent manifests alongside the existing `.claude-plugin/plugin.json` in each portable plugin root.

3. **Add per-agent plugin manifests** for `core` (portable subset) and `standards`, duplicating the `.claude-plugin/plugin.json` shape into the agent-specific manifest directories the standard expects (e.g. `.cursor-plugin/plugin.json`, plus whatever Codex/Pi/OpenCode require). Keep `name`, `description`, `version`, and `author` in sync with `.claude-plugin/plugin.json` and `marketplace.json`.

4. **Add Cursor `.mdc` rule wrappers** where a portable skill should also surface as a Cursor rule. `.mdc` format uses frontmatter `globs` + `alwaysApply` (boolean). Author these so the skill content is reachable as a Cursor rule without duplicating prose (reference the SKILL.md or carry a thin pointer per cloudflare's pattern).

5. **Wire up `npx skills` installation.** Add the configuration/metadata the `skills` CLI reads to enumerate this repo's skills and copy them into each agent's discovery directory (`~/.claude/skills`, `~/.cursor/skills`, `~/.config/opencode/skills`, `~/.codex/skills`, `~/.pi/agent/skills`). Verify the installer only exposes the portable subset, not `work`.

6. **Update version-sync tracking.** Add every new per-agent manifest to the `CLAUDE.md` "Version Management" file list so future `/release` bumps keep them in lockstep with `marketplace.json` and the three `.claude-plugin/plugin.json` files.

7. **Document cross-agent install** in `README.md`: how to install via `npx skills`, which skills are exposed (and that `work` is Claude-Code-only), and the per-agent discovery directories.

## Considerations

- **Vendor neutrality is the governing principle** (`plugins/standards/skills/leading-availability/SKILL.md` lines 27-29). This work is itself a vendor-neutrality move: it reduces lock-in to one agent. Keep the integration surface small — do not fork skill content per agent; share one SKILL.md body and vary only the thin manifest/rule wrappers.
- **Do not relocate the canonical skill trees.** Claude Code resolves `${CLAUDE_PLUGIN_ROOT}` to `plugins/<plugin>/`, and the `work` plugin references `../core/skills/...` (e.g. `plugins/core/skills/check-deps/scripts/check.sh` builds `${plugin_root}/../core`; `plugins/core/skills/drive/scripts/archive.sh` calls `../../../../core/skills/commit/scripts/commit.sh`). Moving `plugins/core/skills/` would break both. Additive manifests/wrappers only (`plugins/core/`, `plugins/standards/`).
- **The portable subset must be honest.** A skill that documents subagent invocation, slash-command orchestration, or worktree/hook mechanics (`drive`, `ship`, `report`, `trip-protocol`, `branching`) is not usable on Cursor/Codex/Pi even with paths fixed — exposing it would mislead users. The classification in Step 1 is the load-bearing decision here.
- **Manifest duplication is a maintenance cost.** Per-agent manifests duplicate `name`/`version`/`description`; without the Step 6 version-sync entry they will drift on the next `/release` (`CLAUDE.md` Version Management section).
- **Companion ticket ordering.** This ticket creates the packaging; `20260525205530-audit-claude-specific-refs-in-portable-skills.md` fixes the in-body references so the packaged skills actually run on other agents. The audit can begin once the portable subset is chosen here.
- **`work` exclusion must be enforced, not just documented** — the `npx skills` config (Step 5) must omit `plugins/work/` so its subagent/command/hook-coupled skills are never copied into a non-Claude agent's discovery dir.

## Patches

> **Note**: This patch is speculative — the exact per-agent manifest directory names and the `npx skills` config schema should be confirmed against `github.com/cloudflare/skills` before applying. It illustrates the additive, version-synced manifest shape for the `standards` plugin (the fully-portable case).

### `plugins/standards/.cursor-plugin/plugin.json`

```diff
--- /dev/null
+++ b/plugins/standards/.cursor-plugin/plugin.json
@@
+{
+  "name": "standards",
+  "description": "Repository structuring policy, qualitative agents, and documentation standards",
+  "version": "1.0.48",
+  "author": {
+    "name": "tamurayoshiya",
+    "email": "a@qmu.jp"
+  }
+}
```
