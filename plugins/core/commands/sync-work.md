---
name: sync-work
description: Sync source code changes to .workaholic/ directory (specs and terminology)
---

# Sync Work

Update `.workaholic/specs/` and `.workaholic/terminology/` to reflect the current codebase state.

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

**If no archived tickets:**

- Compare against main branch: `git diff main...HEAD --stat`
- Read changed files to understand modifications

### 2. Audit Current Documentation

Survey what exists in `.workaholic/specs/` and `.workaholic/terminology/`:

```bash
find .workaholic/specs -name "*.md" -type f | sort
find .workaholic/terminology -name "*.md" -type f | sort
```

For each document:

- Read the file to understand its scope
- Note what aspects of the codebase it covers
- Identify if content is outdated or incomplete

### 3. Plan Documentation Updates

Based on changes and current docs, determine:

**For specs:**

- **Updates needed**: Existing docs that reference changed components
- **New docs needed**: Changes that introduced new concepts requiring docs
- **Deletions needed**: Docs for removed features (only within `.workaholic/`)
- **README updates**: Index files needing link additions/removals

**For terminology:**

- **New terms**: Concepts introduced that need definitions
- **Updated definitions**: Terms whose meaning has evolved
- **Inconsistencies**: Terms used differently across files
- **Deprecated terms**: Concepts no longer in use

### 4. Identify Cross-Cutting Concerns

Before updating individual docs, analyze changes for patterns that span multiple components. Documentation serves two audiences: someone looking up a specific file, and someone trying to understand how the system works. The former needs file-level docs; the latter needs cross-cutting docs that explain flows, patterns, and architectural decisions.

Look for:

- **Data flow paths**: How data moves through layers (e.g., request → middleware → handler → database)
- **Shared concepts**: Abstractions used across multiple files (e.g., error handling patterns, validation approaches)
- **Integration points**: Where different subsystems connect
- **Architectural patterns**: Design decisions that affect multiple areas

For each cross-cutting concern identified:

- Check if `.workaholic/specs/` already has a document covering this concept
- If not, consider whether it warrants a new document or a section in `architecture.md`
- If yes, update the existing document to reflect the current state
- Prefer extending existing docs over creating new files for minor patterns

**Writing cross-cutting documentation:**

- Prefer prose over file listings - explain how components work together
- Use Mermaid sequence diagrams to show interactions between layers
- Document the "why" behind design decisions, not just implementation details
- Think like a new developer - what would they need to understand before diving into individual files?

### 5. Execute Spec Updates

Apply updates to `.workaholic/specs/` following these formatting rules:

**Directory Structure** (required):

All spec documents must be placed in the appropriate subdirectory based on audience:

| Audience   | Directory                      | Content                                  |
| ---------- | ------------------------------ | ---------------------------------------- |
| Users      | `.workaholic/specs/user-guide/`      | How to use: commands, workflows, setup   |
| Developers | `.workaholic/specs/developer-guide/` | How it works: architecture, contributing |

- The `category` in frontmatter must match the directory
- Do not place documents directly in `.workaholic/specs/` (except README.md)
- Each subdirectory has its own README.md as an index

**Frontmatter** (required for every file):

```yaml
---
title: Document Title
description: Brief description of this document
category: user | developer # Must match parent directory (user-guide or developer-guide)
modified_at: <ISO 8601 datetime>
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
- Links use relative paths within `.workaholic/`
- Use Mermaid charts for diagrams

**Design Policy**:

- Rewrite to reflect present reality, not append changes
- Think "what does a new reader need to know today?"
- Historical context belongs in tickets, not specs

### 6. Execute Terminology Updates

Apply updates to `.workaholic/terminology/` following these rules:

**Term categories:**

| File                  | Terms                                    |
| --------------------- | ---------------------------------------- |
| `core-concepts.md`    | plugin, command, skill, rule             |
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

### 7. Update Index Files

Ensure documentation hierarchy is maintained:

**.workaholic/README.md structure:**

The root .workaholic/README.md should be a simple index linking to subdirectory READMEs:

```markdown
# Documentation

- [changelogs/](changelogs/README.md) - Historical record of changes per branch
- [specs/](specs/README.md) - Current state reference documentation
- [stories/](stories/README.md) - Development narratives per branch
- [terminology/](terminology/README.md) - Consistent term definitions
- [tickets/](tickets/README.md) - Implementation work queue and archives

## Plugins

- [Core](../plugins/core/README.md) - Git workflow commands
- [TDD](../plugins/tdd/README.md) - Ticket-driven development
```

Keep detailed content in subdirectory READMEs, not in .workaholic/README.md.

**When adding a document:**

- Add link to parent README (subdirectory or `.workaholic/specs/README.md`)
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

**i18n README mirroring:**

When the project has multiple language READMEs (e.g., `README.md` and `README_ja.md`):

- Any document added to one README must have its translation linked in the other
- See `plugins/core/rules/i18n.md` for `.workaholic/` i18n policy

### 8. Completion

Summarize changes made:

- List specs updated/created/deleted
- List terminology terms added/updated/deprecated
- List inconsistencies identified
- Confirm all new docs are linked from READMEs

## Critical Rules

- **"No updates needed" is almost always wrong** - Re-analyze if you think nothing changed
- **Every ticket affects docs somehow** - Even small changes have documentation implications
- **Only delete within `.workaholic/`** - Safety constraint for file deletions
- **No orphan documents** - Every doc must be linked from a parent README
- **Consistency over precision** - A term should mean the same thing everywhere
- **Category matches directory** - A doc with `category: user` must be in `user-guide/`, `category: developer` in `developer-guide/`
- **Update `modified_at`** - Set to current datetime (use `date -Iseconds`) when modifying any doc
- **Update `commit_hash`** - Run `git rev-parse --short HEAD` and set this value
