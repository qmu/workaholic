---
created_at: 2026-02-02T18:22:39+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: 3197a5a
category: Changed
---

# Configure Opus Model for ticket-organizer and Child Subagents

## Overview

Configure the `/ticket` command to invoke ticket-organizer with `model: "opus"`, and configure ticket-organizer to invoke its child subagents (history-discoverer, source-discoverer, ticket-moderator) with `model: "opus"` as well. This ensures the ticket creation workflow uses the Opus model for higher quality context discovery and ticket writing.

## Key Files

- `plugins/core/commands/ticket.md` - Add model parameter to ticket-organizer invocation
- `plugins/core/agents/ticket-organizer.md` - Add model parameter to child subagent invocations

## Related History

Historical tickets demonstrate the pattern of adding model parameters to Task tool invocations, with haiku used for report subagents.

Past tickets that touched similar areas:

- [20260128211509-use-haiku-for-report-subagents.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211509-use-haiku-for-report-subagents.md) - Same pattern: added model parameter to subagent invocations (used haiku for cost efficiency)
- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Recent refactoring that added the three child subagents (same files)
- [20260129015817-add-discover-history-subagent.md](.workaholic/tickets/archive/feat-20260128-220712/20260129015817-add-discover-history-subagent.md) - Original history-discoverer implementation with model parameter pattern

## Implementation Steps

1. **Update ticket.md Step 2**:
   - Add `model: "opus"` to the Task tool invocation for ticket-organizer

   Before:
   ```markdown
   Task tool with subagent_type: "core:ticket-organizer"
   prompt: "Create ticket for: <$ARGUMENT>. Target: <todo|icebox based on argument>"
   ```

   After:
   ```markdown
   Task tool with subagent_type: "core:ticket-organizer", model: "opus"
   prompt: "Create ticket for: <$ARGUMENT>. Target: <todo|icebox based on argument>"
   ```

2. **Update ticket-organizer.md Step 2 (Parallel Discovery)**:
   - Add `model: "opus"` to all three child subagent invocations

   Before:
   ```markdown
   **2-A. History Discovery** (via Task tool):
   ```
   subagent_type: "core:history-discoverer"
   prompt: "Find related tickets for keywords: <keyword1> <keyword2> ..."
   ```
   ```

   After:
   ```markdown
   **2-A. History Discovery** (via Task tool):
   ```
   subagent_type: "core:history-discoverer"
   model: "opus"
   prompt: "Find related tickets for keywords: <keyword1> <keyword2> ..."
   ```
   ```

   Apply the same change to:
   - 2-B. Source Discovery (source-discoverer)
   - 2-C. Ticket Moderation (ticket-moderator)

3. **Update the Parallel Discovery section header** to document model usage:

   Before:
   ```markdown
   Invoke ALL THREE subagents concurrently using Task tool (single message with three parallel Task calls):
   ```

   After:
   ```markdown
   Invoke ALL THREE subagents concurrently using Task tool (single message with three parallel Task calls, each with `model: "opus"`):
   ```

## Considerations

- **Cost vs quality tradeoff**: Using Opus for ticket creation prioritizes quality over cost, which is appropriate since tickets guide implementation work
- **Consistency**: All four agents in the ticket workflow (ticket-organizer + 3 child subagents) use the same model
- **Pattern alignment**: Follows the same pattern as `/story` command, which specifies model for each subagent invocation

## Final Report

Implemented using frontmatter `model` field (not Task tool parameters). Added `model: opus` to ticket-organizer for quality ticket writing. Added `model: haiku` to history-discoverer, source-discoverer, and ticket-moderator for cost-efficient discovery tasks.
