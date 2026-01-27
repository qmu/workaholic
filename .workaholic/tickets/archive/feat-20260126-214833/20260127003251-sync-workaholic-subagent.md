---
created_at: 2026-01-27T00:32:51+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: d4e6a07
category: Changed
---

# Convert sync-workaholic command to subagent

## Overview

The `/sync-workaholic` command should be converted from a command (`plugins/core/commands/sync-workaholic.md`) to a subagent (`plugins/core/agents/sync-workaholic.md`). This allows the sync process to run in its own context window, preserving the main conversation context while performing extensive codebase exploration and documentation updates. The `/sync-workaholic` command will become an alias that invokes the subagent.

## Key Files

- `plugins/core/commands/sync-workaholic.md` - Current command to be removed
- `plugins/core/agents/sync-workaholic.md` - New subagent to create
- `plugins/core/agents/performance-analyst.md` - Reference for agent frontmatter format

## Implementation Steps

1. **Create spec-writer subagent** at `plugins/core/agents/spec-writer.md`:
   - Extract spec-related instructions (steps 1-5, 7-8) from sync-workaholic.md
   - Tools: Read, Write, Edit, Bash, Glob, Grep
   - Focus on `.workaholic/specs/` updates

2. **Create terminology-writer subagent** at `plugins/core/agents/terminology-writer.md`:
   - Extract terminology-related instructions (steps 1-3, 6-8) from sync-workaholic.md
   - Tools: Read, Write, Edit, Bash, Glob, Grep
   - Focus on `.workaholic/terminology/` updates

3. **Update the command to orchestrate both subagents**:
   - Keep `plugins/core/commands/sync-workaholic.md` as orchestrator
   - Invoke both subagents in parallel via Task tool
   - Summarize combined results

4. **Remove single sync-workaholic agent**:
   - Delete `plugins/core/agents/sync-workaholic.md` (replaced by two specialized agents)

## Considerations

- **Context preservation**: Running as subagents keeps extensive file reads out of main conversation
- **Tool access**: Both agents need write access (Write, Edit) to update documentation files
- **Model choice**: Using `inherit` ensures consistency with the parent conversation's model
- **Backward compatibility**: The `/sync-workaholic` command still works, just orchestrates both agents
- **Parallel execution**: Both agents can run simultaneously for faster completion
- **Separation of concerns**: Spec updates and terminology updates are independent tasks

## Final Report

Implementation deviated from original plan:

- **Change**: Split into two specialized subagents instead of one
  **Reason**: User requested separation into spec-writer and terminology-writer for better separation of concerns

Created files:
- `plugins/core/agents/spec-writer.md` - Handles `.workaholic/specs/` updates
- `plugins/core/agents/terminology-writer.md` - Handles `.workaholic/terminology/` updates

Updated files:
- `plugins/core/commands/sync-workaholic.md` - Now orchestrates both subagents in parallel
