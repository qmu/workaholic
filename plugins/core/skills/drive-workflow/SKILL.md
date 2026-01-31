---
name: drive-workflow
description: Implementation workflow for processing tickets.
skills:
  - request-approval
  - write-final-report
  - handle-abandon
  - format-commit-message
user-invocable: false
---

# Drive Workflow

Step-by-step workflow for implementing a single ticket during `/drive`.

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

### 3. Ask User to Review Implementation

Follow the preloaded **request-approval** skill.

### 4. Update Effort and Write Final Report

Follow the preloaded **write-final-report** skill.

### 5. Commit and Archive Using Skill

```bash
bash .claude/skills/archive-ticket/sh/archive.sh \
  <ticket-path> "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
```

Follow the preloaded **format-commit-message** skill for message format.

**CRITICAL**: The archive script is the ONLY way to archive tickets.

#### Prohibited Actions

- NEVER use `mv` or `git mv` to move ticket files
- NEVER create directories like `done/`, `completed/`, `finished/`
- NEVER manually update CHANGELOG files
- NEVER manually set `commit_hash` or `category` frontmatter fields

### After Committing

- **Approve**: Proceed to next ticket automatically
- **Approve and stop**: Stop driving, report tickets remaining

### If User Selects "Abandon"

Follow the preloaded **handle-abandon** skill.
