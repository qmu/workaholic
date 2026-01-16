---
name: drive
description: Implement specs from doc/specs/ one by one, commit each, and archive.
---

# Drive

Implement all specs stored in `doc/specs/` from top to bottom, committing and archiving each one before moving to the next.

## Instructions

### 1. List and Sort Specs

```bash
ls -1 doc/specs/*.md 2>/dev/null | sort
```

- If no specs found, inform the user and stop
- Process specs in alphabetical/chronological order (YYYYMMDD prefix ensures chronological)

### 2. For Each Spec (Top to Bottom)

#### 2.1 Read and Understand the Spec

- Read the spec file to understand requirements
- Identify key files mentioned in the spec
- Understand the implementation steps outlined

#### 2.2 Implement the Spec

- Follow the implementation steps in the spec
- Use existing patterns and conventions in the codebase
- Run type checks (per CLAUDE.md) to verify changes
- Fix any type errors or test failures before proceeding

#### 2.3 Ask User to Review Implementation

- **STOP and ask the user to review the implementation before proceeding**
- Show a summary of changes made
- Use AskUserQuestion tool to confirm:
  - "Approve" - implementation is correct, proceed to commit step
  - "Needs changes" - user will provide feedback to fix
- Do NOT proceed to commit until user explicitly approves the implementation
- If user requests changes, make them and ask for review again

#### 2.4 Ask User to Approve Commit

- After user approves the implementation, ask for **separate commit approval**:
  - "Commit" - create commit and archive spec
  - "Wait" - hold off, user may want to make additional changes first
- This two-step process (approve implementation → approve commit) prevents accidental commits
- Only proceed to commit when user explicitly says "Commit" or equivalent

#### 2.5 Commit Following /commit Manner

- Run `git status` to see all changes
- Run `npx prettier --write` on modified files if needed
- Group changes into a single logical commit for the spec
- **Commit Message Rules**:
  - NO prefixes (no `[feat]`, `fix:`, etc.)
  - Start with present-tense verb (Add, Update, Fix, Remove, Refactor)
  - Focus on **WHY** the change was made
  - Keep title concise (50 chars or less)
  - Add body with context if needed

#### 2.6 Archive the Spec and Update Branch CHANGELOG

- Get current branch name: `git branch --show-current`
- Create branch archive directory: `doc/specs/archive/<branch-name>/`
- Move the spec file to the branch archive
- **Update branch CHANGELOG**:
  - Create/update `doc/specs/archive/<branch-name>/CHANGELOG.md`
  - Add entry for the implemented spec under appropriate section (Added/Changed/Removed)
  - Format: `- <commit message> ([hash](commit-url)) - [spec](spec-filename.md)`
  - Include relative link to archived spec file for GitHub viewing
  - Categorize by commit verb (Add→Added, Update/Fix→Changed, Remove→Removed)
- Include both the move and CHANGELOG update in the commit by amending:
  ```bash
  BRANCH=$(git branch --show-current)
  mkdir -p "doc/specs/archive/${BRANCH}"
  mv "doc/specs/<spec-file>.md" "doc/specs/archive/${BRANCH}/"
  # Update branch CHANGELOG.md (see format below)
  git add -A
  git commit --amend --no-edit
  ```

**Branch CHANGELOG format** (`doc/specs/archive/<branch>/CHANGELOG.md`):

```markdown
# Branch Changelog

## Added

- New feature description ([abc1234](commit-url)) - [spec](spec-filename.md)

## Changed

- Modification description ([def5678](commit-url)) - [spec](spec-filename.md)

## Removed

- Removed item description ([ghi9012](commit-url)) - [spec](spec-filename.md)
```

Each entry includes a relative link to the archived spec file for easy reference on GitHub.

#### 2.7 Re-check Specs Queue Before Next

- After archiving, re-scan `doc/specs/` for any new or remaining spec files:
  ```bash
  ls -1 doc/specs/*.md 2>/dev/null | sort
  ```
- Display the remaining specs queue with count:
  ```
  Remaining specs in queue (N):
  1. doc/specs/20260113-feature-a.md
  2. doc/specs/20260113-feature-b.md
  ```
- Ask user to confirm before proceeding:
  - "Yes" / "Continue" - proceed with next spec
  - "Stop" / "Pause" - stop here, user can resume later
- This ensures user has control over the pace and can pause at any time

#### 2.8 Move to Next Spec

- Only if user confirms to continue, proceed to the next spec in the list
- Repeat steps 2.1 through 2.7

### 3. Completion

- After all specs are implemented, summarize what was done
- List all commits created
- Inform user that all specs have been processed

## Example Workflow

```
Claude: Found 3 specs to implement:
        1. doc/specs/20260113-feature-a.md
        2. doc/specs/20260113-feature-b.md
        3. doc/specs/20260113-feature-c.md

        Starting with 20260113-feature-a.md...
        [implements feature-a]

        Implementation complete. Changes made:
        - Modified src/foo.ts (added function X)
        - Updated src/bar.ts (fixed Y)

        Do you approve this implementation?
        [Approve / Needs changes]

User:   Approve

Claude: Implementation approved. Ready to commit?
        [Commit / Wait]

User:   Commit

Claude: [creates commit, archives spec]

        Remaining specs in queue (2):
        1. doc/specs/20260113-feature-b.md
        2. doc/specs/20260113-feature-c.md

        Proceed with next spec?
        [Yes / Stop here]

User:   Yes

Claude: Starting with 20260113-feature-b.md...
        [continues...]
```

## Notes

- Each spec gets its own commit - do not batch multiple specs
- **Two-step approval required**: first approve implementation, then approve commit
- **Always ask before proceeding to next spec** - never auto-continue without confirmation
- If implementation fails, stop and report the error
