---
created_at: 2026-01-27T00:54:14+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.15h
commit_hash: b65d371
category: Changed
---

# Extract changelog-writer subagent and run 4 agents concurrently in pull-request

## Overview

The pull-request command currently handles CHANGELOG updates inline (step 4) and only invokes story-writer as a subagent. This ticket extracts the changelog update logic into a dedicated `changelog-writer` subagent and modifies pull-request to run all 4 documentation agents concurrently: changelog-writer, story-writer, spec-writer, and terminology-writer. After all agents complete, pull-request will commit the artifacts in a single commit.

This improves performance through parallelism and maintains separation of concerns for each documentation type.

## Key Files

- `plugins/core/commands/pull-request.md` - Current command to be modified
- `plugins/core/agents/changelog-writer.md` - New subagent to create
- `plugins/core/agents/story-writer.md` - Existing subagent (already invoked)
- `plugins/core/agents/spec-writer.md` - Existing subagent (to be invoked)
- `plugins/core/agents/terminology-writer.md` - Existing subagent (to be invoked)

## Implementation Steps

1. **Create changelog-writer subagent** at `plugins/core/agents/changelog-writer.md`:
   - Extract CHANGELOG update logic from pull-request.md step 4
   - Read archived tickets from `.workaholic/tickets/archive/<branch-name>/*.md`
   - Extract frontmatter fields: `commit_hash`, `category`
   - Extract title from `# <Title>` heading
   - Extract first sentence from Overview section
   - Generate entries grouped by category (Added, Changed, Removed)
   - Update root `CHANGELOG.md` with new branch section
   - Tools: Read, Write, Edit, Bash, Glob, Grep

2. **Update pull-request command** to invoke 4 agents concurrently:
   - Replace inline CHANGELOG update (step 4) with changelog-writer subagent invocation
   - Replace sequential story-writer invocation (step 5) with concurrent execution
   - Add spec-writer and terminology-writer invocations
   - Use Task tool with 4 parallel invocations in a single message
   - Wait for all 4 agents to complete before proceeding

3. **Update commit strategy**:
   - After all 4 agents complete, stage all changes from:
     - `CHANGELOG.md` (from changelog-writer)
     - `.workaholic/stories/<branch-name>.md` (from story-writer)
     - `.workaholic/specs/**/*.md` (from spec-writer)
     - `.workaholic/terminology/**/*.md` (from terminology-writer)
   - Commit with message: "Update documentation for PR"
   - This consolidates what was previously multiple commits into one

4. **Update pull-request instructions**:
   - Remove step 4 (CHANGELOG update) as separate step
   - Rename step 5 to "Generate documentation" covering all 4 agents
   - Adjust step numbers for subsequent steps

## Considerations

- **Parallel execution**: All 4 agents can run simultaneously since they write to different locations
- **Single commit**: Consolidating artifacts into one commit keeps git history cleaner than multiple doc commits
- **Context preservation**: Running as subagents keeps extensive file reads out of main conversation
- **Agent independence**: Each agent handles its own domain without dependencies on others
- **Failure handling**: If one agent fails, others can still complete; PR command should report which succeeded/failed

## Final Report

Development completed as planned.
