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

#### 2.5 Commit and Archive Using Skill

After user approves, run the archive-ticket skill which handles everything:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  <spec-path> \
  "<commit-message>" \
  <repo-url> \
  [modified-files...]
```

Example:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  doc/specs/20260115-feature.md \
  "Add new feature for user authentication" \
  https://github.com/org/repo \
  src/auth.ts src/login.tsx
```

The script handles:
1. Format modified files with prettier
2. Archive spec to `doc/specs/archive/<branch>/`
3. Create/update branch CHANGELOG
4. Stage all changes and commit
5. Add commit hash to CHANGELOG (via amend)

**Commit Message Rules**:
- NO prefixes (no `[feat]`, `fix:`, etc.)
- Start with present-tense verb (Add, Update, Fix, Remove, Refactor)
- Focus on **WHY** the change was made
- Keep title concise (50 chars or less)

#### 2.6 Re-check Specs Queue Before Next

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

#### 2.7 Move to Next Spec

- Only if user confirms to continue, proceed to the next spec in the list
- Repeat steps 2.1 through 2.6

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
