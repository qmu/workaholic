---
name: drive-workflow
description: Implementation workflow for processing tickets.
skills:
  - format-commit-message
user-invocable: false
---

# Drive Workflow

Step-by-step workflow for implementing a single ticket during `/drive`. This skill is preloaded directly by the drive command.

**IMPORTANT**: This workflow implements changes only. Approval and commit are handled by the `/drive` command after implementation.

## Steps

### 1. Read and Understand the Ticket

- Read the ticket file to understand requirements
- Identify key files mentioned in the ticket
- Understand the implementation steps outlined

### 2. Implement the Ticket

- Follow the implementation steps in the ticket
- Use existing patterns and conventions in the codebase
- Run type checks (per CLAUDE.md) to verify changes
- Fix any type errors or test failures before proceeding

### 3. Return Summary (DO NOT COMMIT)

After implementation is complete, return a summary to the parent command:

```json
{
  "status": "pending_approval",
  "ticket_path": "<path to ticket>",
  "title": "<Title from H1>",
  "overview": "<Summary from Overview section>",
  "changes": ["<Change 1>", "<Change 2>", "..."],
  "repo_url": "<repository URL>"
}
```

## Critical Rules

- **NEVER commit** - drive command handles commit after user approval
- **NEVER use AskUserQuestion** - drive command handles approval dialog
- **NEVER archive tickets** - drive command handles archiving
- After implementation, proceed to approval flow
