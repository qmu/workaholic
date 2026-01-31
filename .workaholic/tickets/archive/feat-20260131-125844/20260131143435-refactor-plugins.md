---
created_at: 2026-01-31T14:34:35+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: f538bb6---
category: Changed
# Split drive-navigator Subagent from drive.md

## Overview

Extract ticket navigation logic (listing, analysis, prioritization, user confirmation) from `drive.md` into a dedicated `drive-navigator` subagent. This follows the architectural policy of keeping commands as thin orchestrators (~50-100 lines) while delegating complex logic to subagents and skills.

## Key Files

- `plugins/core/commands/drive.md` - Main command to refactor (steps 1-4 contain navigation logic)
- `plugins/core/agents/drive-navigator.md` - Target subagent (already created, needs integration)
- `plugins/core/commands/story.md` - Reference for Task tool invocation pattern

## Related History

- `20260127204529-extract-agent-content-to-skills.md` - Established agent/skill separation pattern
- `20260129020653-add-command-flow-spec.md` - Documents command flow including /drive
- `20260127100902-extract-drive-ticket-skills.md` - Architectural policy for command refactoring

## Implementation

1. **Update drive.md** to invoke drive-navigator via Task tool:
   - Replace inline steps 1-4 with Task tool call to `core:drive-navigator`
   - Pass mode parameter ("normal" or "icebox" based on $ARGUMENT)
   - Receive prioritized ticket list from subagent

2. **Simplify drive.md** to thin orchestration:
   - Phase 1: Call drive-navigator, get ordered ticket list
   - Phase 2: Loop through tickets, apply drive-workflow skill
   - Handle completion reporting

3. **Delete drive-navigator.md** that was prematurely created (or verify it matches requirements)

## Acceptance Criteria

- drive.md is ~50-100 lines (thin orchestrator)
- drive-navigator subagent handles all navigation logic
- Icebox mode works via mode parameter
- User confirmation flow unchanged from user perspective

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The ticket mentioned a pre-existing `drive-navigator.md` that needed integration, but no such file existed
  **Context**: The ticket's step 3 said "Delete drive-navigator.md that was prematurely created" but the agent didn't exist, so we created it fresh instead
