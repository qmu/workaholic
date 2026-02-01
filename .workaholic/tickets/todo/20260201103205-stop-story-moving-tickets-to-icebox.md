---
created_at: 2026-02-01T10:32:05+09:00
author: noreply@anthropic.com
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Stop /story from moving todo tickets to icebox

## Overview

Remove the automatic ticket migration behavior from `/story` command. Currently, `/story` moves any remaining tickets in `.workaholic/tickets/todo/` to `icebox/` before generating documentation. This behavior is unwanted.

## Key Files

- `plugins/core/commands/story.md` - Contains the ticket migration logic at lines 22-30

## Related History

Historical context shows the `/story` command has evolved through multiple iterations, including command consolidation and parallel execution optimizations.

Past tickets that touched similar areas:

- [20260129015817-add-discover-history-subagent.md](.workaholic/tickets/archive/feat-20260128-220712/20260129015817-add-discover-history-subagent.md) - Ticket discovery workflows
- [20260131182901-move-performance-analyst-to-phase1.md](.workaholic/tickets/archive/feat-20260131-125844/20260131182901-move-performance-analyst-to-phase1.md) - /story command refactoring
- [20260131125946-intelligent-drive-prioritization.md](.workaholic/tickets/archive/feat-20260131-125844/20260131125946-intelligent-drive-prioritization.md) - Ticket prioritization logic

## Implementation Steps

1. Open `plugins/core/commands/story.md`
2. Remove step 3 entirely (lines 22-30) which handles "Check for remaining tickets"
3. Renumber subsequent steps (current step 4 becomes step 3, etc.)
4. Verify the instruction flow remains coherent after removal

## Considerations

- Users who want to move tickets to icebox can do so manually or via `/drive` abandon flow
- The `icebox/` directory structure remains available for other uses
