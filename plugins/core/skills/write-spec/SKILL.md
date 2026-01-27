---
name: write-spec
description: Spec document structure, formatting rules, and guidelines for updating .workaholic/specs/.
user-invocable: false
---

# Write Spec

Guidelines for writing and updating specification documents in `.workaholic/specs/`.

## Directory Structure

| Audience   | Directory                            | Content                                  |
| ---------- | ------------------------------------ | ---------------------------------------- |
| Users      | `.workaholic/specs/user-guide/`      | How to use: commands, workflows, setup   |
| Developers | `.workaholic/specs/developer-guide/` | How it works: architecture, contributing |

## Frontmatter

Required for every spec file:

```yaml
---
title: Document Title
description: Brief description of this document
category: user | developer
modified_at: <ISO 8601 datetime>
commit_hash: <from context COMMIT section>
---
```

## File Naming

- Use kebab-case: `getting-started.md`, `command-reference.md`
- Exception: `README.md` uses uppercase

## Content Style

- Write full paragraphs, not bullet-point fragments
- Code blocks must specify language
- Links use relative paths within `.workaholic/`
- Use Mermaid charts for diagrams

## Design Policy

- Rewrite to reflect present reality, not append changes
- Think "what does a new reader need to know today?"

## Cross-Cutting Concerns

Before updating individual docs, analyze changes for patterns that span multiple components:

- **Data flow paths**: How data moves through layers
- **Shared concepts**: Abstractions used across multiple files
- **Integration points**: Where different subsystems connect
- **Architectural patterns**: Design decisions that affect multiple areas

For each cross-cutting concern:

- Check if `.workaholic/specs/` already has a document covering this concept
- Prefer extending existing docs over creating new files for minor patterns

**Writing cross-cutting documentation:**

- Prefer prose over file listings - explain how components work together
- Use Mermaid sequence diagrams to show interactions between layers
- Document the "why" behind design decisions, not just implementation details

## Index File Updates

**When adding a document:**

- Add link to parent README
- Include brief description

**When removing a document:**

- Remove link from parent README
- Verify no other docs link to it

**i18n README mirroring:**

- Any document added to one README must have its translation linked in the other
- Follow the preloaded `enforce-i18n` skill for translation requirements

## Critical Rules

- **"No updates needed" is almost always wrong** - Re-analyze if you think nothing changed
- **Every ticket affects docs somehow** - Even small changes have documentation implications
- **Only delete within `.workaholic/`** - Safety constraint for file deletions
- **No orphan documents** - Every doc must be linked from a parent README
- **Category matches directory** - A doc with `category: user` must be in `user-guide/`, `category: developer` in `developer-guide/`
- **Update `modified_at`** - Set to current datetime (use `date -Iseconds`) when modifying any doc
- **Update `commit_hash`** - Use value from context COMMIT section
