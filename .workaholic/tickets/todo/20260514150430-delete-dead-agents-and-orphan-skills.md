---
created_at: 2026-05-14T15:04:29+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Delete Dead Agents and Their Orphan Skills

## Overview

Five subagents in `plugins/work/agents/` have zero `subagent_type` callers anywhere in the codebase: `changelog-writer`, `lead`, `model-analyst`, `terms-writer`, and `performance-analyst`. Six skills in `plugins/core/skills/` are preloaded exclusively by these dead agents and by nothing else: `write-changelog`, `write-spec`, `write-terms`, `analyze-performance`, `analyze-policy`, and `analyze-viewpoint`. This ticket removes the dead agents, their orphan skills (entire directories including bundled `scripts/`), updates `CLAUDE.md`'s `core` skills inventory line, and cleans up the now-stale `.claude/rules/define-lead.md` references to a `plugins/standards/agents/lead.md` file that does not exist.

The work plugin's `leading-validity`, `leading-accessibility`, `leading-security`, and `leading-availability` skills under `plugins/standards/skills/` remain — they have live preloaders (`ticket-organizer`, `architect`, `planner`, `constructor`, `drive.md` command, plus discover/create-ticket/drive skill cross-references). The dead `lead` agent was one preloader among many; removing it does not orphan them.

## Key Files

### Files to delete

- `plugins/work/agents/changelog-writer.md` — agent with zero callers; only preloads `core:write-changelog`
- `plugins/work/agents/lead.md` — agent with zero callers; preloads four leading-* (live elsewhere) plus `core:analyze-policy`, `core:analyze-viewpoint`, `core:write-spec`
- `plugins/work/agents/model-analyst.md` — agent with zero callers; preloads `core:analyze-viewpoint`, `core:write-spec`
- `plugins/work/agents/terms-writer.md` — agent with zero callers; preloads `core:write-terms`
- `plugins/work/agents/performance-analyst.md` — agent with zero callers; preloads `core:gather` (live) and `core:analyze-performance`
- `plugins/core/skills/write-changelog/` — entire directory (SKILL.md + scripts/); preloaded only by the deleted `changelog-writer`
- `plugins/core/skills/write-spec/` — entire directory; preloaded only by deleted `lead` and `model-analyst`
- `plugins/core/skills/write-terms/` — entire directory; preloaded only by deleted `terms-writer`
- `plugins/core/skills/analyze-performance/` — entire directory; preloaded only by deleted `performance-analyst`
- `plugins/core/skills/analyze-policy/` — entire directory; preloaded only by deleted `lead`
- `plugins/core/skills/analyze-viewpoint/` — entire directory; preloaded only by deleted `lead` and `model-analyst`

### Files to edit

- `CLAUDE.md` — line 20 lists the six dead skill names in the `core/skills/` inventory comment; trim them
- `.claude/rules/define-lead.md` — frontmatter `paths` (line 4) and "Agent" section (lines 112–116) reference a nonexistent `plugins/standards/agents/lead.md`; the work `lead.md` being deleted is the only `lead` agent that ever existed. Remove the stale path entry and the obsolete Agent section so the rule scopes only to `plugins/standards/skills/leading-*/SKILL.md`.

### Files verified not affected

- `.claude-plugin/marketplace.json` — no per-agent or per-skill manifest entries
- `plugins/core/.claude-plugin/plugin.json`, `plugins/work/.claude-plugin/plugin.json`, `plugins/standards/.claude-plugin/plugin.json` — none name agents or skills
- `plugins/work/commands/`, `plugins/work/hooks/`, `plugins/work/rules/` — verification grep returned zero matches for any dead agent name or dead skill name
- `plugins/standards/skills/leading-*/SKILL.md` — four leading-* skills retained; they have live consumers independent of the deleted `lead` agent

## Related History

Recent commits show an active campaign to flatten the agent/skill graph by removing unused tiers: `f6869f2` deprecated `leaders-principle` and merged two leading skills, `78278c2` updated stale documentation after manager-tier removal, `ecac660` wired leading skills into work plugin flows, and `174b988` eliminated the manager tier from the standards plugin. This ticket continues that pattern by removing the next layer of dead code — agents whose call sites disappeared during the same restructuring, along with the skills only they used.

Past commits in this campaign (visible in `git log`, not under `.workaholic/tickets/archive/`):

- `f6869f2` - Deprecate leaders-principle; merge Vendor Neutrality and Ubiquitous Language into leads
- `78278c2` - Update stale documentation after manager tier removal
- `ecac660` - Wire leading skills into work plugin flows
- `174b988` - Eliminate manager tier from standards plugin
- `41e951f` - Add tickets for manager-tier elimination and lead-to-work wiring

## Implementation Steps

1. **Delete the five dead agent files** with `git rm`:
   - `plugins/work/agents/changelog-writer.md`
   - `plugins/work/agents/lead.md`
   - `plugins/work/agents/model-analyst.md`
   - `plugins/work/agents/terms-writer.md`
   - `plugins/work/agents/performance-analyst.md`
2. **Delete the six orphan skill directories** with `git rm -r` (each removes SKILL.md plus its `scripts/` subdirectory):
   - `plugins/core/skills/write-changelog/`
   - `plugins/core/skills/write-spec/`
   - `plugins/core/skills/write-terms/`
   - `plugins/core/skills/analyze-performance/`
   - `plugins/core/skills/analyze-policy/`
   - `plugins/core/skills/analyze-viewpoint/`
3. **Edit `CLAUDE.md` line 20** to remove the six dead skill names from the `core/skills/` inventory comment. The retained list is alphabetical: `branching, check-deps, commit, create-ticket, discover, drive, gather, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-overview, write-release-note`.
4. **Edit `.claude/rules/define-lead.md`**:
   - Remove `'plugins/standards/agents/lead.md'` from the `paths` array (line 4), since no `agents/lead.md` file exists anywhere in the repo after this ticket.
   - Remove or rewrite the `## Agent` section (lines 112–116) which describes a nonexistent parameterized agent at `plugins/standards/agents/lead.md`. Replace with a brief note that lead knowledge lives entirely in the `leading-*` skills with no per-domain agent files.
5. **Run the verification grep** to confirm zero remaining references in live files:
   ```bash
   grep -rn 'write-changelog\|write-spec\|write-terms\|analyze-performance\|analyze-policy\|analyze-viewpoint\|changelog-writer\|model-analyst\|terms-writer\|performance-analyst' plugins/ CLAUDE.md .claude/rules/
   ```
   Expected: no output. Matches under `.workaholic/specs/`, `.workaholic/policies/`, or `.workaholic/tickets/archive/` are historical and acceptable.
6. **Commit** as a single refactoring commit per workaholic convention.

## Patches

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -17,7 +17,7 @@ plugins/                 # Plugin source directories
 plugins/                 # Plugin source directories
   core/                  # Core shared plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    skills/              # analyze-performance, analyze-policy, analyze-viewpoint, branching, check-deps, commit, create-ticket, discover, drive, gather, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-changelog, write-overview, write-release-note, write-spec, write-terms
+    skills/              # branching, check-deps, commit, create-ticket, discover, drive, gather, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-overview, write-release-note
   standards/             # Standards policy plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
     skills/              # leading-*
```

### `.claude/rules/define-lead.md`

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -1,7 +1,6 @@
 ---
 paths:
   - 'plugins/standards/skills/leading-*/SKILL.md'
-  - 'plugins/standards/agents/lead.md'
 ---

 # Lead Agent Schema Enforcement
@@ -109,11 +108,9 @@ Use this checklist to verify a lead definition is complete and well-formed:
 - [ ] `## Practices` section, if present, contains concrete actionable items traceable to policies
 - [ ] `## Standards` section, if present, contains a table of adopted tech standards with concise comments

-## Agent
+## Agents
+
+Lead domains have no per-domain agent files. All domain knowledge lives in the `leading-<domain>` skills under `plugins/standards/skills/`. Callers that need to apply a lead's policies preload the relevant `leading-*` skill directly; there is no parameterized lead agent.

-All 4 lead domains share a single parameterized agent at `plugins/standards/agents/lead.md`. The agent preloads all domain skills and both analysis frameworks. Callers pass the domain as a prompt parameter (e.g., `"Domain: security."`), and the agent applies the matching `leading-<domain>` skill.
-
-There are no per-domain agent files. All domain knowledge lives in the lead skills, not in the agent.
-
 ## Example
```

### Deletions

```bash
git rm plugins/work/agents/changelog-writer.md
git rm plugins/work/agents/lead.md
git rm plugins/work/agents/model-analyst.md
git rm plugins/work/agents/terms-writer.md
git rm plugins/work/agents/performance-analyst.md
git rm -r plugins/core/skills/write-changelog/
git rm -r plugins/core/skills/write-spec/
git rm -r plugins/core/skills/write-terms/
git rm -r plugins/core/skills/analyze-performance/
git rm -r plugins/core/skills/analyze-policy/
git rm -r plugins/core/skills/analyze-viewpoint/
```

## Considerations

- **Stale spec documents at `.workaholic/specs/`** (model.md, ux.md, application.md, component.md, data.md, feature.md, infrastructure.md, stakeholder.md, usecase.md): these were produced by `model-analyst` and other viewpoint analysts that no longer exist. They are historical and regenerable rather than load-bearing — the workflow no longer regenerates them — so they are NOT blockers for this ticket. Leaving them in place documents the project's prior state. A future ticket may choose to archive or remove `.workaholic/specs/` and `.workaholic/policies/` entirely; that is out of scope here.
- **Stale policy documents at `.workaholic/policies/`** (accessibility.md, delivery.md, observability.md, quality.md, recovery.md, security.md, test.md): produced by the dead `lead` agent's analyze-policy flow. Same disposition as specs — historical, not regenerable in the current workflow, kept as-is.
- **The `core:gather` skill survives**: `performance-analyst` preloaded both `core:gather` (live, used by many agents) and `core:analyze-performance` (dead). Only `analyze-performance` is removed.
- **`define-lead.md` rule still serves a purpose** after the edit: it documents the schema for new lead skill files under `plugins/standards/skills/leading-*/SKILL.md`. The frontmatter `paths` field tells Claude Code's rule-loader which files trigger the rule; after this edit, only the four existing lead skill files (plus any future leading-* skill) will activate it.
- **Verification grep MUST be run before committing.** If any live file outside the deleted set still references one of the six skills or five agents by name, the deletion will produce a broken plugin load. Treat `.workaholic/` matches as historical (acceptable); treat any match under `plugins/`, `CLAUDE.md`, or `.claude/` as a blocker requiring a fix in the same commit (`.claude/rules/define-lead.md` lines 4 and 114 are the only known cases, both addressed by the patches above).
- **No version bump implications**: this is a behavioral no-op for any consumer because the deleted code paths have no callers. The release workflow handles version bumps independently.
- **Lead lens applicability**: this is a `Config` layer change touching plugin manifests, skill inventories, and rule files. No security-, validity-, accessibility-, or availability-sensitive behavior is altered — the dead code never ran. The applicable lead is whichever governs plugin-architecture hygiene, which in practice is captured by the workaholic.md rule and the project's architecture policy in `CLAUDE.md` (Component Nesting, Plugin Dependencies, Design Principle). Those are preserved.
