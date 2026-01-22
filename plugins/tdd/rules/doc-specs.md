---
name: doc-specs
description: Documentation standards for doc/specs/
paths: doc/specs/**
---

# Documentation Standards for doc/specs/

This rule applies automatically when working in `doc/specs/`.

## Philosophy

Specs represent a **snapshot of the current state**. They describe what exists now, not what changed. When updating specs:

- Rewrite to reflect the present reality, not append changes
- Think "what does a new reader need to know today?"
- Don't preserve historical context - that belongs in tickets

## File Naming

Use kebab-case for all markdown files except README.md:

- `getting-started.md` (not `GETTING_STARTED.md`)
- `api-reference.md` (not `API_REFERENCE.md`)
- `data-model.md` (not `DATA_MODEL.md`)

README.md files use uppercase as a universal convention.

## File Format

Every markdown file must have YAML frontmatter:

```yaml
---
title: Document Title
description: Brief description of this document
category: user | developer
last_updated: YYYY-MM-DD
---
```

## Structure

- `doc/README.md` - Index linking to specs/ and tickets/
- `doc/specs/README.md` - Index for all specifications
- `doc/specs/user-guide/README.md` - Index for user documentation
- `doc/specs/developer-guide/README.md` - Index for developer documentation

**Requirement**: Every subdirectory under `doc/specs/` must have a README.md that links to all documents in that directory.

## Heading Levels

- H1 (`#`): Document title only (one per file, matches frontmatter title)
- H2 (`##`): Major sections
- H3 (`###`): Subsections
- H4 (`####`): Rarely used, only for deep nesting

## Markdown Style

- Use Mermaid charts for diagrams (flowcharts, sequences, architecture)
- Write full paragraphs, not bullet-point fragments
- Code blocks must specify language
- Links use relative paths within doc/
- Tables for structured data comparisons

## Link Hierarchy

```
README.md (root)
└── doc/README.md
    ├── doc/specs/README.md
    │   ├── doc/specs/user-guide/README.md
    │   │   └── (individual user docs)
    │   └── doc/specs/developer-guide/README.md
    │       └── (individual developer docs)
    └── doc/tickets/README.md
```

## Subdirectory README Format

Each subdirectory README must:

- Have YAML frontmatter with title and description
- List all documents in the directory with brief descriptions
- Use relative links to documents

Example:

```yaml
---
title: User Documentation
description: Documentation for end users of the project
category: user
last_updated: 2026-01-23
---
```

```markdown
# User Documentation

- [Getting Started](getting-started.md) - Installation and first steps
- [Commands](commands.md) - Complete command reference
```

## PR-Time Documentation Updates

When preparing a pull request, update documentation based on all archived tickets:

1. **Read archived tickets** from `doc/tickets/archive/<branch-name>/`
2. **Extract changes** - What changed (from Implementation Steps) and why (from Overview)
3. **Audit current docs** - Check what exists in `doc/specs/`
4. **Update documentation**:
   - Update existing docs that reference changed components
   - Create new docs if changes introduced new concepts
   - Delete outdated docs (only within `doc/`)
   - Update subdirectory READMEs when adding/removing docs

## Critical Rules

- **Document everything** - Every ticket affects docs somehow
- **"No updates needed" is wrong** - Re-analyze if you think nothing changed
- **Only delete within `doc/`** - Safety constraint for file deletions
- **Update READMEs** - Keep subdirectory indexes current
- No orphan documents (must be linked from parent)
- Follow written language specified in CLAUDE.md
