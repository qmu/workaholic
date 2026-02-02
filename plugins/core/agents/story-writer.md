---
name: story-writer
description: Generate branch story for PR description. Reads archived tickets, calculates metrics, and produces narrative documentation.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - write-story
---

# Story Writer

Generate a branch story in `.workaholic/stories/<branch-name>.md` that serves as the single source of truth for PR content.

This agent is the central orchestrator for documentation generation. It invokes 6 subagents in parallel, then integrates their outputs into the story file.

## Input

You will receive:

- Branch name to generate story for
- Base branch (usually `main`)
- Repository URL (for changelog-writer)
- List of archived tickets for the branch
- Git log main..HEAD

## Critical Format Rules

When writing section 4 (Changes), you MUST follow these rules:

1. **Commit hash MUST be GitHub-linked**: `([hash](<repo-url>/commit/<hash>))`
   - Wrong: `(abc1234)` or `(<hash>)`
   - Correct: `([abc1234](<repo-url>/commit/abc1234))`

2. **List ALL files changed as bullet points**, not prose paragraphs

3. **Reference archived ticket's Implementation or Changes section** for the complete file list

## Instructions

### Phase 1: Invoke Documentation Agents

Invoke 6 agents in parallel via Task tool (single message with 6 tool calls):

- **changelog-writer** (`subagent_type: "core:changelog-writer"`): Updates `CHANGELOG.md` with entries from archived tickets. Pass repository URL.
- **spec-writer** (`subagent_type: "core:spec-writer"`): Updates `.workaholic/specs/` to reflect codebase changes. Pass branch name.
- **terms-writer** (`subagent_type: "core:terms-writer"`): Updates `.workaholic/terms/` with new terms. Pass branch name.
- **release-readiness** (`subagent_type: "core:release-readiness"`): Analyzes branch for release readiness. Pass archived tickets list and branch name.
- **performance-analyst** (`subagent_type: "core:performance-analyst"`): Evaluates decision quality. Pass archived tickets list and git log.
- **overview-writer** (`subagent_type: "core:overview-writer"`): Generates overview, highlights, motivation, and journey. Pass branch name and base branch.

Wait for all 6 agents to complete. Track which succeeded and which failed.

### Phase 2: Gather Source Data and Write Story

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

6. **Write Performance Section**: Use the performance-analyst output to write section 9.2 (Performance Analysis).

7. **Write Release Preparation**: Use the release-readiness JSON to write section 10 (Release Preparation).

8. **Translate Story**: Create `<branch-name>_ja.md` with Japanese translation following the preloaded translate skill.

9. **Update Index**: Add entry to both `.workaholic/stories/README.md` and `README_ja.md`.

## Output

Return confirmation that includes:

- Story file was created at `.workaholic/stories/<branch-name>.md`
- Japanese translation was created at `.workaholic/stories/<branch-name>_ja.md`
- Stories index (both README.md and README_ja.md) was updated
- **Agent status report**: List which of the 6 agents succeeded/failed
  - If all succeeded: "All 6 documentation agents completed successfully"
  - If some failed: "Agents succeeded: [list]. Agents failed: [list with error reason]"
