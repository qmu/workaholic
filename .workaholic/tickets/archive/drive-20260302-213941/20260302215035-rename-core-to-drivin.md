---
created_at: 2026-03-02T21:50:35+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: S
commit_hash: f50695e
category: Changed
---

# Rename "core" Plugin Directory to "drivin"

## Overview

Rename the `plugins/core` directory to `plugins/drivin` and update all references throughout the codebase. This affects the plugin name in marketplace and plugin JSON, all `subagent_type: "core:*"` references, all installed plugin path references (`~/.claude/plugins/marketplaces/workaholic/plugins/core/`), and the `CLAUDE.md` documentation.

## Key Files

- `plugins/core/.claude-plugin/plugin.json` - Plugin name and metadata (rename to `plugins/drivin/.claude-plugin/plugin.json`)
- `.claude-plugin/marketplace.json` - Plugin name and source path
- `CLAUDE.md` - Multiple references to `plugins/core` in project structure, skill script paths, and version management
- `plugins/core/commands/ticket.md` - `subagent_type: "core:ticket-organizer"`
- `plugins/core/commands/drive.md` - `subagent_type: "core:drive-navigator"` and installed path references
- `plugins/core/commands/report.md` - `subagent_type: "core:story-writer"` and installed path references
- `plugins/core/commands/scan.md` - Multiple `subagent_type: "core:*"` references and installed path references
- `plugins/core/agents/ticket-organizer.md` - `subagent_type: "core:history-discoverer"`, `"core:source-discoverer"`, `"core:ticket-discoverer"`
- `plugins/core/agents/story-writer.md` - Multiple `subagent_type: "core:*"` references
- `plugins/core/skills/*/SKILL.md` - All skill files with `~/.claude/plugins/marketplaces/workaholic/plugins/core/` path references
- `plugins/core/agents/*.md` - Agent files with installed path references
- `plugins/core/README.md` - Plugin documentation

## Related History

The project has an established pattern of renaming plugin components when naming conventions evolve. Previous rename tickets followed the same structure: directory rename via `git mv`, followed by systematic reference updates across all affected files, with historical references in archives and stories left untouched.

Past tickets that touched similar areas:

- [20260212164717-rename-manage-branch-skill.md](.workaholic/tickets/archive/drive-20260212-122906/20260212164717-rename-manage-branch-skill.md) - Renamed manage-branch to branching; same pattern of directory rename plus cascading reference updates
- [20260212173856-rename-policy-skills-to-principle.md](.workaholic/tickets/archive/drive-20260212-122906/20260212173856-rename-policy-skills-to-principle.md) - Renamed managers-policy/leaders-policy to managers-principle/leaders-principle; same large-scale rename pattern
- [20260203180235-rename-story-to-report.md](.workaholic/tickets/archive/drive-20260203-122444/20260203180235-rename-story-to-report.md) - Renamed story command to report; same command-level rename pattern

## Implementation Steps

1. **Rename the plugin directory** using `git mv plugins/core plugins/drivin`

2. **Update `plugins/drivin/.claude-plugin/plugin.json`**:
   - Change `"name": "core"` to `"name": "drivin"`

3. **Update `.claude-plugin/marketplace.json`**:
   - Change `"name": "core"` to `"name": "drivin"`
   - Change `"source": "./plugins/core"` to `"source": "./plugins/drivin"`

4. **Update all `subagent_type: "core:*"` references** to `"drivin:*"` in:
   - `plugins/drivin/commands/ticket.md` - `core:ticket-organizer` to `drivin:ticket-organizer`
   - `plugins/drivin/commands/drive.md` - `core:drive-navigator` to `drivin:drive-navigator`
   - `plugins/drivin/commands/report.md` - `core:story-writer` to `drivin:story-writer`
   - `plugins/drivin/commands/scan.md` - All `core:*` to `drivin:*` (17 agent references)
   - `plugins/drivin/agents/ticket-organizer.md` - 3 subagent references
   - `plugins/drivin/agents/story-writer.md` - 6 subagent references

5. **Update all installed plugin path references** from `~/.claude/plugins/marketplaces/workaholic/plugins/core/` to `~/.claude/plugins/marketplaces/workaholic/plugins/drivin/` in:
   - All SKILL.md files under `plugins/drivin/skills/`
   - All command files under `plugins/drivin/commands/`
   - All agent files under `plugins/drivin/agents/`

6. **Update `CLAUDE.md`**:
   - Project structure: `core/` to `drivin/` with updated description
   - All path references: `plugins/core` to `plugins/drivin`
   - Installed plugin path: update the documented path
   - Version management: `plugins/core/.claude-plugin/plugin.json` to `plugins/drivin/.claude-plugin/plugin.json`

7. **Update `plugins/drivin/README.md`**:
   - Change heading from `# Core` to `# Drivin`
   - Update description text as appropriate

## Patches

### `.claude-plugin/marketplace.json`

```diff
--- a/.claude-plugin/marketplace.json
+++ b/.claude-plugin/marketplace.json
@@ -9,9 +9,9 @@
   "plugins": [
     {
-      "name": "core",
-      "description": "Core development workflow: branch, commit, pull-request, ticket-driven development",
+      "name": "drivin",
+      "description": "Core development workflow: branch, commit, pull-request, ticket-driven development",
       "version": "1.0.37",
       "author": {
         "name": "tamurayoshiya",
         "email": "a@qmu.jp"
       },
-      "source": "./plugins/core",
+      "source": "./plugins/drivin",
       "category": "development"
     }
```

### `plugins/drivin/.claude-plugin/plugin.json`

> **Note**: This file will be at the new path after `git mv`.

```diff
--- a/plugins/core/.claude-plugin/plugin.json
+++ b/plugins/drivin/.claude-plugin/plugin.json
@@ -1,5 +1,5 @@
 {
-  "name": "core",
+  "name": "drivin",
   "description": "Core development workflow: branch, commit, pull-request, ticket-driven development",
   "version": "1.0.37",
   "author": {
```

### `plugins/drivin/commands/ticket.md`

> **Note**: This file will be at the new path after `git mv`.

```diff
--- a/plugins/core/commands/ticket.md
+++ b/plugins/drivin/commands/ticket.md
@@ -18,7 +18,7 @@
 Invoke ticket-organizer subagent via Task tool:

 ```
-Task tool with subagent_type: "core:ticket-organizer", model: "opus"
+Task tool with subagent_type: "drivin:ticket-organizer", model: "opus"
 prompt: "Create ticket for: <$ARGUMENT>. Target: <todo|icebox based on argument>"
 ```
```

### `plugins/drivin/commands/drive.md`

> **Note**: This file will be at the new path after `git mv`.

```diff
--- a/plugins/core/commands/drive.md
+++ b/plugins/drivin/commands/drive.md
@@ -21,7 +21,7 @@
 Invoke the drive-navigator subagent via Task tool:

 ```
-Task tool with subagent_type: "core:drive-navigator", model: "opus"
+Task tool with subagent_type: "drivin:drive-navigator", model: "opus"
 prompt: "Navigate tickets. mode: <normal|icebox>"
 ```
```

## Considerations

- The installed plugin path `~/.claude/plugins/marketplaces/workaholic/plugins/core/` appears in over 50 locations across skill, agent, and command files. A systematic find-and-replace is needed to avoid missing any references. (`plugins/drivin/skills/*/SKILL.md`, `plugins/drivin/agents/*.md`, `plugins/drivin/commands/*.md`)
- The GitHub Actions workflow `validate-plugins.yml` uses a glob pattern `plugins/*/.claude-plugin/plugin.json` and checks that marketplace plugin names match directory names. After renaming, the `"name": "drivin"` must match the `plugins/drivin/` directory name for CI to pass. (`.github/workflows/validate-plugins.yml` lines 95-100)
- Archived tickets, stories, and changelog entries contain historical references to `plugins/core` and `core:*`. These should NOT be updated since they document what happened at the time. (`.workaholic/tickets/archive/`, `.workaholic/stories/`)
- Generated documentation under `.workaholic/specs/` and `.workaholic/policies/` may contain `plugins/core` references. These will be regenerated on the next `/scan` run. (`.workaholic/specs/`, `.workaholic/policies/`)
- The `$CLAUDE_PLUGIN_ROOT` variable in `hooks/hooks.json` is dynamically resolved and does not need manual updating. (`plugins/drivin/hooks/hooks.json`)
- Cross-reference: The companion ticket for creating the `trippin` plugin skeleton should be implemented after this rename is complete.

## Final Report

### Description
Renamed `plugins/core` to `plugins/drivin` and updated all references across the codebase.

### Changes
- Renamed directory via `git mv plugins/core plugins/drivin`
- Updated plugin name in `plugin.json` and `marketplace.json`
- Updated all `subagent_type: "core:*"` prefixes to `"drivin:*"` across 6 command/agent files (including 16 backtick-delimited refs in scan.md)
- Updated all installed plugin path references (`plugins/core/` → `plugins/drivin/`) across 43 skill, agent, and command files
- Updated `CLAUDE.md` project structure, path examples, and version management section
- Updated `plugins/drivin/README.md` heading and install example
- Fixed hardcoded `find plugins/core` path in `analyze-viewpoint/sh/gather.sh`
- Left historical references in archives/stories untouched per ticket guidance
- Left auto-generated specs/policies for next `/scan` regeneration

### Test Plan
- [x] No remaining `plugins/core` references in active plugin files
- [x] No remaining `"core:` or `` `core:` `` subagent_type refs in active files
- [x] Plugin name `"drivin"` matches directory name `plugins/drivin/` for CI validation
- [x] Archives and stories preserve historical `plugins/core` references

### Release Preparation
- Generated documentation (`.workaholic/specs/`, `.workaholic/policies/`) still references `plugins/core` — will be regenerated on next `/scan` run
