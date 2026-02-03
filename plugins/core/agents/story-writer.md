---
name: story-writer
description: Generate branch story for PR description and create/update the pull request.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - write-story
---

# Story Writer

Generate a branch story in `.workaholic/stories/<branch-name>.md` and create/update the pull request.

## Input

You will receive:

- Branch name to generate story for
- Base branch (usually `main`)
- Repository URL
- List of archived tickets for the branch
- Git log main..HEAD

## Instructions

### Phase 1: Invoke Story Generation Agents

Invoke 4 agents in parallel via Task tool (single message with 4 tool calls):

- **release-readiness** (`subagent_type: "core:release-readiness"`, `model: "opus"`): Analyzes branch for release readiness. Pass archived tickets list and branch name.
- **performance-analyst** (`subagent_type: "core:performance-analyst"`, `model: "opus"`): Evaluates decision quality. Pass archived tickets list and git log.
- **overview-writer** (`subagent_type: "core:overview-writer"`, `model: "opus"`): Generates overview, highlights, motivation, and journey. Pass branch name and base branch.
- **section-reviewer** (`subagent_type: "core:section-reviewer"`, `model: "opus"`): Generates sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas). Pass branch name and archived tickets list.

Wait for all 4 agents to complete. Track which succeeded and which failed.

### Phase 2: Write Story File

1. **Gather Source Data**: Read archived tickets using Glob pattern `.workaholic/tickets/archive/<branch-name>/*.md`. Extract frontmatter (`commit_hash`, `category`) and content (Overview, Final Report).

2. **Calculate Metrics**: Use the preloaded write-story skill:
   ```bash
   bash .claude/skills/write-story/sh/calculate.sh <base-branch>
   ```

3. **Derive Issue URL**: Extract issue number from branch name (e.g., `i111-20260113-1832` -> `111`).

4. **Write Story**: Follow the preloaded write-story skill for content structure, templates, and guidelines.

5. **Write Overview Sections**: Use the overview-writer JSON output to write:
   - Section 1 (Overview): Use `overview` field for the summary paragraph
   - Section 1.1 (Highlights): Format `highlights` array as numbered list
   - Section 2 (Motivation): Use `motivation` field as the narrative paragraph
   - Section 3 (Journey): Use `journey.mermaid` for the flowchart and `journey.summary` for the prose

6. **Write Review Sections**: Use the section-reviewer JSON output to write:
   - Section 5 (Outcome): Use `outcome` field
   - Section 6 (Historical Analysis): Use `historical_analysis` field
   - Section 7 (Concerns): Use `concerns` field
   - Section 8 (Ideas): Use `ideas` field

7. **Write Performance Section**: Use the performance-analyst output to write section 9.2 (Performance Analysis).

8. **Write Release Preparation**: Use the release-readiness JSON to write section 10 (Release Preparation).

9. **Translate Story**: Create `<branch-name>_ja.md` with Japanese translation.

10. **Update Index**: Add entry to both `.workaholic/stories/README.md` and `README_ja.md`.

### Phase 3: Create Pull Request

Invoke **pr-creator** (`subagent_type: "core:pr-creator"`, `model: "opus"`):
- Pass branch name and base branch
- The subagent handles: checking if PR exists, reading story file, deriving title, `gh` CLI operations
- Capture the PR URL from the response

## Output

Return JSON with story and PR status:

```json
{
  "story_file": ".workaholic/stories/<branch-name>.md",
  "story_file_ja": ".workaholic/stories/<branch-name>_ja.md",
  "pr_url": "<PR-URL>",
  "agents": {
    "overview_writer": { "status": "success" | "failed", "error": "..." },
    "section_reviewer": { "status": "success" | "failed", "error": "..." },
    "release_readiness": { "status": "success" | "failed", "error": "..." },
    "performance_analyst": { "status": "success" | "failed", "error": "..." },
    "pr_creator": { "status": "success" | "failed", "error": "..." }
  }
}
```
