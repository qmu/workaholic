---
name: sync-doc-specs
description: Update doc/specs comprehensively following doc-specs rules
---

# Sync Doc Specs

Update `doc/specs/` to reflect the current codebase state based on changes made in the current branch.

## Instructions

### 1. Gather Context

Understand what changed in the current branch:

```bash
# Get current branch
git branch --show-current

# List archived tickets for this branch
ls -1 doc/tickets/archive/<branch-name>/*.md 2>/dev/null | grep -v CHANGELOG
```

**If archived tickets exist:**

- Read each ticket file
- Extract what changed (from Implementation Steps)
- Extract why it changed (from Overview)

**If no archived tickets:**

- Compare against main branch: `git diff main...HEAD --stat`
- Read changed files to understand modifications

### 2. Audit Current Documentation

Survey what exists in `doc/specs/`:

```bash
find doc/specs -name "*.md" -type f | sort
```

For each document:

- Read the file to understand its scope
- Note what aspects of the codebase it covers
- Identify if content is outdated or incomplete

### 3. Plan Documentation Updates

Based on changes and current docs, determine:

- **Updates needed**: Existing docs that reference changed components
- **New docs needed**: Changes that introduced new concepts requiring docs
- **Deletions needed**: Docs for removed features (only within `doc/`)
- **README updates**: Index files needing link additions/removals

### 4. Execute Updates

Apply updates following these formatting rules:

**Frontmatter** (required for every file):

```yaml
---
title: Document Title
description: Brief description of this document
category: user | developer
last_updated: YYYY-MM-DD
commit_hash: <short-hash>
---
```

Get the current commit hash with:

```bash
git rev-parse --short HEAD
```

**File Naming**:

- Use kebab-case: `getting-started.md`, `api-reference.md`
- Exception: `README.md` uses uppercase

**Heading Levels**:

- H1 (`#`): Document title only (one per file, matches frontmatter title)
- H2 (`##`): Major sections
- H3 (`###`): Subsections

**Content Style**:

- Write full paragraphs, not bullet-point fragments
- Code blocks must specify language
- Links use relative paths within `doc/`
- Use Mermaid charts for diagrams

**Philosophy**:

- Rewrite to reflect present reality, not append changes
- Think "what does a new reader need to know today?"
- Historical context belongs in tickets, not specs

### 5. Update Index Files

Ensure documentation hierarchy is maintained:

**When adding a document:**

- Add link to parent README (subdirectory or `doc/specs/README.md`)
- Include brief description of the document

**When removing a document:**

- Remove link from parent README
- Verify no other docs link to it

**Subdirectory README format:**

```markdown
# Section Title

- [Document Name](document-name.md) - Brief description
- [Another Doc](another-doc.md) - Brief description
```

### 6. Completion

Summarize changes made:

- List documents updated
- List documents created
- List documents deleted
- Confirm all new docs are linked from READMEs

## Critical Rules

- **"No updates needed" is almost always wrong** - Re-analyze if you think nothing changed
- **Every ticket affects docs somehow** - Even small changes have documentation implications
- **Only delete within `doc/`** - Safety constraint for file deletions
- **No orphan documents** - Every doc must be linked from a parent README
- **Update `last_updated`** - Set to today's date when modifying any doc
- **Update `commit_hash`** - Run `git rev-parse --short HEAD` and set this value
