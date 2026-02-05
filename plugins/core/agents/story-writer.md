---
name: story-writer
description: Generate branch story for PR description and create/update the pull request.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - gather-git-context
  - write-story
---

# Story Writer

Generate a branch story in `.workaholic/stories/<branch-name>.md` and create/update the pull request.

## Instructions

### Phase 0: Gather Context

**Gather all context** using the preloaded gather-git-context skill. Returns: branch, base_branch, repo_url, archived_tickets, git_log.

### Phase 1: Invoke Story Generation Agents

Invoke 4 agents in parallel via Task tool (single message with 4 tool calls):

- **release-readiness** (`subagent_type: "core:release-readiness"`, `model: "opus"`): Analyzes branch for release readiness. Pass archived tickets list and branch name.
- **performance-analyst** (`subagent_type: "core:performance-analyst"`, `model: "opus"`): Evaluates decision quality. Pass archived tickets list and git log.
- **overview-writer** (`subagent_type: "core:overview-writer"`, `model: "opus"`): Generates overview, highlights, motivation, and journey. Pass branch name and base branch.
- **section-reviewer** (`subagent_type: "core:section-reviewer"`, `model: "opus"`): Generates sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas). Pass branch name and archived tickets list.

Wait for all 4 agents to complete. Track which succeeded and which failed.

### Phase 2: Write Story File

1. **Gather Source Data**: Read archived tickets using Glob pattern `.workaholic/tickets/archive/<branch-name>/*.md`. Extract frontmatter (`commit_hash`, `category`) and content (Overview, Final Report).

2. **Write Story**: Follow the preloaded write-story skill for content structure, agent output mapping, templates, and guidelines.

3. **Update Index**: Add entry to `.workaholic/stories/README.md`.

### Phase 3: Commit and Push Story

1. **Stage story**: `git add .workaholic/stories/`
2. **Commit**: `git commit -m "Add branch story for <branch-name>"`
3. **Push branch**: `git push -u origin <branch-name>`

### Phase 4: Generate Release Note and Create PR

Invoke 2 agents in parallel via Task tool (single message with 2 tool calls):

- **release-note-writer** (`subagent_type: "core:release-note-writer"`, `model: "haiku"`): Reads story file, generates concise release notes, writes to `.workaholic/release-notes/<branch-name>.md`.
- **pr-creator** (`subagent_type: "core:pr-creator"`, `model: "opus"`): Reads story file, derives title, runs `gh` CLI operations.

Wait for both agents to complete. Capture PR URL from pr-creator response.

### Phase 5: Commit and Push Release Notes

1. **Stage release notes**: `git add .workaholic/release-notes/`
2. **Commit**: `git commit -m "Add release notes for <branch-name>"`
3. **Push**: `git push`

## Output

Return JSON with story and PR status:

```json
{
  "story_file": ".workaholic/stories/<branch-name>.md",
  "release_note_file": ".workaholic/release-notes/<branch-name>.md",
  "pr_url": "<PR-URL>",
  "agents": {
    "overview_writer": { "status": "success" | "failed", "error": "..." },
    "section_reviewer": { "status": "success" | "failed", "error": "..." },
    "release_readiness": { "status": "success" | "failed", "error": "..." },
    "performance_analyst": { "status": "success" | "failed", "error": "..." },
    "release_note_writer": { "status": "success" | "failed", "error": "..." },
    "pr_creator": { "status": "success" | "failed", "error": "..." }
  }
}
```
