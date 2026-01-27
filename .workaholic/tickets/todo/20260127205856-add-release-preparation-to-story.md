---
created_at: 2026-01-27T20:58:57+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Release Preparation section to story with release-readiness subagent

## Overview

The story currently lacks release readiness information. Users want to know:

1. **Is this branch releasable?** - AI-determined verdict based on actual changes
2. **What release instructions apply?** - Extra steps needed before/after release

This requires:
- A new **release-readiness** subagent that runs in parallel with other `/report` subagents
- A new **Release Preparation** section in the story (after Performance, before Notes)
- The subagent analyzes changes and provides a releasability verdict with reasoning

## Key Files

- `plugins/core/agents/story-writer.md` - Needs to invoke release-readiness subagent
- `plugins/core/skills/write-story/SKILL.md` - Add Release Preparation section template
- `plugins/core/agents/release-readiness.md` - New subagent to create
- `plugins/core/commands/report.md` - Add release-readiness to parallel subagent invocation

## Related History

Past tickets that touched similar areas:

- `20260127182720-improve-story-changes-granularity.md` - Modified story format (same file)
- `20260127100459-add-topic-tree-to-story.md` - Added section to story (same file)
- `20260127005414-changelog-writer-subagent-and-concurrent-pr-agents.md` - Added parallel subagent pattern (same pattern)
- `20260127004417-story-writer-subagent.md` - Created story-writer agent (same file)

## Implementation Steps

1. **Create release-readiness subagent** at `plugins/core/agents/release-readiness.md`:
   - Tools: Read, Bash, Glob, Grep
   - Input: Branch name, base branch, list of archived tickets
   - Analysis tasks:
     - Review actual code changes (`git diff main..HEAD`)
     - Check for breaking changes (API changes, config changes)
     - Check for incomplete work (TODO comments, FIXME)
     - Verify tests pass (if test command exists)
     - Check for security concerns (secrets, credentials)
   - Output JSON:
     ```json
     {
       "releasable": true/false,
       "verdict": "Ready for release" / "Needs attention",
       "concerns": ["list of concerns if any"],
       "instructions": ["pre-release steps", "post-release steps"]
     }
     ```

2. **Update report.md** to invoke release-readiness in parallel:
   - Add to step 4 (Generate documentation):
     - **release-readiness** (`subagent_type: "core:release-readiness"`): Analyzes changes for release readiness
   - Now 5 subagents run in parallel instead of 4
   - Pass the output to story-writer (or story-writer invokes it directly)

3. **Add Release Preparation section** to `plugins/core/skills/write-story/SKILL.md`:
   ```markdown
   ## 8. Release Preparation

   **Verdict**: [Ready for release / Needs attention before release]

   ### 8.1. Concerns

   - [List any concerns from release-readiness analysis]
   - Or "None - changes are safe for release"

   ### 8.2. Pre-release Instructions

   - [Steps to take before running /release]
   - Or "None - standard release process applies"

   ### 8.3. Post-release Instructions

   - [Steps to take after release]
   - Or "None - no special post-release actions needed"
   ```

4. **Update story-writer.md**:
   - Add instruction to invoke release-readiness subagent
   - OR receive release-readiness output from report command
   - Include the output in Release Preparation section

5. **Update section numbering**:
   - Current: 1-7 (Summary through Notes)
   - New: 1-8 (with Release Preparation as 8, Notes becomes 9)
   - OR if combined with previous ticket (20260127205054): coordinate numbering

## Considerations

- **Parallel execution**: release-readiness should run alongside other subagents, not sequentially
- **Data flow**: Either report.md passes release-readiness output to story-writer, or story-writer invokes it directly. Direct invocation is simpler.
- **False positives**: The AI verdict should err on the side of caution - flag concerns rather than miss them
- **Optional sections**: If no concerns/instructions, display "None" rather than omitting
- **Coordination with other ticket**: The enhance-story-format ticket (20260127205054) also adds sections. Coordinate numbering to avoid conflicts.
