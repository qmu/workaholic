---
name: drive
description: Implement tickets from .work/tickets/ one by one, commit each, and archive.
---

# Drive

Implement all tickets stored in `.work/tickets/` from top to bottom, committing and archiving each one before moving to the next.

## Icebox Mode

If `$ARGUMENT` contains "icebox":

1. List tickets in `.work/tickets/icebox/`
2. Ask user which ticket to retrieve
3. Move selected ticket to `.work/tickets/`
4. Implement that ticket (steps 2.1-2.5)
5. **ALWAYS ask confirmation** before proceeding to next ticket

## Instructions

### 1. List and Sort Tickets

```bash
ls -1 .work/tickets/*.md 2>/dev/null | sort
```

- If no tickets found, inform the user and stop
- Process tickets in alphabetical/chronological order (YYYYMMDD prefix ensures chronological)

### 2. For Each Ticket (Top to Bottom)

#### 2.1 Read and Understand the Ticket

- Read the ticket file to understand requirements
- Identify key files mentioned in the ticket
- Understand the implementation steps outlined

#### 2.2 Implement the Ticket

- Follow the implementation steps in the ticket
- Use existing patterns and conventions in the codebase
- Run type checks (per CLAUDE.md) to verify changes
- Fix any type errors or test failures before proceeding

#### 2.3 Ask User to Review Implementation

- **STOP and ask the user to review the implementation before proceeding**
- **Show ticket context** to help user understand what they're reviewing:
  - Display the ticket title (H1 heading from ticket file)
  - Include a brief summary (first 1-2 sentences from Overview section)
- Show a summary of changes made
- Use AskUserQuestion tool to confirm:
  - "Approve" - implementation is correct, proceed to commit and continue to next ticket
  - "Approve and stop" - implementation is correct, commit this ticket but stop driving
  - "Needs changes" - user will provide feedback to fix
- Do NOT proceed to commit until user explicitly approves
- If user requests changes:
  1. **Update the ticket file first** - add/modify steps based on feedback
  2. Then implement the changes
  3. Ask for review again
- This ensures the ticket always reflects the final implementation

**Approval prompt format:**

```
**Ticket: <Title from H1>**
<Summary from Overview section - first 1-2 sentences>

Implementation complete. Changes made:
- <Change 1>
- <Change 2>

Do you approve this implementation?
[Approve / Approve and stop / Needs changes]
```

#### 2.4 Update Effort and Write Final Report

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

#### 2.5 Commit and Archive Using Skill

After writing the final report, run the archive-ticket skill which handles everything:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  <ticket-path> \
  "<commit-message>" \
  <repo-url> \
  "<description>" \
  [modified-files...]
```

Example:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  .work/tickets/20260115-feature.md \
  "Add new feature for user authentication" \
  https://github.com/org/repo \
  "Enables users to log in with session-based authentication, addressing the need for secure access control." \
  src/auth.ts src/login.tsx
```

**IMPORTANT**: Always use the script. Never manually move tickets or create changelogs.

**Note**: The archive script uses `git add -A`, which includes:

- All implementation changes
- The archived ticket file
- Any uncommitted ticket files in `.work/tickets/`
- CHANGELOG updates

This means newly created tickets are automatically included in drive commits,
eliminating the need for separate "add tickets" commits.

**Commit Message Rules**:

- NO prefixes (no `[feat]`, `fix:`, etc.)
- Start with present-tense verb (Add, Update, Fix, Remove, Refactor)
- Focus on **WHY** the change was made
- Keep title concise (50 chars or less)

**Description Rules**:

- 1-2 sentences explaining the motivation behind the change
- Capture the "why" from the ticket's Overview section
- This appears in CHANGELOG and helps generate meaningful PR descriptions

After committing:

- If user selected "Approve": automatically proceed to the next ticket without asking for confirmation
- If user selected "Approve and stop": stop driving and report how many tickets remain (e.g., "Stopped. 2 tickets remaining in queue.")

### 3. Completion

- After all tickets are implemented, summarize what was done
- List all commits created
- Inform user that all tickets have been processed

## Example Workflow

```
Claude: Found 3 tickets to implement:
        1. .work/tickets/20260113-feature-a.md
        2. .work/tickets/20260113-feature-b.md
        3. .work/tickets/20260113-feature-c.md

        Starting with 20260113-feature-a.md...
        [implements feature-a]

        **Ticket: Add User Authentication**
        Implement user authentication with session-based login and logout.

        Implementation complete. Changes made:
        - Modified src/foo.ts (added function X)
        - Updated src/bar.ts (fixed Y)

        Do you approve this implementation?
        [Approve / Approve and stop / Needs changes]

User:   Approve

Claude: [creates commit, archives ticket]

        Starting with 20260113-feature-b.md...
```

## Notes

- Each ticket gets its own commit - do not batch multiple tickets
- If implementation fails, stop and report the error
- **Implementation approval (step 2.3) is mandatory** - never skip this step
- **Final report (step 2.4) is mandatory** - document what happened
- Between-ticket continuation is automatic - no confirmation needed
- User can stop cleanly by selecting "Approve and stop" at any approval prompt

## Critical Rules

**NEVER autonomously move tickets to icebox.** Moving tickets is a developer decision, not an AI decision.

If a ticket cannot be implemented (out of scope, too complex, blocked, or any other reason):

1. **Stop and ask the developer** using AskUserQuestion
2. Explain why implementation cannot proceed
3. Offer these options:
   - "Move to icebox" - Move ticket to `.work/tickets/icebox/` and continue to next
   - "Skip for now" - Leave ticket in queue, move to next ticket
   - "Abort drive" - Stop the drive session entirely

**Never commit ticket moves without explicit developer approval.**
