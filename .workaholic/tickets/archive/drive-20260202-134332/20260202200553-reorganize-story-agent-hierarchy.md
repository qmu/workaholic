---
created_at: 2026-02-02T20:05:53+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: e1db47a
category: Changed
---

# Reorganize Story Agent Hierarchy

## Overview

Restructure the `/story` command to delegate orchestration responsibilities to `story-writer` subagent. Currently, the `/story` command orchestrates 6 parallel agents in Phase 1, then passes their outputs to `story-writer` in Phase 2. The new architecture moves this orchestration into `story-writer`, making it the central hub that launches subagents and integrates their outputs.

This change inverts the current responsibility model: instead of the command being the orchestrator, the `story-writer` becomes the orchestrator.

## Key Files

- `plugins/core/commands/story.md` - Simplify to delegate to story-writer
- `plugins/core/agents/story-writer.md` - Expand to orchestrate subagents and integrate outputs
- `plugins/core/agents/changelog-writer.md` - No changes (called by story-writer)
- `plugins/core/agents/spec-writer.md` - No changes (called by story-writer)
- `plugins/core/agents/terms-writer.md` - No changes (called by story-writer)
- `plugins/core/agents/release-readiness.md` - No changes (called by story-writer)
- `plugins/core/agents/performance-analyst.md` - No changes (called by story-writer)
- `plugins/core/agents/overview-writer.md` - No changes (called by story-writer)
- `.workaholic/specs/architecture.md` - Update dependency diagrams and documentation

## Related History

Historical tickets show the evolution of the /story agent architecture through multiple phases of parallelization and restructuring.

Past tickets that touched similar areas:

- [20260202181348-add-overview-writer-subagent.md](.workaholic/tickets/archive/drive-20260202-134332/20260202181348-add-overview-writer-subagent.md) - Added overview-writer as 6th parallel agent in Phase 1
- [20260131182901-move-performance-analyst-to-phase1.md](.workaholic/tickets/archive/feat-20260131-125844/20260131182901-move-performance-analyst-to-phase1.md) - Moved performance-analyst from story-writer to parallel execution
- [20260127004417-story-writer-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127004417-story-writer-subagent.md) - Original extraction of story-writer as subagent
- [20260128004700-document-nesting-policy.md](.workaholic/tickets/archive/feat-20260128-001720/20260128004700-document-nesting-policy.md) - Established current nesting policy (may need update)

## Current Architecture

```
/story command
  |
  +-- Phase 1 (parallel): 6 subagents
  |     |-- changelog-writer
  |     |-- spec-writer
  |     |-- terms-writer
  |     |-- release-readiness
  |     |-- performance-analyst
  |     +-- overview-writer
  |
  +-- Phase 2: story-writer (receives Phase 1 outputs)
  |
  +-- Phase 3: pr-creator
```

## Proposed Architecture

```
/story command
  |
  +-- story-writer (orchestrates everything)
  |     |
  |     +-- Phase 1 (parallel): 6 subagents
  |     |     |-- changelog-writer
  |     |     |-- spec-writer
  |     |     |-- terms-writer
  |     |     |-- release-readiness
  |     |     |-- performance-analyst
  |     |     +-- overview-writer
  |     |
  |     +-- Phase 2: integrate outputs, write story
  |
  +-- pr-creator
```

## Implementation Steps

1. **Update story.md command**:
   - Remove Phase 1 parallel agent invocations
   - Change to invoke only `story-writer` with branch context
   - `story-writer` returns confirmation that story is complete
   - Then invoke `pr-creator` as before

2. **Update story-writer.md agent**:
   - Add Task tool to frontmatter
   - Add instructions to invoke 6 subagents in parallel
   - Receive outputs from all subagents
   - Use outputs to populate story sections (current integration logic remains)
   - Handle failure cases (report which agents succeeded/failed)

3. **Update architecture.md**:
   - Update /story Dependencies diagram
   - Update Documentation Enforcement flowchart
   - Show story-writer as the orchestration hub
   - Update prose descriptions

4. **Update CLAUDE.md nesting policy** (if needed):
   - Current policy allows Subagent -> Subagent only in parallel with max depth 1
   - This change complies with that policy (story-writer invokes subagents in parallel, not nested chains)
   - No policy change required

## Considerations

- **Nesting policy compliance**: The proposed architecture complies with current policy - subagents invoke other subagents in parallel (max depth 1), not nested chains
- **Context window**: `story-writer` will need more context to orchestrate 6 agents, but this is offset by removing orchestration logic from the command
- **Error handling**: `story-writer` must handle partial failures gracefully and report status
- **Backward compatibility**: The PR output remains the same; only internal orchestration changes
- **Thin command principle**: This change makes `/story` command even thinner (just invoke story-writer, then pr-creator)
