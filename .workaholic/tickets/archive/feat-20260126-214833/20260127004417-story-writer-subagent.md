---
created_at: 2026-01-27T00:44:17+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.1h
commit_hash: 4c83014
category: Changed
---

# Extract story-writer as subagent from pull-request command

## Overview

The story generation logic in `plugins/core/commands/pull-request.md` (step 5) should be extracted into a separate subagent at `plugins/core/agents/story-writer.md`. This follows the same pattern as the recent sync-workaholic refactoring, allowing story generation to run in its own context window and keeping the main conversation focused on PR creation orchestration.

## Key Files

- `plugins/core/commands/pull-request.md` - Current command containing story generation logic
- `plugins/core/agents/story-writer.md` - New subagent to create
- `plugins/core/agents/spec-writer.md` - Reference for agent structure

## Implementation Steps

1. **Create story-writer subagent** at `plugins/core/agents/story-writer.md`:
   - Extract step 5 content (story generation) from pull-request.md
   - Include: gathering source data, calculating metrics, creating story file, writing guidelines
   - Tools: Read, Write, Edit, Bash, Glob, Grep, Task (for invoking performance-analyst)
   - Keep the performance-analyst invocation as part of story-writer's responsibilities

2. **Update pull-request command**:
   - Replace step 5 with invocation of story-writer subagent via Task tool
   - Pass branch name as context to the subagent
   - Subagent handles: reading archived tickets, calculating metrics, generating story file

3. **Story-writer subagent responsibilities**:
   - Read archived tickets from `.workaholic/tickets/archive/<branch-name>/`
   - Extract frontmatter (commit_hash, category) and content (Overview, Final Report)
   - Calculate performance metrics (commits, duration, velocity)
   - Create story file with YAML frontmatter
   - Generate all 7 sections of the story
   - Invoke performance-analyst for Decision Review section
   - Update `.workaholic/stories/README.md`

## Considerations

- **Context preservation**: Story generation reads many files; isolating it preserves main PR flow context
- **Subagent chaining**: story-writer invokes performance-analyst subagent internally
- **Single responsibility**: pull-request command focuses on orchestration; story-writer focuses on content generation
- **Backward compatibility**: `/pull-request` command still works, just delegates story generation

## Final Report

Development completed as planned.
