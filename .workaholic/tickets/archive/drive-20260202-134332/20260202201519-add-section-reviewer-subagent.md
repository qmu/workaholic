---
created_at: 2026-02-02T20:15:19+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash: 7cbf1a0
category: Added
---

# Add Section Reviewer Subagent for Sections 5-8

## Overview

Add a reviewer subagent that generates content for story sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas) concurrently with other subagents. The story-writer will invoke this reviewer in parallel with the existing 6 subagents, then integrate its output into the story file.

Currently, sections 5-8 are written directly by story-writer based on archived ticket content. This enhancement extracts that logic into a dedicated subagent, following the pattern established by overview-writer (which generates sections 1-3).

## Key Files

- `plugins/core/agents/section-reviewer.md` - New subagent to create
- `plugins/core/agents/story-writer.md` - Update to invoke section-reviewer in parallel
- `plugins/core/skills/review-sections/SKILL.md` - New skill with review guidelines
- `plugins/core/skills/write-story/SKILL.md` - Update to document section-reviewer integration

## Related History

Historical tickets show the pattern of extracting story sections into dedicated subagents for parallel execution.

Past tickets that touched similar areas:

- [20260202200553-reorganize-story-agent-hierarchy.md](.workaholic/tickets/todo/20260202200553-reorganize-story-agent-hierarchy.md) - Moves orchestration to story-writer (prerequisite)
- [20260202181348-add-overview-writer-subagent.md](.workaholic/tickets/archive/drive-20260202-134332/20260202181348-add-overview-writer-subagent.md) - Added overview-writer for sections 1-3 (same pattern)
- [20260127205054-enhance-story-format.md](.workaholic/tickets/archive/feat-20260126-214833/20260127205054-enhance-story-format.md) - Added sections 6-8 to story format
- [20260131182901-move-performance-analyst-to-phase1.md](.workaholic/tickets/archive/feat-20260131-125844/20260131182901-move-performance-analyst-to-phase1.md) - Moved performance-analyst to parallel execution

## Implementation Steps

1. **Create review-sections skill**:
   - Create `plugins/core/skills/review-sections/SKILL.md`
   - Define guidelines for analyzing archived tickets to generate:
     - Section 5 (Outcome): Summarize accomplishments
     - Section 6 (Historical Analysis): Extract patterns from Related History sections
     - Section 7 (Concerns): Identify risks, trade-offs, limitations
     - Section 8 (Ideas): Extract future enhancement suggestions
   - Define JSON output format

2. **Create section-reviewer subagent**:
   - Create `plugins/core/agents/section-reviewer.md`
   - Tools: Read, Glob, Grep
   - Skills: review-sections
   - Model: haiku (lightweight analysis task)
   - Input: Branch name, list of archived tickets
   - Output: JSON with sections 5-8 content

3. **Update story-writer to invoke section-reviewer**:
   - Add section-reviewer to parallel invocation (7 agents total)
   - Use output to populate sections 5-8 in story
   - Update agent status report to include section-reviewer

4. **Update write-story skill documentation**:
   - Document section-reviewer JSON input format
   - Update section 5-8 templates to reference subagent output

5. **Create skill shell script (optional)**:
   - `plugins/core/skills/review-sections/sh/gather.sh` if needed for ticket parsing

## Considerations

- **Dependency**: Should be implemented after `20260202200553-reorganize-story-agent-hierarchy.md` which moves orchestration to story-writer
- **Pattern consistency**: Follows the same pattern as overview-writer (sections 1-3) and performance-analyst (section 9.2)
- **Parallel execution**: Section-reviewer runs concurrently with changelog-writer, spec-writer, terms-writer, release-readiness, performance-analyst, and overview-writer
- **Empty sections**: Reviewer should return "None" for Concerns/Ideas if nothing noteworthy found
- **Context window**: Haiku model should be sufficient for analyzing ticket content
