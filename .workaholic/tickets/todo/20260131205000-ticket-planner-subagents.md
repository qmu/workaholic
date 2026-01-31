---
created_at: 2026-01-31T20:50:00+09:00
author: tamurayoshiya@gmail.com
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Ticket Planner Subagents for Empty Todo Queue

## Overview

When `/drive` finds no todo tickets, invoke three planner subagents in parallel to suggest new work sources: icebox revival, abandoned ticket retry, and story-derived tickets from concerns/ideas sections.

## Motivation

Currently, when todo is empty, `/drive` only offers to work on icebox or stop. This misses opportunities to:

1. Systematically review icebox for stale vs. ready-to-implement tickets
2. Retry previously abandoned tickets that may now be feasible
3. Create new tickets from concerns/ideas accumulated in recent stories

Parallel planners provide a comprehensive "what's next?" overview without requiring the user to manually scan multiple sources.

## Key Files

- `plugins/core/commands/drive.md` - Update empty todo handling to invoke planners
- `plugins/core/agents/drive-navigator.md` - Trigger planner invocation on empty status
- `plugins/core/agents/ticket-planner-icebox.md` - New subagent
- `plugins/core/agents/ticket-planner-abandoned.md` - New subagent
- `plugins/core/agents/ticket-planner-stories.md` - New subagent

## Related History

- [20260131125946-intelligent-drive-prioritization.md](.workaholic/tickets/archive/feat-20260131-125844/20260131125946-intelligent-drive-prioritization.md) - Added icebox fallback on empty todo
- [20260131164315-add-driver-agent.md](.workaholic/tickets/archive/feat-20260131-125844/20260131164315-add-driver-agent.md) - Established subagent isolation pattern

## Implementation

### 1. Create ticket-planner-icebox Subagent

Create `plugins/core/agents/ticket-planner-icebox.md`:

```markdown
---
name: ticket-planner-icebox
description: Plan icebox ticket revival or mark as stale.
tools: Glob, Read
---

# Ticket Planner: Icebox

Analyze icebox tickets and recommend actions.

## Instructions

1. List all tickets in `.workaholic/tickets/icebox/`
2. For each ticket, read and analyze:
   - Age (from created_at): >30 days = potentially stale
   - Type and layer: Still relevant to current codebase?
   - Overview: Is the problem still valid?

3. Categorize each ticket:
   - **Ready**: Still relevant, can be moved to todo
   - **Stale**: Outdated, recommend deletion or archival
   - **Needs update**: Valid idea but ticket needs rewriting

## Output

Return JSON:
\`\`\`json
{
  "ready": ["ticket1.md", "ticket2.md"],
  "stale": ["ticket3.md"],
  "needs_update": ["ticket4.md"],
  "summary": "2 tickets ready for revival, 1 stale"
}
\`\`\`
```

### 2. Create ticket-planner-abandoned Subagent

Create `plugins/core/agents/ticket-planner-abandoned.md`:

```markdown
---
name: ticket-planner-abandoned
description: Plan abandoned ticket retry or mark as stale.
tools: Glob, Read
---

# Ticket Planner: Abandoned

Analyze failed tickets and recommend retry or closure.

## Instructions

1. List all tickets in `.workaholic/tickets/fail/`
2. For each ticket, read the Failure Analysis section:
   - Why did it fail?
   - What was the blocker?
   - Has the blocker been resolved?

3. Categorize each ticket:
   - **Retry**: Blocker resolved or different approach possible
   - **Permanent**: Fundamentally blocked, mark for deletion
   - **Split**: Too complex, recommend breaking into smaller tickets

## Output

Return JSON:
\`\`\`json
{
  "retry": ["ticket1.md"],
  "permanent": ["ticket2.md"],
  "split": ["ticket3.md"],
  "summary": "1 ticket ready for retry"
}
\`\`\`
```

### 3. Create ticket-planner-stories Subagent

Create `plugins/core/agents/ticket-planner-stories.md`:

```markdown
---
name: ticket-planner-stories
description: Create tickets from story concerns and ideas.
tools: Glob, Read
---

# Ticket Planner: Stories

Extract actionable tickets from recent story concerns and ideas.

## Instructions

1. List recent stories (last 5) in `.workaholic/stories/`
2. For each story, extract:
   - Section 7 (Concerns): Risks, trade-offs identified
   - Section 8 (Ideas): Future enhancement suggestions

3. Filter for actionable items:
   - Skip "None" sections
   - Skip vague observations
   - Keep specific, implementable suggestions

4. Draft ticket summaries for each actionable item

## Output

Return JSON:
\`\`\`json
{
  "from_concerns": [
    {"source": "feat-20260131.md", "title": "Add batch approval to reduce UX friction", "type": "enhancement"}
  ],
  "from_ideas": [
    {"source": "feat-20260131.md", "title": "Track Phase 1 execution time", "type": "enhancement"}
  ],
  "summary": "Found 2 potential tickets from recent stories"
}
\`\`\`
```

### 4. Update drive-navigator

Modify `plugins/core/agents/drive-navigator.md` empty todo handling (lines 43-52):

```markdown
**If no tickets found:**

1. Check if `.workaholic/tickets/icebox/` has tickets
2. Check if `.workaholic/tickets/fail/` has tickets
3. Return status to trigger planner invocation:
   ```json
   {
     "status": "empty",
     "has_icebox": true,
     "has_failed": true
   }
   ```
```

### 5. Update drive Command

Modify `plugins/core/commands/drive.md` Phase 1 empty handling (lines 31-33):

```markdown
- `status: "empty"` - Invoke ticket planners:
  1. Invoke 3 planner subagents in parallel (single message, 3 Task tool calls):
     - `ticket-planner-icebox`
     - `ticket-planner-abandoned`
     - `ticket-planner-stories`
  2. Present combined results to user with AskUserQuestion:
     - "Create tickets from stories" - Create suggested tickets
     - "Revive icebox tickets" - Move ready tickets to todo
     - "Retry abandoned tickets" - Move retry candidates to todo
     - "Stop" - End drive session
```

## Verification

1. Empty todo queue, have tickets in icebox → planners should analyze icebox
2. Have failed ticket with Failure Analysis → planner should categorize
3. Recent stories with Concerns/Ideas sections → planner should extract actionable items
4. All three planners return results → combined presentation to user

## Notes

- Planners are advisory only; user must approve any ticket movements
- Stale/permanent tickets are not auto-deleted; user decides
- Story-derived tickets need user confirmation before creation
