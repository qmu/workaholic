---
name: drive
description: Implement tickets from doc/tickets/ one by one, commit each, and archive.
---

# Drive

Implement all tickets stored in `doc/tickets/` from top to bottom, committing and archiving each one before moving to the next.

## Icebox Mode

If `$ARGUMENT` contains "icebox":

1. List tickets in `doc/tickets/icebox/`
2. Ask user which ticket to retrieve
3. Move selected ticket to `doc/tickets/`
4. Implement that ticket (steps 2.1-2.5)
5. **ALWAYS ask confirmation** before proceeding to next ticket

## Instructions

### 1. List and Sort Tickets

```bash
ls -1 doc/tickets/*.md 2>/dev/null | sort
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
  - "Approve" - implementation is correct, proceed to commit
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
[Approve / Needs changes]
```

#### 2.4 Write Final Report

After user approves, append a "## Final Report" section to the ticket file.

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
  doc/tickets/20260115-feature.md \
  "Add new feature for user authentication" \
  https://github.com/org/repo \
  "Enables users to log in with session-based authentication, addressing the need for secure access control." \
  src/auth.ts src/login.tsx
```

**IMPORTANT**: Always use the script. Never manually move tickets or create changelogs.

**Commit Message Rules**:

- NO prefixes (no `[feat]`, `fix:`, etc.)
- Start with present-tense verb (Add, Update, Fix, Remove, Refactor)
- Focus on **WHY** the change was made
- Keep title concise (50 chars or less)

**Description Rules**:

- 1-2 sentences explaining the motivation behind the change
- Capture the "why" from the ticket's Overview section
- This appears in CHANGELOG and helps generate meaningful PR descriptions

After committing, automatically proceed to the next ticket without asking for confirmation.

### 3. Completion

- After all tickets are implemented, summarize what was done
- List all commits created
- Inform user that all tickets have been processed

## Example Workflow

```
Claude: Found 3 tickets to implement:
        1. doc/tickets/20260113-feature-a.md
        2. doc/tickets/20260113-feature-b.md
        3. doc/tickets/20260113-feature-c.md

        Starting with 20260113-feature-a.md...
        [implements feature-a]

        **Ticket: Add User Authentication**
        Implement user authentication with session-based login and logout.

        Implementation complete. Changes made:
        - Modified src/foo.ts (added function X)
        - Updated src/bar.ts (fixed Y)

        Do you approve this implementation?
        [Approve / Needs changes]

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
- User can stop by responding "Needs changes" at approval and requesting to pause
