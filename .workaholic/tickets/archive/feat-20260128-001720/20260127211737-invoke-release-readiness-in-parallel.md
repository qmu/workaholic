---
created_at: 2026-01-27T21:17:37+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: S
commit_hash: e1dcf1f
category: Changed
---

# Invoke release-readiness as 5th parallel agent in /report

## Overview

Currently, `release-readiness` is invoked as a nested subagent inside `story-writer`, based on instructions in the `write-story` skill. This creates unnecessary complexity:

```
/report → story-writer → release-readiness (nested)
```

This ticket moves `release-readiness` to be the 5th parallel agent invoked directly by `/report`:

```
/report → [changelog-writer, story-writer, spec-writer, terms-writer, release-readiness] (parallel)
```

Benefits:
- Simpler architecture (no nested subagent calls)
- Faster execution (all 5 run concurrently)
- Easier to understand and maintain

## Key Files

- `plugins/core/commands/report.md` - Add release-readiness as 5th parallel agent
- `plugins/core/skills/write-story/SKILL.md` - Remove nested release-readiness invocation instructions
- `plugins/core/agents/story-writer.md` - Update to receive release-readiness output as input

## Related History

Past tickets that touched similar areas:

- `20260127205856-add-release-preparation-to-story.md` - Added release preparation section (same files)
- `20260127005414-changelog-writer-subagent-and-concurrent-pr-agents.md` - Established parallel agent pattern (same layer)
- `20260127004417-story-writer-subagent.md` - Created story-writer agent (same file)

## Implementation Steps

1. Update `plugins/core/commands/report.md`:
   - Change "4 subagents concurrently" to "5 subagents concurrently"
   - Add `release-readiness` (`subagent_type: "core:release-readiness"`) to the parallel invocation list
   - Pass branch name, base branch, and archived tickets list to release-readiness
   - After all 5 complete, pass release-readiness JSON output to story-writer (or write directly to story file)

2. Update `plugins/core/skills/write-story/SKILL.md`:
   - Remove "Invoking release-readiness" section (lines 154-162)
   - Change section 10 template to expect release-readiness data as input rather than invoking it
   - Add note that release-readiness output is provided by the orchestrator

3. Update `plugins/core/agents/story-writer.md`:
   - Add to Input section: "Release-readiness JSON output (from parallel agent)"
   - Remove any reference to invoking release-readiness subagent

4. Coordinate the data flow in `/report`:
   - Option A: Wait for release-readiness to complete, then pass its output to story-writer
   - Option B: Let both run in parallel, then have story-writer read release-readiness output file
   - Recommend Option A for simplicity

## Considerations

- Story-writer needs release-readiness output to write section 10
- May need to adjust parallelism: run 4 agents first, then story-writer with release-readiness data
- Alternative: release-readiness writes to a temp file, story-writer reads it after both complete

## Final Report

Implemented Option A: two-phase execution where 4 agents run in parallel first (changelog-writer, spec-writer, terms-writer, release-readiness), then story-writer runs with the release-readiness JSON output as input. This provides a good balance between parallelism and data dependency management.

Files modified:
- `plugins/core/commands/report.md`: Restructured into Phase 1 (4 parallel agents) and Phase 2 (story-writer with release-readiness data)
- `plugins/core/skills/write-story/SKILL.md`: Replaced invocation instructions with input documentation showing expected JSON format
- `plugins/core/agents/story-writer.md`: Added release-readiness JSON to Input section, changed step 6 from invocation to formatting
