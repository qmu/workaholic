---
name: drive
description: Implement tickets from doc/tickets/ one by one, commit each, and archive.
---

# Drive

Implement all tickets stored in `doc/tickets/` from top to bottom, committing and archiving each one before moving to the next.

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
- If user requests changes, make them and ask for review again

#### 2.5 Commit Following /commit Manner

- Run `git status` to see all changes
- Run `npx prettier --write` on modified files if needed
- Group changes into a single logical commit for the ticket
- **Commit Message Rules**:
  - NO prefixes (no `[feat]`, `fix:`, etc.)
  - Start with present-tense verb (Add, Update, Fix, Remove, Refactor)
  - Focus on **WHY** the change was made
  - Keep title concise (50 chars or less)
  - Add body with context if needed

#### 2.6 Archive the Ticket and Update Branch CHANGELOG

- Get current branch name: `git branch --show-current`
- Create branch archive directory: `doc/tickets/archive/<branch-name>/`
- Move the ticket file to the branch archive
- **Update branch CHANGELOG**:
  - Create/update `doc/tickets/archive/<branch-name>/CHANGELOG.md`
  - Add entry for the implemented ticket under appropriate section (Added/Changed/Removed)
  - Format: `- <commit message> ([hash](commit-url)) - [ticket](ticket-filename.md)`
  - Include relative link to archived ticket file for GitHub viewing
  - Categorize by commit verb (Add→Added, Update/Fix→Changed, Remove→Removed)
- Include both the move and CHANGELOG update in the commit by amending:
  ```bash
  BRANCH=$(git branch --show-current)
  mkdir -p "doc/tickets/archive/${BRANCH}"
  mv "doc/tickets/<ticket-file>.md" "doc/tickets/archive/${BRANCH}/"
  # Update branch CHANGELOG.md (see format below)
  git add -A
  git commit --amend --no-edit
  ```

**Branch CHANGELOG format** (`doc/tickets/archive/<branch>/CHANGELOG.md`):

```markdown
# Branch Changelog

## Added

- New feature description ([abc1234](commit-url)) - [ticket](ticket-filename.md)

## Changed

- Modification description ([def5678](commit-url)) - [ticket](ticket-filename.md)

## Removed

- Removed item description ([ghi9012](commit-url)) - [ticket](ticket-filename.md)
```

Each entry includes a relative link to the archived ticket file for easy reference on GitHub.

#### 2.7 Move to Next Ticket

- Proceed to the next ticket in the list
- Repeat steps 2.1 through 2.6

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

        Starting with 20260113-feature-b.md...
        [continues with remaining tickets...]
```

## Notes

- Each ticket gets its own commit - do not batch multiple tickets
- If implementation fails, stop and report the error
