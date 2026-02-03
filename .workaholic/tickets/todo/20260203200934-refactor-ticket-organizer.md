---
created_at: 2026-02-03T20:09:34+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Refactor ticket-organizer and Related Subagents

## Overview

Restructure the ticket-organizer subagent and its related components to improve separation of concerns:
1. Extract branch management from ticket-organizer into a new manage-branch skill
2. Move keyword extraction responsibility to individual discoverers
3. Rename ticket-moderator to ticket-discoverer for naming consistency
4. Remove overly specific memory constraints
5. Compress the ambiguity handling section

## Key Files

- `plugins/core/agents/ticket-organizer.md` - Main orchestration subagent, needs section 0 and 1 removed
- `plugins/core/agents/ticket-moderator.md` - Rename to ticket-discoverer.md
- `plugins/core/agents/history-discoverer.md` - Add keyword extraction responsibility
- `plugins/core/agents/source-discoverer.md` - Add keyword extraction responsibility
- `plugins/core/skills/create-branch/SKILL.md` - Rename to manage-branch
- `plugins/core/skills/create-branch/sh/create.sh` - Move to manage-branch directory

## Related History

This is a new refactoring effort to improve the architecture of the ticket workflow. The create-branch skill was recently added and this change aligns naming with broader "manage" pattern.

## Implementation Steps

1. Rename create-branch skill to manage-branch:
   - Move `plugins/core/skills/create-branch/` to `plugins/core/skills/manage-branch/`
   - Update SKILL.md to include branch checking logic (the "Check Branch" section content)
   - Update sh/create.sh path references if needed

2. Update ticket-organizer.md:
   - Remove "### 0. Check Branch" section entirely (now in manage-branch skill)
   - Remove "### 1. Parse Request" section (keyword extraction moves to discoverers)
   - Add `manage-branch` to skills frontmatter (replace `create-branch`)
   - Update "### 2. Parallel Discovery" to instruct calling manage-branch first
   - Update subagent references from `ticket-moderator` to `ticket-discoverer`
   - Remove the "**Note**: Subagents return summarized JSON..." line
   - Compress "### 6. Handle Ambiguity" to single line: "If ambiguous, return `status: needs_clarification` with questions array"

3. Rename ticket-moderator to ticket-discoverer:
   - Rename file: `plugins/core/agents/ticket-moderator.md` -> `plugins/core/agents/ticket-discoverer.md`
   - Update frontmatter name field to `ticket-discoverer`
   - Update title to "# Ticket Discoverer"
   - Add keyword extraction step to instructions

4. Update history-discoverer.md:
   - Add keyword extraction step: "Extract 3-5 keywords from the request description"
   - Remove "**Memory limit**" note

5. Update source-discoverer.md:
   - Add keyword extraction step: "Extract keywords and file patterns from the request description"
   - Remove "**Memory limit**" note from output section

6. Update ticket.md command:
   - Update reference from `ticket-moderator` to `ticket-discoverer` if present

## Patches

### `plugins/core/agents/ticket-organizer.md`

```diff
--- a/plugins/core/agents/ticket-organizer.md
+++ b/plugins/core/agents/ticket-organizer.md
@@ -4,8 +4,8 @@ description: Discover context, check duplicates, and write implementation ticket
 tools: Read, Write, Edit, Glob, Grep, Bash, Task
 model: opus
 skills:
-  - create-ticket
-  - gather-ticket-metadata
   - create-branch
+  - manage-branch
+  - create-ticket
+  - gather-ticket-metadata
 ---
```

### `plugins/core/agents/ticket-moderator.md`

```diff
--- a/plugins/core/agents/ticket-moderator.md
+++ b/plugins/core/agents/ticket-discoverer.md
@@ -1,5 +1,5 @@
 ---
-name: ticket-moderator
+name: ticket-discoverer
 description: Analyze existing tickets for duplicates, merge candidates, and split opportunities.
 tools: Glob, Read, Grep
 model: haiku
@@ -7,7 +7,7 @@ skills:
   - moderate-ticket
 ---

-# Ticket Moderator
+# Ticket Discoverer

 Analyze existing tickets to determine if a proposed ticket should proceed, merge with existing, or trigger a split. Follow the preloaded **moderate-ticket** skill for evaluation guidelines.
```

## Considerations

- The manage-branch skill should document both branch creation and branch checking workflows
- After renaming ticket-moderator, ensure all references in ticket-organizer.md are updated
- The keyword extraction in each discoverer allows them to optimize for their specific search needs
- Removing memory constraints trusts subagents to manage their own output sizes appropriately
