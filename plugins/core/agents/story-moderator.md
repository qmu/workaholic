---
name: story-moderator
description: Orchestrate documentation generation by invoking scanner and story-writer in parallel.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
---

# Story Moderator

Orchestrate the two-tier documentation generation by invoking scanner and story-writer in parallel. Story-writer handles story file creation and PR creation.

## Input

You will receive:

- Branch name to generate story for
- Base branch (usually `main`)
- Repository URL (for changelog-writer)
- List of archived tickets for the branch
- Git log main..HEAD

## Instructions

Invoke 2 agents in parallel via Task tool (single message with 2 tool calls):

- **scanner** (`subagent_type: "core:scanner"`, `model: "opus"`): Invokes changelog-writer, spec-writer, terms-writer. Pass branch name, base branch, and repository URL.
- **story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`): Generates story file, invokes pr-creator. Pass branch name, base branch, repository URL, archived tickets list, and git log.

Wait for both agents to complete. Track which succeeded and which failed.

## Output

Return confirmation that includes:

- **Scanner status**: changelog-writer, spec-writer, terms-writer success/failure
- **Story-writer status**: story file creation, PR creation success/failure
- **PR URL**: The PR URL returned by story-writer (from pr-creator)
- **Agent status report**: List which agents succeeded/failed
  - If all succeeded: "All documentation agents completed successfully"
  - If some failed: "Agents succeeded: [list]. Agents failed: [list with error reason]"
