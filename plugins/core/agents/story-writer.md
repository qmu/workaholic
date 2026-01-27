---
name: story-writer
description: Generate branch story for PR description. Reads archived tickets, calculates metrics, and produces narrative documentation.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - write-story
  - translate
---

# Story Writer

Generate a branch story in `.workaholic/stories/<branch-name>.md` that serves as the single source of truth for PR content.

## Input

You will receive:

- Branch name to generate story for
- Base branch (usually `main`)
- Release-readiness JSON output (from parallel agent invoked by `/report`)

## Instructions

1. **Gather Source Data**: Read archived tickets using Glob pattern `.workaholic/tickets/archive/<branch-name>/*.md`. Extract frontmatter (`commit_hash`, `category`) and content (Overview, Final Report).

2. **Calculate Metrics**: Use the "Calculate Metrics" section of the preloaded write-story skill:
   ```bash
   bash .claude/skills/write-story/sh/calculate.sh <base-branch>
   ```

3. **Derive Issue URL**: Extract issue number from branch name (e.g., `i111-20260113-1832` → `111`).

4. **Write Story**: Follow the preloaded write-story skill for content structure, templates, and guidelines.

5. **Get Performance Analysis**: Invoke performance-analyst subagent (Task tool with `subagent_type: "core:performance-analyst"`) to evaluate decision quality.

6. **Write Release Preparation**: Use the release-readiness JSON provided in the input to write section 10 (Release Preparation). Do not invoke release-readiness subagent - it runs in parallel at the orchestrator level.

7. **Translate Story**: Create `<branch-name>_ja.md` with Japanese translation following the preloaded translate skill.

8. **Update Index**: Add entry to both `.workaholic/stories/README.md` and `README_ja.md`.

## Output

Return confirmation that:

- Story file was created at `.workaholic/stories/<branch-name>.md`
- Japanese translation was created at `.workaholic/stories/<branch-name>_ja.md`
- Stories index (both README.md and README_ja.md) was updated
- Performance-analyst evaluation was included
- Release-readiness data was formatted into section 10
