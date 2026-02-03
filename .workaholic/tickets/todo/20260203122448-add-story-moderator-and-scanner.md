---
created_at: 2026-02-03T12:24:48+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Add story-moderator and scanner to Reorganize Documentation Agents

## Overview

Introduce a two-tier orchestration pattern for the `/story` command by adding `story-moderator` and `scanner` subagents. Currently, `story-writer` invokes 7 subagents in parallel. The new architecture splits this into two groups: `scanner` handles documentation scanning (changelog-writer, spec-writer, terms-writer), while `story-writer` (reduced) handles story generation (overview-writer, section-reviewer, release-readiness, performance-analyst). A new `story-moderator` orchestrates both groups in parallel.

This change removes the "max depth 1" constraint from CLAUDE.md, allowing depth 2 subagent nesting (story-moderator -> scanner -> writers).

## Key Files

- `plugins/core/agents/story-moderator.md` - New orchestrator to create (invokes scanner and story-writer in parallel)
- `plugins/core/agents/scanner.md` - New subagent to create (invokes changelog-writer, spec-writer, terms-writer in parallel)
- `plugins/core/agents/story-writer.md` - Reduce to 4 subagents (overview-writer, section-reviewer, release-readiness, performance-analyst)
- `plugins/core/commands/story.md` - Update to invoke story-moderator instead of story-writer
- `CLAUDE.md` - Remove "max depth 1" restriction, allow depth 2
- `.workaholic/specs/architecture.md` - Update /story Dependencies diagram and Documentation Enforcement flowchart
- `.workaholic/specs/architecture_ja.md` - Japanese translation of architecture updates

## Related History

Historical tickets demonstrate the pattern of parallelizing documentation agents and restructuring the /story command hierarchy. The current 7-agent parallel execution in story-writer was established through multiple iterations.

Past tickets that touched similar areas:

- [20260202200553-reorganize-story-agent-hierarchy.md](.workaholic/tickets/archive/drive-20260202-134332/20260202200553-reorganize-story-agent-hierarchy.md) - Moved orchestration from /story command into story-writer (same layer: Config)
- [20260202181348-add-overview-writer-subagent.md](.workaholic/tickets/archive/drive-20260202-134332/20260202181348-add-overview-writer-subagent.md) - Added overview-writer as parallel agent pattern
- [20260127004417-story-writer-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127004417-story-writer-subagent.md) - Original extraction of story-writer as subagent
- [20260131154122-split-dependency-graph-by-command.md](.workaholic/tickets/archive/feat-20260131-125844/20260131154122-split-dependency-graph-by-command.md) - Per-command dependency diagrams

## Current Architecture

```
/story command
  |
  +-- story-writer (orchestrates 7 agents)
  |     |
  |     +-- Phase 1 (parallel): 7 subagents
  |     |     |-- changelog-writer
  |     |     |-- spec-writer
  |     |     |-- terms-writer
  |     |     |-- release-readiness
  |     |     |-- performance-analyst
  |     |     |-- overview-writer
  |     |     +-- section-reviewer
  |     |
  |     +-- Phase 2: integrate outputs, write story
  |
  +-- pr-creator
```

## Proposed Architecture

```
/story command
  |
  +-- story-moderator (orchestrates 2 groups)
  |     |
  |     +-- Parallel invocation:
  |     |     |
  |     |     +-- scanner (invokes 3 agents)
  |     |     |     |-- changelog-writer
  |     |     |     |-- spec-writer
  |     |     |     +-- terms-writer
  |     |     |
  |     |     +-- story-writer (invokes 4 agents)
  |     |           |-- overview-writer
  |     |           |-- section-reviewer
  |     |           |-- release-readiness
  |     |           +-- performance-analyst
  |     |
  |     +-- Integrate outputs, write story
  |
  +-- pr-creator
```

## Implementation Steps

1. **Update CLAUDE.md** nesting policy:
   - Remove "max depth 1" from Subagent -> Subagent allowed rule
   - Update prohibited section to note that "nested chains" (sequential, not parallel) are still prohibited
   - Change line 46: `- Subagent → Subagent (via Task tool, parallel only, max depth 1)` to `- Subagent → Subagent (via Task tool, parallel only)`
   - Update line 52 comment to clarify sequential chains are prohibited, not depth

2. **Create scanner.md** at `plugins/core/agents/scanner.md`:
   - Frontmatter: name, description, tools (Read, Write, Edit, Bash, Glob, Grep, Task)
   - Input: branch name, base branch, repository URL
   - Instructions: invoke changelog-writer, spec-writer, terms-writer in parallel
   - Output: JSON with status of each writer and any error details

3. **Create story-moderator.md** at `plugins/core/agents/story-moderator.md`:
   - Frontmatter: name, description, tools (Read, Write, Edit, Bash, Glob, Grep, Task)
   - Skills: preload write-story for story integration
   - Input: branch name, base branch, repository URL, archived tickets list, git log
   - Phase 1: invoke scanner and story-writer in parallel
   - Phase 2: integrate all outputs into story file (moved from story-writer)
   - Output: confirmation with agent status report

4. **Update story-writer.md**:
   - Remove changelog-writer, spec-writer, terms-writer from Phase 1 invocation
   - Keep: overview-writer, section-reviewer, release-readiness, performance-analyst (4 agents)
   - Remove Phase 2 story integration (moved to story-moderator)
   - Output: JSON with overview, sections, release-readiness, performance outputs

5. **Update story.md command**:
   - Replace story-writer invocation with story-moderator
   - Pass same inputs (branch name, base branch, repo URL, archived tickets, git log)
   - Update comments to reflect new architecture

6. **Update architecture.md**:
   - Update /story Dependencies diagram to show story-moderator -> (scanner, story-writer)
   - Update Documentation Enforcement flowchart to show two-tier structure
   - Update prose descriptions of story-writer and add scanner/story-moderator descriptions
   - Update agent list in Directory Layout section

7. **Update architecture_ja.md**:
   - Apply same changes as architecture.md with Japanese translations

## Considerations

- **Nesting policy change**: Removing "max depth 1" is necessary for this architecture. The key constraint is "parallel only" (no sequential chains), which remains enforced.
- **Context distribution**: Splitting into two groups may improve context utilization - scanner agents don't need story context, story-writer agents don't need changelog/spec/terms context.
- **Failure isolation**: If scanner fails, story-writer output is still valid. If story-writer fails, scanner output (changelog, specs, terms) is still valid.
- **Backward compatibility**: Final story output remains identical; only internal orchestration changes.
- **Thin moderator principle**: story-moderator is pure orchestration (~30-40 lines), delegating all knowledge to story-writer and scanner.
