---
name: ticket-format
description: Ticket file structure and frontmatter conventions.
user-invocable: false
---

# Ticket Format

Standard format for implementation tickets in `.workaholic/tickets/`.

## Filename Convention

Format: `YYYYMMDDHHmmss-<short-description>.md`

Use current timestamp: `date +%Y%m%d%H%M%S`

Example: `20260114153042-add-dark-mode.md`

## File Structure

```markdown
---
created_at: YYYY-MM-DDTHH:MM:SS+TZ
author: <git user.email>
type: enhancement | bugfix | refactoring | housekeeping
layer: [<layers affected>]
effort: <filled after implementation>
commit_hash: <filled when archived>
category: <filled when archived>
---

# <Title>

## Overview

<Brief description of what will be implemented>

## Key Files

- `path/to/file.ts` - <why this file is relevant>

## Implementation Steps

1. <Step 1>
2. <Step 2>
   ...

## Considerations

- <Any trade-offs, risks, or things to watch out for>
```

## Frontmatter Fields

### Required at Creation

- **created_at**: Creation timestamp in ISO 8601 format. Use `date -Iseconds`
- **author**: Git email. Use `git config user.email`
- **type**: Infer from request context:
  - `enhancement` - New features or capabilities (keywords: add, create, implement, new)
  - `bugfix` - Fixing broken behavior (keywords: fix, bug, broken, error)
  - `refactoring` - Restructuring without changing behavior (keywords: refactor, restructure, reorganize)
  - `housekeeping` - Maintenance, cleanup, documentation (keywords: clean, update, remove, deprecate)
- **layer**: Architectural layers affected (YAML array, can specify multiple):
  - `UX` - User interface, components, styling
  - `Domain` - Business logic, models, services
  - `Infrastructure` - External integrations, APIs, networking
  - `DB` - Database, storage, migrations
  - `Config` - Configuration, build, tooling

### Filled After Implementation

- **effort**: Time spent on implementation (e.g., 0.1h, 0.25h, 0.5h, 1h, 2h). Leave empty when creating ticket.
- **commit_hash**: Short git commit hash. Set automatically by archive script.
- **category**: Change category (Added, Changed, or Removed). Set automatically by archive script based on commit message verb.
