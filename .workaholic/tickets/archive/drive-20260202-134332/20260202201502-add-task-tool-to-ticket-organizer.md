---
created_at: 2026-02-02T20:15:02+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: dd1764c
category: Added
---

# Add Task Tool to ticket-organizer Agent

## Overview

Add the `Task` tool to `ticket-organizer.md` frontmatter tools list. The agent currently specifies `tools: Read, Write, Edit, Glob, Grep, Bash` but instructs to use Task tool for parallel subagent invocation (history-discoverer, source-discoverer, ticket-moderator). Without Task in the tools list, the agent falls back to using Bash with the `claude` CLI, which triggers permission prompts.

## Key Files

- `plugins/core/agents/ticket-organizer.md` - Add Task to tools list in frontmatter

## Related History

Historical tickets show the parallel subagent discovery feature was added to ticket-organizer, but the Task tool was not included in the tools list. The story-writer agent serves as the reference implementation with Task tool properly configured.

Past tickets that touched similar areas:

- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Added parallel Task tool invocations but missed adding Task to tools list
- [20260202182240-configure-opus-model-for-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202182240-configure-opus-model-for-ticket-organizer.md) - Configured model for ticket-organizer and child subagents (same file)

## Implementation Steps

1. **Update ticket-organizer.md frontmatter**:

   Line 4 - Change from:
   ```yaml
   tools: Read, Write, Edit, Glob, Grep, Bash
   ```

   To:
   ```yaml
   tools: Read, Write, Edit, Glob, Grep, Bash, Task
   ```

## Considerations

- **Reference implementation**: `story-writer.md` has `tools: Read, Write, Edit, Bash, Glob, Grep, Task` - demonstrates the pattern of including Task tool when the agent invokes subagents
- **Single line change**: This is a simple bugfix with minimal risk
- **Immediate effect**: After this fix, ticket-organizer will properly use Task tool for subagent invocation without permission prompts
