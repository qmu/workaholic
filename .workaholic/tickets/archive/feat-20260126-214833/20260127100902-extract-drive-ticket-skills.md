---
created_at: 2026-01-27T10:09:02+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash: 2777671
category: Changed
---

# Extract /drive and /ticket instructions into skills

## Overview

Reorganize `/drive` and `/ticket` commands to follow the same pattern as `/report`: commands become lightweight orchestrators that reference skills for detailed instructions. This reduces duplication and makes the system more maintainable.

Currently, `drive.md` (218 lines) and `ticket.md` (113 lines) contain extensive inline instructions. These should be extracted into skills that can be referenced by `skills:` frontmatter.

## Key Files

- `plugins/core/commands/drive.md` - Currently 218 lines, should become ~50 lines
- `plugins/core/commands/ticket.md` - Currently 113 lines, should become ~30 lines
- `plugins/core/skills/` - New skills to be created

## Implementation Steps

### 1. Create `ticket-format` skill

Create `plugins/core/skills/ticket-format/SKILL.md`:

```yaml
---
name: ticket-format
description: Ticket file structure and frontmatter conventions.
user-invocable: false
---
```

Content extracted from ticket.md:
- Ticket file structure (section 5)
- Frontmatter fields and their meanings
- Filename format convention (YYYYMMDDHHmmss-<short-description>.md)

### 2. Create `drive-workflow` skill

Create `plugins/core/skills/drive-workflow/SKILL.md`:

```yaml
---
name: drive-workflow
description: Implementation workflow for processing tickets.
user-invocable: false
---
```

Content extracted from drive.md:
- Steps 2.1-2.5 (read, implement, review, report, archive)
- Approval prompt format
- Final report format
- Commit message rules (or reference archive-ticket skill)

### 3. Refactor ticket.md

Reduce to orchestrator:
```yaml
---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
skills: [ticket-format]
---
```

Keep only:
1. Understand the Request (parse $ARGUMENT, icebox detection)
2. Explore the Codebase (brief)
3. Ask Clarifying Questions (brief)
4. Write the Ticket → reference ticket-format skill
5. Commit the Ticket (with drive-context note)
6. Present the Ticket

### 4. Refactor drive.md

Reduce to orchestrator:
```yaml
---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills: [drive-workflow, archive-ticket]
---
```

Keep only:
1. List and Sort Tickets
2. For Each Ticket → reference drive-workflow skill
3. Completion summary
4. Critical Rules (icebox policy)

## Considerations

- Skills don't have scripts - they're just documentation/instructions
- The `skills:` frontmatter preloads skill content into Claude's context
- archive-ticket skill already exists and is referenced by drive
- ticket-format skill could also be used by drive-workflow for consistency
- Keep commands readable as standalone documents (brief inline summaries)
