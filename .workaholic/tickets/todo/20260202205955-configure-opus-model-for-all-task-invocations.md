---
created_at: 2026-02-02T20:59:54+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Configure Opus Model for All Task Tool Invocations

## Overview

Add `model: "opus"` parameter to all Task tool invocations in commands and subagents as a trial configuration. This ensures consistent model usage across the entire workflow and allows evaluation of opus model performance for all subagent tasks.

## Key Files

- `plugins/core/commands/ticket.md` - Task tool invocation for ticket-organizer (line 19)
- `plugins/core/commands/drive.md` - Task tool invocation for drive-navigator (line 24)
- `plugins/core/commands/story.md` - Task tool invocations for story-writer (line 26) and pr-creator (line 60, currently has `model: "haiku"`)
- `plugins/core/agents/ticket-organizer.md` - Task tool invocations for history-discoverer, source-discoverer, ticket-moderator (lines 46-63)
- `plugins/core/agents/story-writer.md` - Task tool invocations for 7 agents: changelog-writer, spec-writer, terms-writer, release-readiness, performance-analyst, overview-writer, section-reviewer (lines 43-49)

## Related History

Previous ticket configured opus model for ticket-organizer specifically using frontmatter `model:` field. This ticket extends that approach to use Task tool `model:` parameter for all subagent invocations.

Past tickets that touched similar areas:

- [20260202182240-configure-opus-model-for-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202182240-configure-opus-model-for-ticket-organizer.md) - Configured opus for ticket-organizer via frontmatter (same layer: Config)
- [20260128211509-use-haiku-for-report-subagents.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211509-use-haiku-for-report-subagents.md) - Added model: haiku to report subagent invocations (same pattern, opposite model)

## Implementation Steps

1. **Update `plugins/core/commands/ticket.md`** (line 19-20):
   - Add `model: "opus"` to the Task tool invocation for ticket-organizer
   - Change: `Task tool with subagent_type: "core:ticket-organizer"` to include model parameter

2. **Update `plugins/core/commands/drive.md`** (line 24-25):
   - Add `model: "opus"` to the Task tool invocation for drive-navigator
   - Change: `Task tool with subagent_type: "core:drive-navigator"` to include model parameter

3. **Update `plugins/core/commands/story.md`**:
   - Line 26: Add `model: "opus"` to story-writer invocation
   - Line 60: Change `model: "haiku"` to `model: "opus"` for pr-creator invocation

4. **Update `plugins/core/agents/ticket-organizer.md`** (lines 46-63):
   - Add `model: "opus"` to all three parallel subagent invocations:
     - history-discoverer
     - source-discoverer
     - ticket-moderator

5. **Update `plugins/core/agents/story-writer.md`** (lines 43-49):
   - Add `model: "opus"` to all 7 parallel subagent invocations:
     - changelog-writer
     - spec-writer
     - terms-writer
     - release-readiness
     - performance-analyst
     - overview-writer
     - section-reviewer

## Considerations

- **Trial configuration**: This is an experimental change to evaluate opus model performance. May be reverted or adjusted based on results (cost vs quality tradeoff)
- **Frontmatter vs Task parameter**: Some agents have frontmatter `model:` fields (e.g., ticket-organizer has `model: opus`). This ticket focuses on Task tool `model:` parameters, which override frontmatter settings when invoking subagents
- **Cost implications**: Opus model is more expensive than haiku. This change will increase API costs for all subagent invocations
- **Existing haiku configurations**: Some agents (history-discoverer, source-discoverer, ticket-moderator, overview-writer, section-reviewer) have `model: haiku` in their frontmatter. The Task tool `model:` parameter overrides this
