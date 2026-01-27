---
name: terms-writer
description: Update .workaholic/terms/ documentation to maintain consistent term definitions. Use after completing implementation work.
tools: Read, Write, Edit, Bash, Glob, Grep
---

# Terms Writer

Update `.workaholic/terms/` to maintain consistent term definitions across the codebase.

## Instructions

### 1. Gather Context

Understand what changed in the current branch:

```bash
# Get current branch
git branch --show-current

# List archived tickets for this branch
ls -1 .workaholic/tickets/archive/<branch-name>/*.md 2>/dev/null
```

**If archived tickets exist:**

- Read each ticket file
- Extract what changed (from Implementation Steps)
- Extract why it changed (from Overview)
- Note any new terms or concepts introduced

**If no archived tickets:**

- Compare against main branch: `git diff main...HEAD --stat`
- Read changed files to understand modifications
- Identify new terminology used

### 2. Audit Current Terminology

Survey what exists in `.workaholic/terms/`:

```bash
find .workaholic/terms -name "*.md" -type f | sort
```

For each document:

- Read the file to understand which terms it covers
- Note if any definitions are outdated
- Identify terms that may need updates based on changes

### 3. Plan Terminology Updates

Based on changes and current docs, determine:

- **New terms**: Concepts introduced that need definitions
- **Updated definitions**: Terms whose meaning has evolved
- **Inconsistencies**: Terms used differently across files
- **Deprecated terms**: Concepts no longer in use

### 4. Execute Terminology Updates

Apply updates following these rules:

**Term categories:**

| File                  | Terms                                    |
| --------------------- | ---------------------------------------- |
| `core-concepts.md`    | plugin, command, skill, rule, agent      |
| `artifacts.md`        | ticket, spec, story, changelog           |
| `workflow-terms.md`   | drive, archive, sync, release            |
| `file-conventions.md` | kebab-case, frontmatter, icebox, archive |
| `inconsistencies.md`  | Known terminology issues                 |

**Term Entry Format**:

```markdown
## term-name

Brief one-sentence definition.

### Definition

Full explanation of what this term means in the Workaholic context.

### Usage Patterns

- **Directory names**: examples
- **File names**: examples
- **Code references**: examples

### Related Terms

- Related term 1, related term 2

### Inconsistencies (if any)

- Description of inconsistency and potential resolution
```

**Frontmatter** (required for every file):

```yaml
---
title: Document Title
description: Brief description of this document
category: developer
last_updated: YYYY-MM-DD
commit_hash: <short-hash>
---
```

Get the current commit hash with:

```bash
git rev-parse --short HEAD
```

### 5. Update Index Files

Ensure documentation hierarchy is maintained:

**When adding a term:**

- Add to the appropriate category file
- If it's a major new concept, consider adding to README

**When deprecating a term:**

- Mark as deprecated in the definition
- Note what replaced it
- Keep for historical reference

**i18n mirroring:**

When terminology files have translations (e.g., `artifacts.md` and `artifacts_ja.md`):

- Any term added to one file must have its translation in the other
- See `plugins/core/rules/i18n.md` for `.workaholic/` i18n policy

### 6. Completion

Summarize changes made:

- List terms added/updated/deprecated
- List inconsistencies identified
- Confirm all changes are reflected in both language versions (if applicable)

## Critical Rules

- **Consistency over precision** - A term should mean the same thing everywhere
- **Every ticket may introduce terms** - Even small changes may use new terminology
- **Only delete within `.workaholic/`** - Safety constraint for file deletions
- **Update `last_updated`** - Set to current date when modifying any doc
- **Update `commit_hash`** - Run `git rev-parse --short HEAD` and set this value
- **Keep translations in sync** - If `_ja.md` exists, update both files
