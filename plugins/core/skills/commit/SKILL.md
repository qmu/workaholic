---
name: commit
description: Safe commit workflow with multi-contributor awareness and structured message format.
skills:
  - format-commit-message
user-invocable: false
---

# Commit

Safe commit workflow with multi-contributor awareness. All commits in the Workaholic workflow should use this skill.

## Multi-Contributor Awareness

**Context**: You are not the only one working in this repository. Multiple developers and agents may have uncommitted changes in the working directory.

Before committing:

1. **Run pre-flight check** to understand what will be committed
2. **Review staged changes** to ensure only intended files are included
3. **Identify unintended changes** that may belong to other contributors
4. **Ask user if uncertain** about whether to include changes

## Usage

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "<title>" "<motivation>" "<ux-change>" "<arch-change>" [files...]
```

### Parameters

- `title` - Commit title (present-tense verb, 50 chars max)
- `motivation` - Why this change was needed (from ticket Overview)
- `ux-change` - What users will experience differently (or "None")
- `arch-change` - What developers need to know (or "None")
- `files...` - Optional: specific files to stage (if omitted, stages all tracked changes)

### Staging Behavior

- If files are specified: stages only those files
- If no files specified: stages all modified tracked files (`git add -u`)
- **Never uses `git add -A`** to avoid accidentally staging untracked files from other contributors

## Pre-Commit Checks

The commit script performs safety checks:

1. **Verify branch exists** - Cannot commit in detached HEAD state
2. **Check for staged changes** - Warns if nothing to commit
3. **Review what will be committed** - Shows diff summary before proceeding

## Message Format

Follow the preloaded **format-commit-message** skill:

```
<title>

Motivation: <why this change was needed>

UX Change: <what changed for the user>

Arch Change: <what changed for the developer>

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Examples

### Implementation commit (with specific files)

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "Add session-based authentication" \
  "Users needed persistent login state across browser sessions" \
  "New 'Remember me' checkbox on login form" \
  "Added SessionManager class and session middleware" \
  src/auth/session.ts src/middleware/auth.ts
```

### Archive commit (stage all changes)

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "Archive ticket: add-authentication" \
  "" \
  "None" \
  "None"
```

### Abandonment commit

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "Abandon: add-authentication" \
  "Implementation proved unworkable due to API limitations" \
  "None" \
  "Ticket moved to abandoned with failure analysis"
```
