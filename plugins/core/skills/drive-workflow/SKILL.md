---
name: drive-workflow
description: Implementation workflow for processing tickets.
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

**STOP and ask the user to review the implementation before proceeding.**

Show ticket context to help user understand what they're reviewing:

- Display the ticket title (H1 heading from ticket file)
- Include a brief summary (first 1-2 sentences from Overview section)
- Show a summary of changes made

Use AskUserQuestion tool to confirm:

- "Approve" - implementation is correct, proceed to commit and continue to next ticket
- "Approve and stop" - implementation is correct, commit this ticket but stop driving
- "Needs changes" - user will provide feedback to fix

**Do NOT proceed to commit until user explicitly approves.**

If user requests changes:

1. **Update the ticket file first** - add/modify steps based on feedback
2. Then implement the changes
3. Ask for review again

This ensures the ticket always reflects the final implementation.

#### Approval Prompt Format

```
**Ticket: <Title from H1>**
<Summary from Overview section - first 1-2 sentences>

Implementation complete. Changes made:
- <Change 1>
- <Change 2>

Do you approve this implementation?
[Approve / Approve and stop / Needs changes]
```

### 4. Update Effort and Write Final Report

After user approves:

1. **Update the `effort` field** in the ticket's YAML frontmatter with actual time spent (e.g., 0.1h, 0.25h, 0.5h, 1h, 2h). Estimate based on implementation complexity.

2. **Append a "## Final Report" section** to the ticket file.

**If no changes were requested:**

```markdown
## Final Report

Development completed as planned.
```

**If user requested changes during review:**

```markdown
## Final Report

Implementation deviated from original plan:

- **Change**: <what was changed>
  **Reason**: <why the user requested this change>
```

This creates a historical record of decisions made during implementation.

### 5. Commit and Archive Using Skill

After writing the final report, run the archive-ticket skill which handles everything:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  <ticket-path> \
  "<commit-message>" \
  <repo-url> \
  "<description>" \
  [modified-files...]
```

**IMPORTANT**: Always use the script. Never manually move tickets or create changelogs.

**Note**: The archive script uses `git add -A`, which includes:

- All implementation changes
- The archived ticket file
- Any uncommitted ticket files in `.workaholic/tickets/`
- CHANGELOG updates

This means newly created tickets are automatically included in drive commits.

### After Committing

- If user selected "Approve": automatically proceed to the next ticket without asking for confirmation
- If user selected "Approve and stop": stop driving and report how many tickets remain (e.g., "Stopped. 2 tickets remaining in queue.")

## Commit Message Rules

- NO prefixes (no `[feat]`, `fix:`, etc.)
- Start with present-tense verb (Add, Update, Fix, Remove, Refactor)
- Focus on **WHAT** changed in the title
- Keep title concise (50 chars or less)

## Description Rules

- 1-2 sentences explaining the motivation behind the change
- Capture the "why" from the ticket's Overview section
- This appears in CHANGELOG and helps generate meaningful PR descriptions
