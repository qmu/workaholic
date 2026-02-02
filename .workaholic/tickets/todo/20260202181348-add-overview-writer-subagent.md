---
created_at: 2026-02-02T18:13:48+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add overview-writer Subagent for Parallel Story Preparation

## Overview

Add a new `overview-writer` subagent to Phase 1 of the `/story` command's parallel execution. This subagent analyzes commit messages in the current branch to generate structured overview content including motivation, highlights, and journey. By moving this work to Phase 1, it runs concurrently with changelog-writer, spec-writer, terms-writer, release-readiness, and performance-analyst, reducing total story generation time.

The subagent uses a bundled shell script to collect commit information, following the pattern established by write-story's calculate.sh.

## Key Files

- `plugins/core/agents/overview-writer.md` - New subagent to create
- `plugins/core/skills/write-overview/SKILL.md` - New skill with content guidelines
- `plugins/core/skills/write-overview/sh/collect-commits.sh` - Shell script for commit collection
- `plugins/core/commands/story.md` - Add overview-writer to Phase 1 parallel execution
- `plugins/core/agents/story-writer.md` - Update to receive overview-writer output for sections 1-3

## Related History

Historical tickets demonstrate the parallel subagent pattern and skill-with-shell-script architecture.

Past tickets that touched similar areas:

- [20260131182901-move-performance-analyst-to-phase1.md](.workaholic/tickets/archive/feat-20260131-125844/20260131182901-move-performance-analyst-to-phase1.md) - Same pattern: moved agent to Phase 1 parallel execution
- [20260128002346-integrate-calculate-story-metrics-into-write-story.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002346-integrate-calculate-story-metrics-into-write-story.md) - Established skill with bundled shell script pattern
- [20260127004417-story-writer-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127004417-story-writer-subagent.md) - Story-writer architecture and section responsibilities

## Implementation Steps

1. **Create write-overview skill** at `plugins/core/skills/write-overview/`:
   - Create `SKILL.md` with content structure for Overview, Highlights, Motivation, and Journey sections
   - Create `sh/collect-commits.sh` shell script that:
     - Takes base branch as argument (default: main)
     - Collects all commit messages since base branch
     - Outputs JSON with commit subjects, bodies, and timestamps
   - Document the output structure expected by story-writer

2. **Create overview-writer subagent** at `plugins/core/agents/overview-writer.md`:
   - Frontmatter: `tools: Read, Bash, Glob, Grep`
   - Preload write-overview skill
   - Input: branch name, base branch
   - Instructions: run shell script, analyze commits, generate content
   - Output: JSON with overview, highlights array, motivation paragraph, journey mermaid chart and paragraph

3. **Update story.md command** Phase 1:
   - Add overview-writer as 6th parallel agent
   - Pass branch name and base branch
   - Update comments to reflect 6 parallel agents

4. **Update story.md command** Phase 2:
   - Pass overview-writer output to story-writer
   - Document that sections 1.1, 1.2, 1.3 come from overview-writer

5. **Update story-writer.md agent**:
   - Add overview-writer output to input section
   - Update instructions to use overview output for sections 1 (Overview), including 1.1 (Highlights), 1.2 (Motivation), and 1.3 (Journey)
   - Story-writer formats and integrates the content rather than generating it from scratch

6. **Update write-story skill** section templates:
   - Update sections 1-3 to reference subsections (1.1 Highlights, 1.2 Motivation, 1.3 Journey)
   - Document that content comes from overview-writer output

## Output Structure

The overview-writer subagent returns JSON:

```json
{
  "overview": "2-3 sentence summary capturing the branch essence",
  "highlights": [
    "First meaningful change",
    "Second meaningful change",
    "Third meaningful change"
  ],
  "motivation": "Paragraph synthesizing the 'why' from commit context",
  "journey": {
    "mermaid": "flowchart LR\n  subgraph Phase1[Initial Work]\n    direction TB\n    a1[Step 1] --> a2[Step 2]\n  end\n  ...",
    "summary": "50-100 word summary of the development journey"
  }
}
```

## Considerations

- **Thin agent, comprehensive skill**: The overview-writer agent is orchestration only; write-overview skill contains templates and guidelines
- **Shell script for commit collection**: Following write-story pattern, use bundled sh script for git operations
- **Section renumbering**: The story structure changes from flat sections to nested (1.1, 1.2, 1.3 under Overview)
- **Backward compatibility**: Story-writer can fall back to generating sections if overview-writer output is missing
- **Commit message quality**: The effectiveness depends on commit message quality; consider documenting commit message guidelines
