---
created_at: 2026-02-12T16:47:17+08:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: 904ed75
category:
---

# Rename manage-branch Skill to Resolve Naming Conflict with Manager Tier

## Overview

Rename the `manage-branch` utility skill to a name that does not use the `manage-` prefix. The `manage-` prefix is now reserved for manager-tier skills (`manage-project`, `manage-architecture`, `manage-quality`) as established by the `define-manager` schema. The current `manage-branch` skill is a utility skill for checking and creating git branches, not a manager agent. This naming collision forced the `define-manager.md` rule to use explicit path enumeration instead of a `manage-*/SKILL.md` glob pattern, and creates conceptual confusion about the skill's role in the hierarchy.

## Key Files

- `plugins/core/skills/manage-branch/SKILL.md` - Skill to be renamed (directory and all contents)
- `plugins/core/skills/manage-branch/sh/check.sh` - Branch state check script
- `plugins/core/skills/manage-branch/sh/create.sh` - Branch creation script
- `plugins/core/skills/manage-branch/sh/check-version-bump.sh` - Version bump detection script
- `.claude/rules/define-manager.md` - Uses explicit paths to avoid matching manage-branch; could use glob after rename
- `plugins/core/agents/ticket-organizer.md` - References manage-branch in skills frontmatter and instructions
- `plugins/core/commands/report.md` - References manage-branch shell script path

## Related History

The skill was originally named `create-branch` and was renamed to `manage-branch` during a ticket-organizer refactoring. Shortly after, the manager tier was introduced with the `manage-` naming convention, creating a collision that required explicit path scoping as a workaround.

Past tickets that touched similar areas:

- [20260203200934-refactor-ticket-organizer.md](.workaholic/tickets/archive/drive-20260203-122444/20260203200934-refactor-ticket-organizer.md) - Renamed create-branch to manage-branch (origin of current name)
- [20260204161350-manage-branch-script-update.md](.workaholic/tickets/archive/drive-20260204-160722/20260204161350-manage-branch-script-update.md) - Updated manage-branch SKILL.md to reference check.sh script (same file)
- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Introduced manager tier with manage- prefix convention; used explicit paths in define-manager.md to avoid matching manage-branch

## Implementation Steps

1. **Choose the new name**. Use `branching` as the canonical choice — descriptive, avoids the `manage-` prefix, and reads naturally as a gerund ("the branching skill").

2. **Rename the skill directory**:
   - Move `plugins/core/skills/manage-branch/` to `plugins/core/skills/branch/`
   - Update `SKILL.md` frontmatter `name:` field from `manage-branch` to `branch`
   - Update all internal path references in `SKILL.md` (`.claude/skills/manage-branch/` to `.claude/skills/branch/`)
   - Remove the Auto-Approval Configuration section (unnecessary)

3. **Update `plugins/core/agents/ticket-organizer.md`**:
   - Change skills frontmatter entry from `manage-branch` to `branch`
   - Update instruction text referencing "manage-branch" skill

4. **Update `plugins/core/commands/report.md`**:
   - Change script path from `bash .claude/skills/manage-branch/sh/check-version-bump.sh` to `bash .claude/skills/branch/sh/check-version-bump.sh`

5. **Simplify `.claude/rules/define-manager.md`**:
   - Replace the explicit path list with a `manage-*/SKILL.md` glob pattern now that the naming collision is resolved
   - Keep the agent pattern `*-manager.md` as-is

6. **Update `CLAUDE.md`**:
   - Replace the inline example path referencing `manage-branch` with the new name

## Patches

### `plugins/core/skills/manage-branch/SKILL.md`

> **Note**: This patch shows the content changes. The file itself must also be moved to `plugins/core/skills/branch-ops/SKILL.md`.

```diff
--- a/plugins/core/skills/manage-branch/SKILL.md
+++ b/plugins/core/skills/branch-ops/SKILL.md
@@ -1,6 +1,6 @@
 ---
-name: manage-branch
+name: branch-ops
 description: Check and create timestamped topic branches.
 allowed-tools: Bash
 user-invocable: false
@@ -6,7 +6,7 @@
 ---

-# Manage Branch
+# Branch Ops

 Check current branch state and create new topic branches when needed.

@@ -13,7 +13,7 @@
 ## Check Branch

 ```bash
-bash .claude/skills/manage-branch/sh/check.sh
+bash .claude/skills/branch-ops/sh/check.sh
 ```

@@ -35,7 +35,7 @@
 ## Create Branch

 ```bash
-bash .claude/skills/manage-branch/sh/create.sh [prefix]
+bash .claude/skills/branch-ops/sh/create.sh [prefix]
 ```
```

### `plugins/core/agents/ticket-organizer.md`

```diff
--- a/plugins/core/agents/ticket-organizer.md
+++ b/plugins/core/agents/ticket-organizer.md
@@ -5,7 +5,7 @@
 model: opus
 skills:
-  - manage-branch
+  - branch-ops
   - create-ticket
   - gather-ticket-metadata
 ---
@@ -25,7 +25,7 @@
 ### 1. Check Branch

-Follow preloaded **manage-branch** skill to check current branch and create a new topic branch if on main/master.
+Follow preloaded **branch-ops** skill to check current branch and create a new topic branch if on main/master.
```

### `plugins/core/commands/report.md`

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -12,7 +12,7 @@
 ## Instructions

-1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash .claude/skills/manage-branch/sh/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
+1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash .claude/skills/branch-ops/sh/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
```

### `.claude/rules/define-manager.md`

```diff
--- a/.claude/rules/define-manager.md
+++ b/.claude/rules/define-manager.md
@@ -1,7 +1,5 @@
 ---
 paths:
-  - 'plugins/core/skills/manage-project/SKILL.md'
-  - 'plugins/core/skills/manage-architecture/SKILL.md'
-  - 'plugins/core/skills/manage-quality/SKILL.md'
+  - 'plugins/core/skills/manage-*/SKILL.md'
   - 'plugins/core/agents/*-manager.md'
 ---
```

## Considerations

- The new name `branch-ops` is proposed but the exact choice may warrant discussion. Alternatives include `branch-control`, `branch-util`, or `git-branch`. The key requirement is avoiding the `manage-` prefix. (`plugins/core/skills/branch-ops/SKILL.md`)
- After renaming, the `define-manager.md` paths can be simplified to a glob, but verify that no other non-manager skills accidentally match `manage-*/SKILL.md` in the future. The glob is safe as long as the convention is enforced going forward. (`.claude/rules/define-manager.md`)
- The `CLAUDE.md` example at line 87 references the old path `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/manage-branch/sh/check.sh` and must be updated. (`CLAUDE.md` line 87)
- Spec documents under `.workaholic/specs/` and `.workaholic/policies/` contain references to `manage-branch` that should be updated on the next `/scan` run rather than manually, since those are generated documentation. (`.workaholic/specs/component.md`, `.workaholic/specs/infrastructure.md`, `.workaholic/policies/recovery.md`)
- Story files and archived tickets reference `manage-branch` historically. These should NOT be updated since they document what happened at the time. (`.workaholic/stories/`, `.workaholic/tickets/archive/`)

## Final Report

Renamed `manage-branch` skill to `branching` per developer feedback (original ticket proposed `branch-ops`, then `branch`, settled on `branching`). Also removed the unnecessary Auto-Approval Configuration section from SKILL.md.

1. Renamed `plugins/core/skills/manage-branch/` to `plugins/core/skills/branching/` — updated SKILL.md name, heading, and all script path references
2. Updated `plugins/core/agents/ticket-organizer.md` — skills frontmatter and instruction text
3. Updated `plugins/core/commands/report.md` — check-version-bump.sh script path
4. Simplified `.claude/rules/define-manager.md` — replaced explicit 3-path list with `manage-*/SKILL.md` glob
5. Updated `CLAUDE.md` — example path in Shell Script Principle section
