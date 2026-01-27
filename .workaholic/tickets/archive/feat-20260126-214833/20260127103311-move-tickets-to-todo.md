---
created_at: 2026-01-27T10:33:11+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: a1d40f9
category: Changed
---

# Move active tickets from root to todo/ subdirectory

## Overview

Reorganize ticket directory structure to use `.workaholic/tickets/todo/` for active tickets instead of placing them directly in `.workaholic/tickets/`. This creates a cleaner three-tier structure:

- `todo/` - active tickets waiting to be implemented
- `icebox/` - deferred tickets (unchanged)
- `archive/<branch>/` - completed tickets (unchanged)

## Key Files

### Plugin files to update

- `plugins/core/commands/ticket.md` - ticket creation path
- `plugins/core/commands/drive.md` - ticket listing and processing
- `plugins/core/commands/report.md` - remaining tickets check
- `plugins/core/skills/archive-ticket/SKILL.md` - archive example
- `plugins/core/skills/archive-ticket/scripts/archive.sh` - example path
- `plugins/core/skills/ticket-format/SKILL.md` - path reference
- `plugins/core/skills/drive-workflow/SKILL.md` - uncommitted tickets note
- `plugins/core/README.md` - directory structure docs

### Current workaholic directory

- `.workaholic/tickets/README.md` - update structure description
- Move existing tickets to `todo/` subdirectory

## Implementation Steps

1. Move existing tickets in `.workaholic/tickets/`:
   ```bash
   mkdir -p .workaholic/tickets/todo
   git mv .workaholic/tickets/*.md .workaholic/tickets/todo/ 2>/dev/null || true
   # Keep README.md in root
   git mv .workaholic/tickets/todo/README.md .workaholic/tickets/
   ```

2. Update `plugins/core/commands/ticket.md`:
   - Change ticket creation path from `.workaholic/tickets/` to `.workaholic/tickets/todo/`
   - Update icebox path reference (stays as `.workaholic/tickets/icebox/`)

3. Update `plugins/core/commands/drive.md`:
   - Change listing: `ls -1 .workaholic/tickets/todo/*.md`
   - Change icebox retrieval: move to `todo/` not root
   - Update example paths

4. Update `plugins/core/commands/report.md`:
   - Change remaining tickets check: `.workaholic/tickets/todo/*.md`

5. Update `plugins/core/skills/archive-ticket/`:
   - SKILL.md example path
   - scripts/archive.sh example path

6. Update `plugins/core/README.md`:
   - Change "Active tickets: `.workaholic/tickets/`" to `.workaholic/tickets/todo/`

7. Update `.workaholic/tickets/README.md`:
   - Document new structure with todo/, icebox/, archive/

## Considerations

- The archive path remains `.workaholic/tickets/archive/<branch>/` (unchanged)
- icebox path remains `.workaholic/tickets/icebox/` (unchanged)
- Only active ticket location changes from root to `todo/`
- This aligns with common task management conventions (todo/doing/done)

## Final Report

Development completed as planned.
