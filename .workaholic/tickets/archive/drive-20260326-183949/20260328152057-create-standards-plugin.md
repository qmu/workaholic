---
created_at: 2026-03-28T15:20:57+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 2h
commit_hash: 3edea8a
category: Added
---

# Create Standards Plugin and Extract Qualitative Components from Drivin

## Overview

Create a fourth plugin at `plugins/standards/` that owns the repository's structuring policy and qualitative-focused agents/skills. These components currently live in the drivin plugin but do not belong there -- drivin should focus exclusively on ticket creation, driving (implementation), and archiving.

The standards plugin will have NO commands. It exposes only agents and skills, referenced cross-plugin by drivin, trippin, and core using the existing `standards:agent-name` / `standards:skill-name` pattern. The components to extract include: all lead agents (a11y, db, delivery, infra, observability, quality, recovery, security, test, ux), all manager agents (architecture, project, quality), the performance-analyst agent, and their backing skills (leaders-principle, managers-principle, lead-*, manage-*, analyze-policy, analyze-viewpoint, analyze-performance, select-scan-agents, review-sections, write-spec, validate-writer-output, translate). Writer agents that produce documentation artifacts (model-analyst, changelog-writer, terms-writer, overview-writer, release-note-writer, section-reviewer) and their skills (write-changelog, write-terms, write-overview, write-release-note, review-sections, write-spec) also belong in standards since they are qualitative/documentation agents, not ticket-driving agents.

After extraction, drivin retains only: commands (ticket, drive, scan), agents for ticket/drive workflow (ticket-organizer, drive-navigator, history-discoverer, source-discoverer, ticket-discoverer, story-writer, pr-creator, release-readiness), and skills for ticket/drive workflow (branching, create-ticket, discover-history, discover-source, discover-ticket, drive-workflow, drive-approval, write-final-report, archive-ticket, commit, create-pr, gather-git-context, gather-ticket-metadata, update-ticket-frontmatter, write-story, assess-release-readiness, system-safety).

## Key Files

- `plugins/drivin/.claude-plugin/plugin.json` - Drivin plugin config; agents/skills list will shrink after extraction
- `plugins/drivin/agents/a11y-lead.md` - Example lead agent to move (all 10 lead agents follow this pattern)
- `plugins/drivin/agents/architecture-manager.md` - Example manager agent to move (all 3 managers follow this pattern)
- `plugins/drivin/agents/performance-analyst.md` - Performance analyst agent to move
- `plugins/drivin/agents/model-analyst.md` - Model analyst writer agent to move
- `plugins/drivin/agents/changelog-writer.md` - Changelog writer agent to move
- `plugins/drivin/agents/terms-writer.md` - Terms writer agent to move
- `plugins/drivin/agents/overview-writer.md` - Overview writer agent to move
- `plugins/drivin/agents/release-note-writer.md` - Release note writer agent to move
- `plugins/drivin/agents/section-reviewer.md` - Section reviewer agent to move
- `plugins/drivin/skills/leaders-principle/SKILL.md` - Cross-cutting leaders principle skill to move
- `plugins/drivin/skills/managers-principle/SKILL.md` - Cross-cutting managers principle skill to move
- `plugins/drivin/skills/lead-a11y/SKILL.md` - Example lead skill to move (all 10 lead-* skills follow this pattern)
- `plugins/drivin/skills/manage-architecture/SKILL.md` - Example manage skill to move (all 3 manage-* skills)
- `plugins/drivin/skills/analyze-policy/SKILL.md` - Policy analysis framework skill to move
- `plugins/drivin/skills/analyze-viewpoint/SKILL.md` - Viewpoint analysis framework skill to move
- `plugins/drivin/skills/analyze-performance/SKILL.md` - Performance analysis skill to move
- `plugins/drivin/skills/select-scan-agents/SKILL.md` - Scan agent selection skill to move
- `plugins/drivin/skills/write-spec/SKILL.md` - Spec writing skill to move
- `plugins/drivin/skills/validate-writer-output/SKILL.md` - Writer output validation skill to move
- `plugins/drivin/skills/translate/SKILL.md` - Translation skill to move
- `plugins/drivin/skills/review-sections/SKILL.md` - Section review skill to move
- `plugins/drivin/skills/write-changelog/SKILL.md` - Changelog writing skill to move
- `plugins/drivin/skills/write-terms/SKILL.md` - Terms writing skill to move
- `plugins/drivin/skills/write-overview/SKILL.md` - Overview writing skill to move
- `plugins/drivin/skills/write-release-note/SKILL.md` - Release note writing skill to move
- `plugins/drivin/commands/scan.md` - Scan command; update `subagent_type` references from `drivin:` to `standards:`
- `plugins/drivin/agents/story-writer.md` - Story writer; update `subagent_type` references from `drivin:` to `standards:`
- `.claude-plugin/marketplace.json` - Add standards plugin entry with version synced to 1.0.41
- `CLAUDE.md` - Update Project Structure section and Version Management section
- `.claude/rules/define-lead.md` - Update paths from `plugins/core/` to `plugins/standards/`
- `plugins/drivin/skills/select-scan-agents/sh/select.sh` - Will move to standards; no path changes needed in content since it uses `${CLAUDE_PLUGIN_ROOT}`

## Related History

The lead and manager agent hierarchies were built incrementally through multiple iterations, starting as analysts, being transformed to a lead architecture, then adding a manager tier above. The scan command evolved to orchestrate all these agents in parallel. The policy and viewpoint analysis frameworks were extracted into generic skills. This ticket represents the next architectural step: separating the qualitative/policy layer from the operational ticket-driving layer.

Past tickets that touched similar areas:

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead schema for lead agents (same components being moved)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - Transformed analysts to lead architecture (established the lead pattern being extracted)
- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Defined manager tier above leads (established the manager pattern being extracted)
- [20260210124953-add-leaders-policy-skill.md](.workaholic/tickets/archive/drive-20260210-121635/20260210124953-add-leaders-policy-skill.md) - Added cross-cutting leaders-policy skill (skill being extracted)
- [20260207024808-add-policy-writer-subagent.md](.workaholic/tickets/archive/drive-20260205-195920/20260207024808-add-policy-writer-subagent.md) - Added policy-writer with analyze-policy skill (skill being extracted)
- [20260311212022-unify-report-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212022-unify-report-command-across-plugins.md) - Unified commands across plugins (established cross-plugin reference pattern)

## Implementation Steps

1. Create `plugins/standards/.claude-plugin/plugin.json` with name "standards", description "Repository structuring policy, qualitative agents, and documentation standards", version "1.0.41", matching the existing plugin metadata format.

2. Create `plugins/standards/agents/` directory and move the following agents from `plugins/drivin/agents/`:
   - Lead agents: `a11y-lead.md`, `db-lead.md`, `delivery-lead.md`, `infra-lead.md`, `observability-lead.md`, `quality-lead.md`, `recovery-lead.md`, `security-lead.md`, `test-lead.md`, `ux-lead.md`
   - Manager agents: `architecture-manager.md`, `project-manager.md`, `quality-manager.md`
   - Analyst/writer agents: `performance-analyst.md`, `model-analyst.md`, `changelog-writer.md`, `terms-writer.md`, `overview-writer.md`, `release-note-writer.md`, `section-reviewer.md`

3. Create `plugins/standards/skills/` directory and move the following skills from `plugins/drivin/skills/`:
   - Principle skills: `leaders-principle/`, `managers-principle/`
   - Lead skills: `lead-a11y/`, `lead-db/`, `lead-delivery/`, `lead-infra/`, `lead-observability/`, `lead-quality/`, `lead-recovery/`, `lead-security/`, `lead-test/`, `lead-ux/`
   - Manage skills: `manage-architecture/`, `manage-project/`, `manage-quality/`
   - Analysis skills: `analyze-policy/`, `analyze-viewpoint/`, `analyze-performance/`
   - Writer skills: `write-spec/`, `write-changelog/`, `write-terms/`, `write-overview/`, `write-release-note/`, `review-sections/`
   - Utility skills: `select-scan-agents/`, `validate-writer-output/`, `translate/`

4. Update all cross-plugin references in drivin:
   - `plugins/drivin/commands/scan.md`: Change all `subagent_type` values from `drivin:` to `standards:` for moved agents (all managers, all leads, model-analyst, changelog-writer, terms-writer). Add `standards` skills to the skills preload list where needed (select-scan-agents, write-spec, validate-writer-output).
   - `plugins/drivin/agents/story-writer.md`: Change `subagent_type` from `drivin:performance-analyst` to `standards:performance-analyst`, `drivin:overview-writer` to `standards:overview-writer`, `drivin:section-reviewer` to `standards:section-reviewer`, `drivin:release-note-writer` to `standards:release-note-writer`.
   - `plugins/drivin/agents/release-readiness.md`: Verify skill reference -- if `assess-release-readiness` stays in drivin, no change needed.

5. Update `.claude/rules/define-lead.md`: Change the `paths` references from `plugins/core/` to `plugins/standards/` (lines reference lead skills and lead agents).

6. Update `.claude-plugin/marketplace.json`: Add a new standards plugin entry in the `plugins` array, positioned after core and before drivin.

7. Update `CLAUDE.md`:
   - Add standards to the Project Structure section tree diagram
   - Add `plugins/standards/.claude-plugin/plugin.json` to Version Management section
   - Update drivin description in the tree to reflect its reduced scope

8. Update `README.md`: Add standards plugin description alongside the existing plugin descriptions.

## Considerations

- The scan command currently references agents with `drivin:` prefix throughout Phase 3a and 3b (`plugins/drivin/commands/scan.md` lines 38-64). Every `subagent_type` for moved agents must change to `standards:`. Missing even one reference will cause a runtime resolution failure.
- The `select-scan-agents/sh/select.sh` script (`plugins/drivin/skills/select-scan-agents/sh/select.sh`) uses `${CLAUDE_PLUGIN_ROOT}` implicitly since it only outputs agent names, not paths. After moving to standards, the script content itself needs no changes, but the scan command's skill preload must reference `standards:select-scan-agents` instead.
- Story-writer invokes 4 subagents (`plugins/drivin/agents/story-writer.md` lines 22-27), 3 of which move to standards (performance-analyst, overview-writer, section-reviewer). The release-readiness agent stays in drivin since it is part of the release workflow. The pr-creator also stays in drivin.
- The `.claude/rules/define-lead.md` currently has `paths` targeting `plugins/core/skills/lead-*/SKILL.md` and `plugins/core/agents/*-lead.md` (`plugins/core/` lines 3-4). These paths appear to already be stale (leads live in drivin, not core). Update to `plugins/standards/`.
- The version must be synced to 1.0.41 across all four plugin.json files and marketplace.json. The Version Management section in CLAUDE.md must list the new file.
- Agents that are moved will have their skill references resolved via `${CLAUDE_PLUGIN_ROOT}` which will point to `plugins/standards/` after the move. Since skills move alongside their agents, internal skill references within moved agents continue to work without modification.
- The drivin scan command preloads skills via frontmatter (`plugins/drivin/commands/scan.md` lines 5-8). Skills that move to standards (select-scan-agents, write-spec, validate-writer-output) will need cross-plugin skill references in the scan command frontmatter, using the `standards:skill-name` pattern.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The scan command's Phase 2 and Phase 4 used `${CLAUDE_PLUGIN_ROOT}/skills/` paths for select-scan-agents and validate-writer-output scripts. After moving these skills to standards, the bash paths needed cross-plugin updates (`${CLAUDE_PLUGIN_ROOT}/../standards/skills/...`) in addition to the frontmatter skill preloads. The ticket anticipated the frontmatter changes but not the inline bash path changes.
  **Context**: When moving skills between plugins, both skill preload references (frontmatter) AND inline bash script paths must be updated. The frontmatter uses `standards:skill-name` syntax while bash paths use the `/../sibling/` directory traversal pattern.
- **Insight**: The performance-analyst agent preloads `gather-git-context`, which remains in drivin. After moving to standards, this needed a cross-plugin reference (`drivin:gather-git-context`). Other moved agents only reference skills that also moved, so no additional cross-plugin fixups were needed.
  **Context**: When extracting agents, check each agent's skill preload list for skills that stay behind in the original plugin.
