---
title: Make Discovery Optional in /ticket Command
type: refactoring
layer: Config
effort: 1h
created_at: 2026-02-03T19:57:42+09:00
author: a@qmu.jp
---

# Make Discovery Optional in /ticket Command

## Overview

Fix the `/ticket` command memory leak by making discovery optional rather than automatic. Most tickets don't need deep codebase exploration - the user already knows what they want to change. By making discovery opt-in, `/ticket` becomes fast by default while preserving the capability for when it's truly needed.

## Motivation

The memory leak occurs because ticket-organizer spawns 3 parallel subagents for every ticket, regardless of whether discovery is useful. This is overkill for simple requests like "add a button to the header".

The root cause isn't the subagent architecture itself - it's that discovery runs unconditionally. A simpler fix than restructuring subagents is to skip discovery when not needed.

## Key Files

- `plugins/core/commands/ticket.md` - Add `--explore` flag handling
- `plugins/core/agents/ticket-organizer.md` - Check for explore flag, skip discovery if false

## Implementation

### 1. Update ticket.md Command

Add flag parsing to detect `--explore` or `-e`:

```markdown
## Instructions

### Parse Arguments

1. Check if `--explore` or `-e` flag is present
2. Extract description (everything except flags)
3. Pass `explore: true/false` to ticket-organizer
```

### 2. Update ticket-organizer.md

Make Step 2 (Parallel Discovery) conditional:

```markdown
### 2. Discovery (Optional)

**If `explore: false` (default)**:
- Skip subagent invocation
- Set empty discovery results:
  - `history_discovery = {"summary": "Discovery skipped", "tickets": []}`
  - `source_discovery = {"summary": "Discovery skipped", "files": []}`
  - `moderation = {"status": "clear", "matches": []}`
- Proceed directly to Step 3

**If `explore: true`**:
- Invoke ALL THREE subagents concurrently (existing behavior)
- Wait for results before proceeding
```

### 3. Update Related History Section Handling

When discovery is skipped, omit the "Related History" section from the ticket rather than including an empty section.

## Usage

```bash
# Fast ticket creation (no discovery)
/ticket add logout button to header

# With exploration (when needed)
/ticket --explore refactor the authentication module
/ticket -e optimize database queries
```

## Considerations

**Default behavior change**: Discovery was automatic, now opt-in. This means:
- Tickets created without `--explore` won't have Related History or explored Key Files
- Users who relied on automatic discovery need to add the flag

**Alternative considered**: Make discovery automatic for complex keywords (detect "refactor", "optimize", etc). Rejected because keyword detection is fragile and unpredictable.

**Backwards compatibility**: The ticket format remains unchanged. Only the discovery process is affected.

## Verification

1. Run `/ticket add simple feature` - should complete quickly without subagent spawning
2. Run `/ticket --explore complex refactoring` - should spawn subagents and include discovery
3. Check both ticket formats are valid
