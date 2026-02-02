---
name: story-writer
description: Generate branch story for PR description. Reads archived tickets, calculates metrics, and produces narrative documentation.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - write-story
---

# Story Writer

Generate a branch story in `.workaholic/stories/<branch-name>.md` that serves as the single source of truth for PR content.

## Input

You will receive:

- Branch name to generate story for
- Base branch (usually `main`)
- Overview-writer JSON output (from parallel agent invoked by `/story`)
- Release-readiness JSON output (from parallel agent invoked by `/story`)
- Performance-analyst output (from parallel agent invoked by `/story`)

## Critical Format Rules

When writing section 4 (Changes), you MUST follow these rules:

1. **Commit hash MUST be GitHub-linked**: `([hash](<repo-url>/commit/<hash>))`
   - Wrong: `(abc1234)` or `(<hash>)`
   - Correct: `([abc1234](<repo-url>/commit/abc1234))`

2. **List ALL files changed as bullet points**, not prose paragraphs

3. **Reference archived ticket's Implementation or Changes section** for the complete file list

## Instructions

1. **Gather Source Data**: Read archived tickets using Glob pattern `.workaholic/tickets/archive/<branch-name>/*.md`. Extract frontmatter (`commit_hash`, `category`) and content (Overview, Final Report).

2. **Calculate Metrics**: Use the "Calculate Metrics" section of the preloaded write-story skill:
   ```bash
   bash .claude/skills/write-story/sh/calculate.sh <base-branch>
   ```

3. **Derive Issue URL**: Extract issue number from branch name (e.g., `i111-20260113-1832` → `111`).

4. **Write Story**: Follow the preloaded write-story skill for content structure, templates, and guidelines.

5. **Write Overview Sections**: Use the overview-writer JSON output to write:
   - Section 1 (Overview): Use `overview` field for the summary paragraph
   - Section 1.1 (Highlights): Format `highlights` array as numbered list
   - Section 2 (Motivation): Use `motivation` field as the narrative paragraph
   - Section 3 (Journey): Use `journey.mermaid` for the flowchart and `journey.summary` for the prose

   Do not invoke overview-writer subagent - it runs in parallel at the orchestrator level.

6. **Write Performance Section**: Use the performance-analyst output provided in the input to write section 9.2 (Performance Analysis). Do not invoke performance-analyst subagent - it runs in parallel at the orchestrator level.

7. **Write Release Preparation**: Use the release-readiness JSON provided in the input to write section 10 (Release Preparation). Do not invoke release-readiness subagent - it runs in parallel at the orchestrator level.

8. **Translate Story**: Create `<branch-name>_ja.md` with Japanese translation following the preloaded translate skill.

9. **Update Index**: Add entry to both `.workaholic/stories/README.md` and `README_ja.md`.

## Output

Return confirmation that:

- Story file was created at `.workaholic/stories/<branch-name>.md`
- Japanese translation was created at `.workaholic/stories/<branch-name>_ja.md`
- Stories index (both README.md and README_ja.md) was updated
- Overview-writer output was formatted into sections 1-3
- Performance-analyst output was formatted into section 9.2
- Release-readiness data was formatted into section 10
