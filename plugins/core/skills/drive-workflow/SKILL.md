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

### 2. Apply Patches (if present)

If the ticket has a "## Patches" section:

1. For each patch in the section:
   - Write patch content to a temporary file
   - Validate with `git apply --check <patch-file>`
   - If valid, apply with `git apply <patch-file>`
   - Clean up temporary file
2. Report which patches applied successfully
3. For failed patches, note them and proceed with manual implementation

If no Patches section exists, skip to step 3.

### 3. Implement the Ticket

- Follow the implementation steps in the ticket
- Use existing patterns and conventions in the codebase
- For areas where patches applied, verify and adjust as needed
- Run type checks (per CLAUDE.md) to verify changes
- Fix any type errors or test failures before proceeding

### 4. Return Summary (DO NOT COMMIT)

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

## Prohibited Operations

**Context**: This repository may have multiple contributors (developers, other agents) working concurrently. Uncommitted changes in the working directory may not belong to you.

The following destructive git commands are **NEVER** allowed during implementation:

| Command | Risk | Alternative |
|---------|------|-------------|
| `git clean` | Deletes untracked files that may belong to other contributors | Do not use |
| `git checkout .` | Discards all uncommitted changes including others' work | Use targeted checkout for specific files |
| `git restore .` | Discards all uncommitted changes including others' work | Reserved for abandonment flow only |
| `git reset --hard` | Discards all uncommitted changes and resets HEAD | Do not use |
| `git stash drop` | Permanently deletes stashed changes | Only with explicit user request |

**Rationale**: You are not the only one working in this repository. Destructive operations affect everyone's uncommitted work, not just your own implementation. Always check `git status` before any operation that discards changes, and be considerate of work that may not be yours.

If an implementation requires discarding changes, use targeted commands that affect only specific files you modified, or request user approval first.
