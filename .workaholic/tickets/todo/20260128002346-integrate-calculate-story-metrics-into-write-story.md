---
created_at: 2026-01-28T00:23:46+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Integrate calculate-story-metrics into write-story

## Overview

The `calculate-story-metrics` skill exists solely to provide metrics calculation for the `story-writer` agent. Since `write-story` is preloaded into the same agent and they always work together, merge them into a single skill to reduce fragmentation.

This follows the same consolidation pattern as the other queued tickets for merging create-pr/manage-pr and gather-terms-context/write-terms.

## Key Files

- `plugins/core/skills/write-story/SKILL.md` - Skill to expand with metrics calculation
- `plugins/core/skills/calculate-story-metrics/SKILL.md` - Skill to merge and delete
- `plugins/core/skills/calculate-story-metrics/sh/calculate.sh` - Shell script to move
- `plugins/core/agents/story-writer.md` - Agent that preloads both skills

## Related History

The calculate-story-metrics skill was extracted from inline agent instructions to enable bash script execution.

Past tickets that touched similar areas:

- `20260127204529-extract-agent-content-to-skills.md` - Created write-story skill and kept calculate-story-metrics separate (same files)
- `20260127021000-extract-story-skill.md` - Originally extracted story metrics calculation to a skill (same files)

## Implementation Steps

1. **Move shell script to write-story directory**:
   - Move `plugins/core/skills/calculate-story-metrics/sh/calculate.sh` to `plugins/core/skills/write-story/sh/calculate.sh`

2. **Merge metrics calculation into write-story**:
   - Add a "Calculate Metrics" section near the beginning of write-story SKILL.md
   - Include the shell script invocation instructions from calculate-story-metrics
   - Update the script path reference to `.claude/skills/write-story/sh/calculate.sh`
   - Include the JSON output format documentation and velocity unit selection logic

3. **Update story-writer agent**:
   - Remove `calculate-story-metrics` from skills list
   - Update instruction step 2 to reference the merged skill's metrics calculation section

4. **Delete calculate-story-metrics skill directory**:
   - Remove `plugins/core/skills/calculate-story-metrics/` entirely

## Considerations

- The write-story skill already references metrics in its frontmatter section - the merged content should be positioned before that reference
- The shell script path changes from `calculate-story-metrics` to `write-story`
- This completes the pattern of consolidating 1:1 utility skills into their primary skills
