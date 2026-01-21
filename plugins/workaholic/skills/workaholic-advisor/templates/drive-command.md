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

#### 2.3 Update Documentation

Update `doc/specs/` to reflect the changes:

- Read changes to understand what was modified
- Create files if they don't exist (generate from codebase analysis)
- Only update sections relevant to the current changes
- Update `README.md` with links to all documents

**Index:**

- `README.md` - Links to all documentation (user and developer)

**User Documentation:**

- `GETTING_STARTED.md` - Quick start, installation, first steps
- `USER_GUIDE.md` - Complete usage instructions, workflows
- `FAQ.md` - Common questions and answers

**Developer Documentation:**

- `FEATURES.md` - Feature catalog by category
- `ARCHITECTURE.md` - System design, components, data flow
- `NFR.md` - Performance, scalability, reliability
- `API.md` - Interfaces, contracts, endpoints
- `DATA_MODEL.md` - Data structures, schemas
- `CONFIGURATION.md` - Settings, environment variables
- `SECURITY.md` - Auth, permissions, vulnerabilities
- `TESTING.md` - Test strategy, coverage
- `DEPENDENCIES.md` - External libraries, requirements

**README.md format:**

```markdown
# Documentation

## User Documentation

- [Getting Started](GETTING_STARTED.md) - Quick start, installation, first steps
- [User Guide](USER_GUIDE.md) - Complete usage instructions, workflows
- [FAQ](FAQ.md) - Common questions and answers

## Developer Documentation

- [Features](FEATURES.md) - Feature catalog by category
- [Architecture](ARCHITECTURE.md) - System design, components, data flow
- [NFR](NFR.md) - Performance, scalability, reliability
- [API](API.md) - Interfaces, contracts, endpoints
- [Data Model](DATA_MODEL.md) - Data structures, schemas
- [Configuration](CONFIGURATION.md) - Settings, environment variables
- [Security](SECURITY.md) - Auth, permissions, vulnerabilities
- [Testing](TESTING.md) - Test strategy, coverage
- [Dependencies](DEPENDENCIES.md) - External libraries, requirements
```

#### 2.4 Ask User to Review Implementation

- **STOP and ask the user to review the implementation before proceeding**
- Show a summary of changes made (including doc updates)
- Use AskUserQuestion tool to confirm:
  - "Approve" - implementation is correct, proceed to commit
  - "Needs changes" - user will provide feedback to fix
- Do NOT proceed to commit until user explicitly approves
- If user requests changes:
  1. **Update the ticket file first** - add/modify steps based on feedback
  2. Then implement the changes
  3. Ask for review again
- This ensures the ticket always reflects the final implementation

#### 2.5 Commit and Archive Using Skill

After user approves, run the archive-ticket skill which handles everything:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  <ticket-path> \
  "<commit-message>" \
  <repo-url> \
  [modified-files...]
```

Example:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  doc/tickets/20260115-feature.md \
  "Add new feature for user authentication" \
  https://github.com/org/repo \
  src/auth.ts src/login.tsx
```

The script handles:

1. Format modified files with prettier
2. Archive ticket to `doc/tickets/archive/<branch>/`
3. Create/update branch CHANGELOG
4. Stage all changes and commit
5. Add commit hash to CHANGELOG (via amend)

**Commit Message Rules**:

- NO prefixes (no `[feat]`, `fix:`, etc.)
- Start with present-tense verb (Add, Update, Fix, Remove, Refactor)
- Focus on **WHY** the change was made
- Keep title concise (50 chars or less)

#### 2.6 Ask Before Next Ticket

- Show remaining tickets count
- Use AskUserQuestion to confirm:
  - "Continue" - proceed with next ticket
  - "Stop" - pause here
- **NEVER auto-continue** - always wait for explicit confirmation
- Repeat steps 2.1 through 2.5 only after user confirms

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

        Implementation complete. Changes made:
        - Modified src/foo.ts (added function X)
        - Updated src/bar.ts (fixed Y)

        Do you approve this implementation?
        [Approve / Needs changes]

User:   Approve

Claude: [creates commit, archives ticket]

        Remaining tickets (2):
        1. doc/tickets/20260113-feature-b.md
        2. doc/tickets/20260113-feature-c.md

        Continue with next ticket?
        [Continue / Stop]

User:   Continue

Claude: Starting with 20260113-feature-b.md...
```

## Notes

- Each ticket gets its own commit - do not batch multiple tickets
- If implementation fails, stop and report the error
- **ALWAYS require user confirmation** - never skip approval steps, even after interruption/resume
- After any interruption, re-ask for confirmation before proceeding
