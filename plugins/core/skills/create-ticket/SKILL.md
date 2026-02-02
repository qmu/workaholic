---
name: create-ticket
description: Create implementation tickets with proper format and conventions.
skills:
  - gather-ticket-metadata
user-invocable: false
---

# Create Ticket

Guidelines for creating implementation tickets in `.workaholic/tickets/`.

## Step 1: Capture Dynamic Values

**Run the gather-ticket-metadata script:**

```bash
bash .claude/skills/gather-ticket-metadata/sh/gather.sh
```

Parse the JSON output:

```json
{
  "created_at": "2026-01-31T19:25:46+09:00",
  "author": "developer@company.com",
  "filename_timestamp": "20260131192546"
}
```

Use these values for frontmatter fields and filename.

## Frontmatter Template

Use the captured values from Step 1:

```yaml
---
created_at: $(date -Iseconds)      # REPLACE with actual output
author: $(git config user.email)   # REPLACE with actual output
type: <enhancement | bugfix | refactoring | housekeeping>
layer: [<UX | Domain | Infrastructure | DB | Config>]
effort:
commit_hash:
category:
---
```

### Field Requirements

- **Lines 1-4**: Fill with actual values (never placeholders)
- **Lines 5-7**: Must be present but leave empty (filled after implementation)

### Concrete Example

```yaml
---
created_at: 2026-01-31T19:25:46+09:00
author: developer@company.com
type: enhancement
layer: [UX, Domain]
effort:
commit_hash:
category:
---
```

## Common Mistakes

These cause validation failures:

| Mistake | Example | Fix |
|---------|---------|-----|
| Missing empty fields | Omitting `effort:` line | Include all 7 fields, even if empty |
| Placeholder values | `author: user@example.com` | Run `git config user.email` and use actual output |
| Wrong date format | `2026-01-31` or `2026/01/31T...` | Use `date -Iseconds` output (includes timezone) |
| Scalar layer | `layer: Config` | Use array format: `layer: [Config]` |

## Filename Convention

Format: `YYYYMMDDHHmmss-<short-description>.md`

Use current timestamp: `date +%Y%m%d%H%M%S`

Example: `20260114153042-add-dark-mode.md`

## File Structure

```markdown
---
created_at: 2026-01-31T19:25:46+09:00
author: developer@company.com
type: enhancement
layer: [UX, Domain]
effort:
commit_hash:
category:
---

# <Title>

## Overview

<Brief description of what will be implemented>

## Key Files

- `path/to/file.ts` - <why this file is relevant>

## Related History

<1-2 sentence summary synthesizing what historical tickets reveal about this area>

Past tickets that touched similar areas:

- [20260127010716-rename-terminology-to-terms.md](.workaholic/tickets/archive/<branch>/20260127010716-rename-terminology-to-terms.md) - Renamed terminology directory (same layer: Config)
- [20260125113858-auto-commit-ticket-on-creation.md](.workaholic/tickets/archive/<branch>/20260125113858-auto-commit-ticket-on-creation.md) - Modified ticket.md (same file)

## Implementation Steps

1. <Step 1>
2. <Step 2>
   ...

## Considerations

- <Any trade-offs, risks, or things to watch out for>
```

## Frontmatter Fields

### Required at Creation

- **created_at**: Creation timestamp in ISO 8601 format. Run `date -Iseconds` and use the actual output.
- **author**: Git email. Run `git config user.email` and use the actual output. Never use hardcoded values.
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

These fields are updated by the `update-ticket-frontmatter` skill during archiving:

- **effort**: Time spent in numeric hours (leave empty when creating)
- **commit_hash**: Short git commit hash (set by archive script)
- **category**: Added, Changed, or Removed (set by archive script)

## Exploring the Codebase

Before writing a ticket:

- Use Glob, Grep, and Read tools to find relevant files
- Understand existing patterns, architecture, and conventions
- Identify files that will need to be modified or created

## Related History

The Related History section is populated by the `history-discoverer` subagent (invoked by `/ticket` command).

**Link format**: Use markdown links with repository-relative paths:
```markdown
- [filename.md](.workaholic/tickets/archive/<branch>/filename.md) - Description (match reason)
```

The full path includes the branch directory from the search results (e.g., `feat-20260126-214833`).

If the subagent returns no matches, omit the Related History section entirely.

## Writing Guidelines

- Focus on the "why" and "what", not just "how"
- Keep implementation steps actionable and specific
- Reference existing code patterns when applicable
- Use the Write tool directly - it creates parent directories automatically
