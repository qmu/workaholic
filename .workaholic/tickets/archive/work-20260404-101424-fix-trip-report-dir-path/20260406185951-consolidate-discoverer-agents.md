---
created_at: 2026-04-06T18:59:51+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: 4546122
category: Changed
---

# Consolidate 3 Discoverer Subagent Files into a Single Parameterized Agent

## Overview

Replace the 3 thin discoverer subagent files (`history-discoverer.md`, `source-discoverer.md`, `ticket-discoverer.md`) with a single `discoverer.md` agent that accepts a mode parameter (`history`, `source`, or `ticket`). All three already preload the same `discover` skill and follow its corresponding section (Discover History, Discover Source, Discover Ticket). The consolidated agent preloads the `discover` skill and uses the union of tools from all three: `Bash, Read, Glob, Grep`. The caller (`ticket-organizer.md`) passes the mode in the prompt and invokes `work:discoverer` instead of 3 separate subagent types.

## Key Files

- `plugins/work/agents/history-discoverer.md` - Thin agent to be deleted (tools: Bash, Read, Glob)
- `plugins/work/agents/source-discoverer.md` - Thin agent to be deleted (tools: Glob, Grep, Read)
- `plugins/work/agents/ticket-discoverer.md` - Thin agent to be deleted (tools: Glob, Read, Grep)
- `plugins/work/agents/discoverer.md` - New consolidated agent to create
- `plugins/work/agents/ticket-organizer.md` - Caller that invokes the 3 discoverers; must switch to single `work:discoverer` with mode parameter
- `plugins/work/skills/discover/SKILL.md` - Shared skill already structured by mode sections (Discover History, Discover Source, Discover Ticket)
- `plugins/work/skills/create-ticket/SKILL.md` - References `history-discoverer` subagent by name in Related History section
- `plugins/work/README.md` - Documents all 3 discoverers in the Drive Agents table

## Related History

This codebase has a strong precedent for consolidating multiple thin agent files into a single parameterized agent. The identical pattern was applied to 10 lead agents in the standards plugin, and earlier to 12 drivin skill directories.

- [20260406182846-consolidate-lead-agents-into-parameterized-agent.md](.workaholic/tickets/archive/work-20260404-101424-fix-trip-report-dir-path/20260406182846-consolidate-lead-agents-into-parameterized-agent.md) - Consolidated 10 lead agents into single parameterized `lead.md` (exact same pattern being applied here)
- [20260129-parallel-discovery-ticket-command.md](.workaholic/tickets/archive/feat-20260129-023941/20260129-parallel-discovery-ticket-command.md) - Added parallel discovery with history + source discoverers (created the current architecture being refactored)
- [20260129015817-add-discover-history-subagent.md](.workaholic/tickets/archive/feat-20260128-220712/20260129015817-add-discover-history-subagent.md) - Original creation of history-discoverer (same file being deleted)
- [20260330210138-consolidate-drivin-skills.md](.workaholic/tickets/archive/drive-20260329-173608/20260330210138-consolidate-drivin-skills.md) - Consolidated 12 drivin skill directories into 5 cohesive units (precedent for consolidation)

## Implementation Steps

1. **Create `plugins/work/agents/discoverer.md`**

   Create a single agent that preloads the `discover` skill and declares the union of all tools: `Bash, Read, Glob, Grep`. The frontmatter:

   ```yaml
   ---
   name: discoverer
   description: Context discovery agent supporting history, source, and ticket analysis modes.
   tools: Bash, Read, Glob, Grep
   model: opus
   skills:
     - discover
   ---
   ```

   The body instructs the agent to:
   1. Read the caller's prompt to determine the mode (`history`, `source`, or `ticket`).
   2. Follow the corresponding section of the preloaded **discover** skill (Discover History, Discover Source, or Discover Ticket).
   3. Return JSON in the format specified by that section's output schema.

   Keep the agent thin (~20 lines body) per the design principle. All knowledge lives in the discover skill.

2. **Delete the 3 individual discoverer agent files**

   Remove:
   - `plugins/work/agents/history-discoverer.md`
   - `plugins/work/agents/source-discoverer.md`
   - `plugins/work/agents/ticket-discoverer.md`

3. **Update `plugins/work/agents/ticket-organizer.md` section 2 (Parallel Discovery)**

   Replace the 3 separate subagent invocations with 3 invocations of the single `work:discoverer` agent, each with a mode parameter in the prompt:

   Before (3 distinct subagent_type values):
   ```
   - **history-discoverer** (`subagent_type: "work:history-discoverer"`)
   - **source-discoverer** (`subagent_type: "work:source-discoverer"`)
   - **ticket-discoverer** (`subagent_type: "work:ticket-discoverer"`)
   ```

   After (single subagent_type, mode in prompt):
   ```
   - **discoverer (history)** (`subagent_type: "work:discoverer"`): Pass "mode: history" + full description
   - **discoverer (source)** (`subagent_type: "work:discoverer"`): Pass "mode: source" + full description
   - **discoverer (ticket)** (`subagent_type: "work:discoverer"`): Pass "mode: ticket" + full description
   ```

   Also update the reference in section 3 from "ticket-discoverer JSON result" to "discoverer (ticket) JSON result".

4. **Update `plugins/work/skills/create-ticket/SKILL.md` Related History reference**

   Line 190 references `history-discoverer` subagent by name. Update to reference `discoverer` agent with history mode.

5. **Update `plugins/work/skills/discover/SKILL.md` Tool Constraints reference**

   Line 167 references `source-discoverer` by name. Update to reference `discoverer` agent or remove the agent-specific name since the consolidated agent has all tools.

6. **Update `plugins/work/README.md` Drive Agents table**

   Replace the 3 discoverer rows with a single row:

   Before:
   ```
   | `history-discoverer`  | Find related historical tickets                         |
   | `source-discoverer`   | Find related source files and analyze code flow         |
   | `ticket-discoverer`   | Analyze tickets for duplicates, merge, and split        |
   ```

   After:
   ```
   | `discoverer`          | Context discovery (history, source, ticket modes)       |
   ```

## Patches

### `plugins/work/agents/discoverer.md`

> **Note**: This is a new file, not a diff against an existing file.

```
---
name: discoverer
description: Context discovery agent supporting history, source, and ticket analysis modes.
tools: Bash, Read, Glob, Grep
model: opus
skills:
  - discover
---

# Discoverer

Multipurpose context discovery agent. Follow the preloaded **discover** skill, using the section that matches the requested mode.

## Input

You will receive:
- Mode: `history`, `source`, or `ticket`
- Description of the feature/change being planned

## Mode Routing

| Mode | Skill Section | Purpose |
| ---- | ------------- | ------- |
| `history` | Discover History | Search archived tickets for related past work |
| `source` | Discover Source | Explore codebase for relevant files and code flow |
| `ticket` | Discover Ticket | Analyze existing tickets for duplicates/merge/split |

## Output

Return JSON in the format specified by the corresponding skill section's output schema.
```

### `plugins/work/agents/ticket-organizer.md`

```diff
--- a/plugins/work/agents/ticket-organizer.md
+++ b/plugins/work/agents/ticket-organizer.md
@@ -30,9 +30,9 @@
 
 Invoke ALL THREE subagents concurrently using Task tool (single message with three parallel Task calls):
 
-- **history-discoverer** (`subagent_type: "work:history-discoverer"`, `model: "opus"`): Find related tickets. Pass full description. Receives JSON with summary, tickets list, match reasons.
-- **source-discoverer** (`subagent_type: "work:source-discoverer"`, `model: "opus"`): Find relevant source files. Pass full description. Receives JSON with summary, files list, code flow.
-- **ticket-discoverer** (`subagent_type: "work:ticket-discoverer"`, `model: "opus"`): Analyze for duplicates/merge/split. Pass full description. Receives JSON with status, matches list, recommendation.
+- **discoverer (history)** (`subagent_type: "work:discoverer"`, `model: "opus"`): Pass "mode: history" + full description. Receives JSON with summary, tickets list, match reasons.
+- **discoverer (source)** (`subagent_type: "work:discoverer"`, `model: "opus"`): Pass "mode: source" + full description. Receives JSON with summary, files list, code flow.
+- **discoverer (ticket)** (`subagent_type: "work:discoverer"`, `model: "opus"`): Pass "mode: ticket" + full description. Receives JSON with status, matches list, recommendation.
 
 Wait for all three to complete, then proceed with all JSON results.
 
@@ -39,7 +39,7 @@
 
 ### 3. Handle Moderation Result
 
-Based on ticket-discoverer JSON result:
+Based on discoverer (ticket) JSON result:
 - If `status: "duplicate"`: Return `status: "duplicate"` with existing ticket path
 - If `status: "needs_decision"`: Return `status: "needs_decision"` with merge/split options
 - If `status: "clear"`: Proceed to step 4
```

### `plugins/work/skills/create-ticket/SKILL.md`

```diff
--- a/plugins/work/skills/create-ticket/SKILL.md
+++ b/plugins/work/skills/create-ticket/SKILL.md
@@ -187,7 +187,7 @@
 
 ## Related History
 
-The Related History section is populated by the `history-discoverer` subagent (invoked by `/ticket` command).
+The Related History section is populated by the `discoverer` agent in history mode (invoked by `/ticket` command).
 
 **Link format**: Use markdown links with repository-relative paths:
```

### `plugins/work/skills/discover/SKILL.md`

```diff
--- a/plugins/work/skills/discover/SKILL.md
+++ b/plugins/work/skills/discover/SKILL.md
@@ -164,7 +164,7 @@
 
 ### Tool Constraints
 
-The source-discoverer has access to Glob, Grep, Read tools only:
+In source mode, the discoverer has access to Glob, Grep, Read, and Bash tools but should primarily use Glob, Grep, Read:
 
 - Cannot execute code or follow dynamic imports
 - Cannot analyze runtime behavior
```

### `plugins/work/README.md`

```diff
--- a/plugins/work/README.md
+++ b/plugins/work/README.md
@@ -30,9 +30,7 @@
 | Agent                 | Description                                             |
 | --------------------- | ------------------------------------------------------- |
 | `drive-navigator`     | Route and prioritize tickets for /drive                 |
-| `history-discoverer`  | Find related historical tickets                         |
-| `source-discoverer`   | Find related source files and analyze code flow         |
-| `ticket-discoverer`   | Analyze tickets for duplicates, merge, and split        |
+| `discoverer`          | Context discovery (history, source, ticket modes)       |
 | `ticket-organizer`    | Discover context, check duplicates, and write tickets   |
 | `story-writer`        | Generate branch story for PR description                |
 | `pr-creator`          | Create or update GitHub PR from story file              |
```

## Considerations

- The consolidated agent preloads Bash in its tool list even though ticket and source modes do not strictly need it. History mode requires Bash to run the `search.sh` script. This is acceptable since unused tools do not affect behavior, and it follows the same union-of-tools pattern used in the lead agent consolidation. (`plugins/work/agents/discoverer.md`)
- The discover skill already structures its content by mode section (Discover History, Discover Source, Discover Ticket), so no skill restructuring is needed. The mode routing in the agent body simply directs to the appropriate section. (`plugins/work/skills/discover/SKILL.md`)
- Archived tickets and story files reference the old agent names (`history-discoverer`, `source-discoverer`, `ticket-discoverer`) in their text. These are historical records and should not be updated. Only live plugin files need changes. (`.workaholic/tickets/archive/`, `.workaholic/stories/`)
- The `CLAUDE.md` project structure comment lists individual agents in the work plugin directory. This comment may become stale but is not a functional reference -- updating it is optional housekeeping. (`CLAUDE.md` line referencing `agents/`)

## Final Report

### Changes

- Created `plugins/work/agents/discoverer.md` — single parameterized agent preloading the discover skill with mode routing table (history, source, ticket)
- Deleted 3 individual discoverer agent files (`history-discoverer.md`, `source-discoverer.md`, `ticket-discoverer.md`)
- Updated `plugins/work/agents/ticket-organizer.md` section 2 to invoke `work:discoverer` with mode parameter, and section 3 reference
- Updated `plugins/work/skills/create-ticket/SKILL.md` Related History reference
- Updated `plugins/work/skills/discover/SKILL.md` Tool Constraints reference
- Updated `plugins/work/README.md` Drive Agents table (3 rows → 1 row)

### Test Plan

- Verified all file references updated (no remaining mentions of individual discoverer slugs in live plugin files)
- Agent file follows same parameterized pattern as consolidated lead.md
