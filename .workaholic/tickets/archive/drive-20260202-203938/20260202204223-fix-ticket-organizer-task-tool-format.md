---
created_at: 2026-02-02T20:42:23+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: a965057
category: Changed
---

# Fix ticket-organizer Subagent Invocation Format

## Overview

The ticket-organizer agent instructions use code block format to specify Task tool parameters (e.g., `subagent_type: "core:history-discoverer"`). This format causes the model to misinterpret the instructions as CLI flags and attempt to run `claude --print ... --subagent-type` via Bash instead of using the native Task tool. Convert to prose format matching story-writer.md pattern.

## Key Files

- `plugins/core/agents/ticket-organizer.md` - Lines 44-63 with code block format Task tool instructions

## Related History

Previous tickets established the current ticket-organizer architecture and added Task tool, but the invocation format was not updated to match working patterns in other agents.

Past tickets that touched similar areas:

- [20260202201502-add-task-tool-to-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202201502-add-task-tool-to-ticket-organizer.md) - Added Task tool to ticket-organizer tools list (same file)
- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Introduced the problematic code block format for Task tool invocations

## Implementation Steps

1. **Update ticket-organizer.md** - Convert code block format to prose format in the "Parallel Discovery" section (step 2).

   **Before (lines 44-63):**
   ```markdown
   **2-A. History Discovery** (via Task tool):
   ```
   subagent_type: "core:history-discoverer"
   prompt: "Find related tickets for keywords: <keyword1> <keyword2> ..."
   ```
   - Receives JSON: summary, tickets list, match reasons

   **2-B. Source Discovery** (via Task tool):
   ```
   subagent_type: "core:source-discoverer"
   prompt: "Find source files for: <description>"
   ```
   - Receives JSON: summary, files list, code flow

   **2-C. Ticket Moderation** (via Task tool):
   ```
   subagent_type: "core:ticket-moderator"
   prompt: "Analyze for duplicates/merge/split. Keywords: <keywords>. Description: <description>"
   ```
   - Receives JSON: status, matches list, recommendation
   ```

   **After (prose format matching story-writer.md):**
   ```markdown
   - **history-discoverer** (`subagent_type: "core:history-discoverer"`): Find related tickets. Pass keywords extracted from request. Receives JSON with summary, tickets list, match reasons.
   - **source-discoverer** (`subagent_type: "core:source-discoverer"`): Find relevant source files. Pass full description. Receives JSON with summary, files list, code flow.
   - **ticket-moderator** (`subagent_type: "core:ticket-moderator"`): Analyze for duplicates/merge/split. Pass keywords and description. Receives JSON with status, matches list, recommendation.
   ```

## Considerations

- **Reference implementation**: story-writer.md uses prose format with inline backticks for `subagent_type` (lines 43-49), which works correctly
- **Root cause**: Code blocks look like pseudo-code or CLI flag documentation, causing model confusion about whether to use Task tool natively or invoke claude CLI
- **Simple format change**: Content remains the same; only presentation format changes from code blocks to prose bullet points

## Final Report

Converted the "Parallel Discovery" section from code block format to prose bullet point format. Each subagent is now documented with inline backticks for `subagent_type`, matching the working pattern in story-writer.md.
