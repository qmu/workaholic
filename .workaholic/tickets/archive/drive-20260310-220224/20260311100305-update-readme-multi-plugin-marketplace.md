---
created_at: 2026-03-11T10:03:05+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: e1b85b8
category: Changed
---

# Update README to Present Workaholic as Multi-Plugin Marketplace

## Overview

Rewrite the repository README.md to reflect that Workaholic is now a plugin marketplace containing multiple plugins (Drivin and Trippin), not a single TiDD workflow tool. The current README describes only the Drivin workflow and its commands. The update should guide users on discovering available plugins, understanding what each one does, how to enable them, and example use cases for each.

## Key Files

- `README.md` - Main repository README to be rewritten
- `.claude-plugin/marketplace.json` - Marketplace metadata listing both plugins
- `plugins/drivin/README.md` - Drivin plugin documentation (reference for accurate descriptions)
- `plugins/trippin/README.md` - Trippin plugin documentation (reference for accurate descriptions)
- `plugins/trippin/commands/trip.md` - Trip command details (reference for workflow description)

## Related History

The README has undergone several major rewrites as the project's identity evolved, from initial creation through TiDD philosophy reframing to adding git warnings. The recent multi-plugin restructuring (renaming core to drivin, creating trippin skeleton, implementing the trip command) established the marketplace as a two-plugin system, but the README was never updated to reflect this.

Past tickets that touched similar areas:

- [20260128222843-rewrite-readme-tidd-philosophy.md](.workaholic/tickets/archive/feat-20260128-220712/20260128222843-rewrite-readme-tidd-philosophy.md) - Rewrote README to focus on TiDD philosophy (same file, same type of comprehensive rewrite)
- [20260302215035-rename-core-to-drivin.md](.workaholic/tickets/archive/drive-20260302-213941/20260302215035-rename-core-to-drivin.md) - Renamed core plugin to drivin, establishing multi-plugin naming
- [20260302215036-create-trippin-plugin-skeleton.md](.workaholic/tickets/archive/drive-20260302-213941/20260302215036-create-trippin-plugin-skeleton.md) - Created trippin plugin skeleton, making marketplace multi-plugin
- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the trip command with Agent Teams workflow
- [20260207033210-add-git-warning-to-readme.md](.workaholic/tickets/archive/drive-20260205-195920/20260207033210-add-git-warning-to-readme.md) - Added git warning banner to README (preserve this warning)

## Implementation Steps

1. **Rewrite the opening section** to position Workaholic as a private marketplace for Claude Code plugins, not a single-purpose TiDD tool:
   - Update the tagline/description to describe the marketplace concept
   - Mention that multiple plugins are available for different workflows
   - Keep the git warning banner (important user safety information)

2. **Add a "Plugins" section** that presents each available plugin:
   - **Drivin**: Ticket-driven development workflow. Describe its purpose (TiDD, serial execution, in-repository tickets). List its commands (`/ticket`, `/drive`, `/scan`, `/report`)
   - **Trippin**: AI-collaborative exploration workflow. Describe its purpose (Agent Teams, multi-agent exploration, worktree isolation). List its command (`/trip`)
   - For each plugin, show how to enable it after marketplace installation

3. **Update the Quick Start section**:
   - Show marketplace installation (keep existing `claude` + `/plugin marketplace add qmu/workaholic`)
   - Explain that plugins are discovered and enabled individually after marketplace installation
   - Remove the single command table that only shows Drivin commands

4. **Add use case examples for each plugin**:
   - Drivin example: The existing "Typical Session" flow (ticket, drive, report cycle)
   - Trippin example: A brief exploration scenario showing `/trip` launching an Agent Teams session for collaborative design

5. **Restructure "How It Works"** to be plugin-aware:
   - Keep the existing TiDD explanation but scope it under Drivin
   - Add a brief explanation of the Trippin workflow (Planner/Architect/Constructor agents, worktree-based exploration, two-phase specification and implementation)
   - Keep the Spec-Driven Development note but scope it appropriately

6. **Update the Documentation section** to remain accurate:
   - The `.workaholic/` directory contents description can stay as-is since both plugins use it

7. **Keep the Author section** unchanged

## Patches

### `README.md`

> **Note**: This patch is speculative - the exact content will need editorial judgment. Showing the structural transformation rather than exact prose.

```diff
--- a/README.md
+++ b/README.md
@@ -1,6 +1,6 @@
 # Workaholic

-Claude Code plugin aiming at in-repository ticket-driven development (TiDD). It stores project context in `.workaholic/` for better AI decisions, enabling fast serial development without worktree or multi-repo overhead.
+Private marketplace for Claude Code plugins. Discover and enable plugins that add structured workflows to your Claude Code sessions, from ticket-driven development to AI-collaborative exploration.

 > [!WARNING]
 > **This plugin drives git on your behalf.** Workaholic lets Claude Code autonomously create branches, commit, amend, push, and open pull requests. Review the command list below before installing so you know what to expect.
@@ -14,13 +14,7 @@

 Enable the plugin after installation. Auto update is recommended.

-| Command   | What it does                                  |
-| --------- | --------------------------------------------- |
-| `/ticket` | Plan a change with context and steps          |
-| `/drive`  | Implement queued tickets one by one           |
-| `/scan`   | Full documentation scan (all 17 agents)       |
-| `/report` | Generate story and create PR                  |
-
-### Typical Session
+## Plugins
```

## Considerations

- The git warning banner must be preserved as-is since both plugins perform autonomous git operations (`README.md` lines 5-6)
- The Spec-Driven Development info card is Drivin-specific and should be scoped accordingly, or moved into the Drivin section to avoid confusing Trippin users (`README.md` lines 43-51)
- The marketplace description in `.claude-plugin/marketplace.json` currently says "Standard Claude Code Configuration in qmu" which may also need updating to match the new README positioning, but that is out of scope for this ticket (`.claude-plugin/marketplace.json` line 4)
- The Trippin plugin requires the experimental `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` flag; this prerequisite should be noted in the README alongside the Trippin description (`plugins/trippin/commands/trip.md` line 16)
- The Documentation section references `.workaholic/` artifacts that are primarily generated by Drivin commands; clarify whether Trippin also writes to this directory (`README.md` lines 54-61)

## Final Report

### Changes Made

- **`README.md`**: Complete rewrite. Updated tagline to "Private marketplace for Claude Code plugins." Added Plugins section with Drivin and Trippin subsections, each with command tables and example sessions. Scoped TiDD/SDD content under Drivin, Agent Teams/Implosive Structure content under Trippin. Added Agent Teams prerequisite note for Trippin. Preserved git warning banner and Documentation/Author sections.

### Approach

Structural rewrite preserving all existing information while reorganizing around a per-plugin presentation. Each plugin gets its own command table, example session, and workflow explanation.
