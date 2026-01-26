---
created_at: 2026-01-27T00:56:01+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.1h
commit_hash: 4ee763d
category: Changed
---

# Extract pr-creator subagent from pull-request command

## Overview

The pull-request command contains PR creation/update logic (steps 6-8 and "Creating vs Updating" section) that should be extracted into a dedicated `pr-creator` subagent. This follows the pattern of extracting specialized logic into focused subagents, keeping the pull-request command as an orchestrator.

The pr-creator subagent handles:
- Checking if PR already exists for the branch
- Reading story file and stripping YAML frontmatter
- Deriving PR title from Summary section
- Creating new PR or updating existing PR via `gh` CLI
- Returning the PR URL

## Key Files

- `plugins/core/commands/pull-request.md` - Current command to be simplified
- `plugins/core/agents/pr-creator.md` - New subagent to create
- `plugins/core/agents/story-writer.md` - Reference for agent pattern

## Implementation Steps

1. **Create pr-creator subagent** at `plugins/core/agents/pr-creator.md`:
   - Tools: Read, Bash, Glob
   - Input: branch name, base branch
   - Check if PR exists: `gh pr list --head <branch> --json number,title,url`
   - Read story file: `.workaholic/stories/<branch-name>.md`
   - Strip YAML frontmatter (everything between `---` delimiters)
   - Derive title from Summary section:
     - Single change: use as-is
     - Multiple changes: first change + "etc"
   - Create or update PR using `gh pr create` or `gh pr edit`
   - Return PR URL (required output)

2. **Update pull-request command** to invoke pr-creator:
   - Remove steps 6-8 inline logic
   - Remove "Creating vs Updating" section details
   - Add pr-creator subagent invocation after formatting step
   - Pass branch name and base branch to subagent
   - Display PR URL from subagent result (mandatory completion output)

3. **Simplify pull-request completion section**:
   - Keep "Completion Output (MANDATORY)" section
   - Reference that pr-creator returns the URL to display

## Considerations

- **Sequential execution**: pr-creator must run AFTER story-writer since it reads the story file
- **Single responsibility**: pr-creator only handles GitHub PR operations, not documentation generation
- **Error handling**: If PR creation fails, subagent should return error details for display
- **URL return**: The subagent MUST return the PR URL as its primary output for mandatory display

## Final Report

Development completed as planned.
