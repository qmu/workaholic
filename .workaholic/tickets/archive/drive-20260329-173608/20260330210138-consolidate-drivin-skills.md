---
created_at: 2026-03-30T21:01:38+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash: 8dd587f
category: Changed
---

# Consolidate Drivin Plugin Skills into Cohesive Units

## Overview

The drivin plugin has 12 skill directories that are too granularly split. Many of these skills are always consumed together by the same command or agent, meaning they serve a single cohesive workflow but are artificially separated into tiny files. This ticket consolidates the 12 skills into 5 by merging skills that share the same consumer into single comprehensive skill files. This is a pure organizational refactoring -- all instructions, shell scripts, templates, and behavioral rules are preserved exactly as-is, just reorganized into fewer directories.

Current 12 skills -> Proposed 5 skills:

| Consolidated Skill | Absorbs | Primary Consumer |
|---|---|---|
| **create-ticket** (keep) | (unchanged) | ticket-organizer agent |
| **discover** (new) | discover-history + discover-source + discover-ticket | history/source/ticket-discoverer agents |
| **drive** (new) | drive-workflow + drive-approval + write-final-report + archive-ticket + update-ticket-frontmatter | /drive command |
| **report** (new) | write-story + create-pr + assess-release-readiness | story-writer, pr-creator, release-readiness agents |
| **gather-ticket-metadata** (removed) | Already in core; delete drivin duplicate directory | (dangling, no consumers after core consolidation) |

## Key Files

- `plugins/drivin/skills/drive-workflow/SKILL.md` - Implementation workflow (80 lines), merges into `drive`
- `plugins/drivin/skills/drive-approval/SKILL.md` - Approval flow (144 lines), merges into `drive`
- `plugins/drivin/skills/write-final-report/SKILL.md` - Final report writing (84 lines), merges into `drive`
- `plugins/drivin/skills/archive-ticket/SKILL.md` - Archive workflow (52 lines), merges into `drive`
- `plugins/drivin/skills/archive-ticket/sh/archive.sh` - Archive shell script (76 lines), moves to `drive/sh/`
- `plugins/drivin/skills/update-ticket-frontmatter/SKILL.md` - Frontmatter updates (52 lines), merges into `drive`
- `plugins/drivin/skills/update-ticket-frontmatter/sh/update.sh` - Frontmatter update script (52 lines), moves to `drive/sh/`
- `plugins/drivin/skills/discover-history/SKILL.md` - History search guidelines (41 lines), merges into `discover`
- `plugins/drivin/skills/discover-history/sh/search.sh` - Archive keyword search script (25 lines), moves to `discover/sh/`
- `plugins/drivin/skills/discover-source/SKILL.md` - Source exploration guidelines (134 lines), merges into `discover`
- `plugins/drivin/skills/discover-ticket/SKILL.md` - Duplicate/overlap analysis (123 lines), merges into `discover`
- `plugins/drivin/skills/write-story/SKILL.md` - Story content templates (179 lines), merges into `report`
- `plugins/drivin/skills/create-pr/SKILL.md` - PR creation workflow (64 lines), merges into `report`
- `plugins/drivin/skills/create-pr/sh/create-or-update.sh` - PR creation script (46 lines), moves to `report/sh/`
- `plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh` - Frontmatter strip utility (22 lines), moves to `report/sh/`
- `plugins/drivin/skills/assess-release-readiness/SKILL.md` - Release analysis (75 lines), merges into `report`
- `plugins/drivin/skills/create-ticket/SKILL.md` - Ticket creation guidelines (233 lines), stays as-is
- `plugins/drivin/commands/drive.md` - Drive command, preloads 4 skills that become 1 (`drive`)
- `plugins/drivin/commands/scan.md` - Scan command, no drivin skill references (all core/standards)
- `plugins/drivin/agents/story-writer.md` - Preloads `write-story`, changes to `report`
- `plugins/drivin/agents/pr-creator.md` - Preloads `create-pr`, changes to `report`
- `plugins/drivin/agents/release-readiness.md` - Preloads `assess-release-readiness`, changes to `report`
- `plugins/drivin/agents/history-discoverer.md` - Preloads `discover-history`, changes to `discover`
- `plugins/drivin/agents/source-discoverer.md` - Preloads `discover-source`, changes to `discover`
- `plugins/drivin/agents/ticket-discoverer.md` - Preloads `discover-ticket`, changes to `discover`
- `CLAUDE.md` - Project Structure section lists drivin skills

## Related History

The drivin plugin has undergone several waves of skill extraction and consolidation. Skills were originally extracted from agents to follow the "thin agents, comprehensive skills" design principle. More recently, generic utilities (commit, gather-git-context, gather-ticket-metadata, branching) were moved from drivin to core. This ticket continues that consolidation trajectory, but instead of moving skills across plugins, it merges related skills within drivin to reduce directory count.

Past tickets that touched similar areas:

- [20260330201937-consolidate-generic-skills-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260330201937-consolidate-generic-skills-to-core.md) - Moved 4 generic skills from drivin to core; reduced drivin skill count from 16 to 12 (same layer: Config, same type: refactoring)
- [20260127204529-extract-agent-content-to-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127204529-extract-agent-content-to-skills.md) - Original extraction of agent content into preloaded skills; established the current structure being reorganized (same layer: Config)
- [20260202184602-merge-approval-flow-skills.md](.workaholic/tickets/archive/drive-20260202-134332/20260202184602-merge-approval-flow-skills.md) - Merged approval flow skills; earlier consolidation within drivin (same layer: Config)
- [20260207003033-refactor-drive-command-reduce-redundancy.md](.workaholic/tickets/archive/drive-20260205-195920/20260207003033-refactor-drive-command-reduce-redundancy.md) - Reduced redundancy in drive command; similar organizational cleanup (same layer: Config)
- [20260203200934-refactor-ticket-organizer.md](.workaholic/tickets/archive/drive-20260203-122444/20260203200934-refactor-ticket-organizer.md) - Refactored ticket-organizer; touched the same ticket creation workflow being preserved here (same layer: Config)

## Implementation Steps

1. **Create `plugins/drivin/skills/discover/` consolidated skill**:
   - Create `plugins/drivin/skills/discover/SKILL.md` combining content from discover-history, discover-source, and discover-ticket under H2 sections: `## Discover History`, `## Discover Source`, `## Discover Ticket`
   - Move `plugins/drivin/skills/discover-history/sh/search.sh` to `plugins/drivin/skills/discover/sh/search.sh`
   - Frontmatter: `name: discover`, `allowed-tools: Bash`, `user-invocable: false`
   - Update `${CLAUDE_PLUGIN_ROOT}` path in SKILL.md from `${CLAUDE_PLUGIN_ROOT}/skills/discover-history/sh/search.sh` to `${CLAUDE_PLUGIN_ROOT}/skills/discover/sh/search.sh`

2. **Create `plugins/drivin/skills/drive/` consolidated skill**:
   - Create `plugins/drivin/skills/drive/SKILL.md` combining content from drive-workflow, drive-approval, write-final-report, archive-ticket, and update-ticket-frontmatter under H2 sections: `## Workflow`, `## Approval`, `## Final Report`, `## Archive`, `## Update Frontmatter`
   - Move shell scripts preserving directory structure:
     - `plugins/drivin/skills/archive-ticket/sh/archive.sh` to `plugins/drivin/skills/drive/sh/archive.sh`
     - `plugins/drivin/skills/update-ticket-frontmatter/sh/update.sh` to `plugins/drivin/skills/drive/sh/update.sh`
   - Frontmatter: `name: drive`, `skills: [core:commit]`, `allowed-tools: Bash`, `user-invocable: false`
   - Update all `${CLAUDE_PLUGIN_ROOT}` paths in SKILL.md:
     - `${CLAUDE_PLUGIN_ROOT}/skills/archive-ticket/sh/archive.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/drive/sh/archive.sh`
     - `${CLAUDE_PLUGIN_ROOT}/skills/update-ticket-frontmatter/sh/update.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/drive/sh/update.sh`
   - Update internal shell script references: `archive.sh` line 65 references `../../update-ticket-frontmatter/sh/update.sh` -- must change to `./update.sh` (same directory after consolidation)

3. **Create `plugins/drivin/skills/report/` consolidated skill**:
   - Create `plugins/drivin/skills/report/SKILL.md` combining content from write-story, create-pr, and assess-release-readiness under H2 sections: `## Write Story`, `## Create PR`, `## Assess Release Readiness`
   - Move shell scripts:
     - `plugins/drivin/skills/create-pr/sh/create-or-update.sh` to `plugins/drivin/skills/report/sh/create-or-update.sh`
     - `plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh` to `plugins/drivin/skills/report/sh/strip-frontmatter.sh`
   - Frontmatter: `name: report`, `allowed-tools: Bash`, `user-invocable: false`
   - Update `${CLAUDE_PLUGIN_ROOT}` paths in SKILL.md from `${CLAUDE_PLUGIN_ROOT}/skills/create-pr/sh/` to `${CLAUDE_PLUGIN_ROOT}/skills/report/sh/`

4. **Delete old skill directories** (10 directories):
   - `plugins/drivin/skills/discover-history/`
   - `plugins/drivin/skills/discover-source/`
   - `plugins/drivin/skills/discover-ticket/`
   - `plugins/drivin/skills/drive-workflow/`
   - `plugins/drivin/skills/drive-approval/`
   - `plugins/drivin/skills/write-final-report/`
   - `plugins/drivin/skills/archive-ticket/`
   - `plugins/drivin/skills/update-ticket-frontmatter/`
   - `plugins/drivin/skills/write-story/`
   - `plugins/drivin/skills/create-pr/`
   - `plugins/drivin/skills/assess-release-readiness/`
   - Also delete `plugins/drivin/skills/gather-ticket-metadata/` if it still exists as a dangling empty directory

5. **Update `/drive` command frontmatter** (`plugins/drivin/commands/drive.md`):
   - Replace skills list: `drive-workflow`, `drive-approval`, `write-final-report`, `archive-ticket` -> single `drive` entry
   - Update all `${CLAUDE_PLUGIN_ROOT}` path references in command body from old skill paths to new consolidated paths
   - Specifically line 78: `${CLAUDE_PLUGIN_ROOT}/skills/archive-ticket/sh/archive.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/drive/sh/archive.sh`

6. **Update agent frontmatter** (6 agents):
   - `plugins/drivin/agents/history-discoverer.md`: Change `- discover-history` to `- discover`
   - `plugins/drivin/agents/source-discoverer.md`: Change `- discover-source` to `- discover`
   - `plugins/drivin/agents/ticket-discoverer.md`: Change `- discover-ticket` to `- discover`
   - `plugins/drivin/agents/story-writer.md`: Change `- write-story` to `- report`
   - `plugins/drivin/agents/pr-creator.md`: Change `- create-pr` to `- report`
   - `plugins/drivin/agents/release-readiness.md`: Change `- assess-release-readiness` to `- report`

7. **Update CLAUDE.md Project Structure**: Update the drivin skills listing to show the new 5-skill structure (create-ticket, discover, drive, report, and the unchanged create-ticket)

8. **Verify shell script relative paths**: After moving scripts, verify that `archive.sh`'s relative path to `commit.sh` still resolves correctly. Current path in archive.sh line 58-59: `SCRIPT_DIR=$(dirname "$0")` then `COMMIT_SCRIPT="${SCRIPT_DIR}/../../../../core/skills/commit/sh/commit.sh"`. After moving from `skills/archive-ticket/sh/` to `skills/drive/sh/`, the relative depth to core is the same (4 levels up from `sh/`), so this should not change. Also verify the `UPDATE_SCRIPT` on line 65: `${SCRIPT_DIR}/../../update-ticket-frontmatter/sh/update.sh` must change to `${SCRIPT_DIR}/update.sh` since both scripts are now in the same `drive/sh/` directory.

## Considerations

- Each consolidated SKILL.md file will be larger than the original individual files. The `drive` skill will be approximately 400+ lines combining 5 skills. This is acceptable per the design principle guideline of "~50-150 lines" since the alternative (12 directories) creates more navigational overhead than content overhead. The content itself is not duplicated or redundant -- it is distinct sections within a single cohesive topic. (`plugins/drivin/skills/drive/SKILL.md`)
- The `write-final-report` skill has a nested `skills:` frontmatter reference to `update-ticket-frontmatter`. After consolidation, both become sections within the same `drive` skill, so this nested dependency disappears. The frontmatter for the consolidated `drive` skill only needs `core:commit` as its sole skill dependency. (`plugins/drivin/skills/write-final-report/SKILL.md` line 5)
- Agent files (history-discoverer, source-discoverer, ticket-discoverer) all preload one discovery sub-skill each. After consolidation, all three agents will preload the full `discover` skill, meaning each agent gets the instructions for all three discovery phases. This is harmless because each agent already has a clear directive ("Follow the preloaded **discover-history** skill") and will only use its relevant section. The extra context is minimal and does not change behavior. (`plugins/drivin/agents/history-discoverer.md`, `plugins/drivin/agents/source-discoverer.md`, `plugins/drivin/agents/ticket-discoverer.md`)
- The `create-or-update.sh` script internally calls `strip-frontmatter.sh` using a relative path from `SCRIPT_DIR` (line 27). Since both scripts move together to `report/sh/`, this relative path continues to work with no changes. (`plugins/drivin/skills/create-pr/sh/create-or-update.sh` line 27)
- The `create-ticket` skill is kept separate rather than merged into `discover` because it serves a different consumer (ticket-organizer agent) and represents a distinct concern (writing tickets vs. discovering context). Merging it would violate single-responsibility. (`plugins/drivin/skills/create-ticket/SKILL.md`)
- The consolidated skill names (`discover`, `drive`, `report`) match the drivin command names (`/ticket` uses discover, `/drive` uses drive, `/report` uses report), creating intuitive alignment between the command layer and skill layer.

## Final Report

Consolidated 12 drivin skills into 4 (create-ticket unchanged, discover, drive, report). Created 3 new SKILL.md files combining content under H2 sections. Relocated 5 shell scripts (search.sh, archive.sh, update.sh, create-or-update.sh, strip-frontmatter.sh). Deleted 11 old skill directories. Updated drive command frontmatter (5 skill refs -> 1) and all inline skill name references. Updated 6 agent files with new skill names and section-specific directives. Fixed archive.sh internal path to update.sh (now same directory). Updated README.md skill table and CLAUDE.md project structure. All shell script relative paths verified to resolve correctly from new locations.
