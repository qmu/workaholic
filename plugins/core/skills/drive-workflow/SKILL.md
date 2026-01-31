---
name: drive-workflow
description: Implementation workflow for processing tickets.
skills:
  - format-commit-message
user-invocable: false
---

# Drive Workflow

Step-by-step workflow for implementing a single ticket during `/drive`.

**IMPORTANT**: This workflow implements changes only. Approval and commit are handled by the parent `/drive` command.

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

- **NEVER commit** - parent command handles commit after user approval
- **NEVER use AskUserQuestion** - parent command handles approval dialog
- **NEVER archive tickets** - parent command handles archiving
- Return implementation summary and stop
