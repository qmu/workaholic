---
name: story-writer
description: Generate branch story for PR description and create/update the pull request.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - core:gather
  - core:report
---

# Story Writer

Generate a branch story in `.workaholic/stories/<branch-name>.md` and create/update the pull request.

## Instructions

### Phase 0: Gather Context

**Gather all context** using the preloaded gather skill -- run `git-context.sh`. Returns: branch, base_branch, repo_url, archived_tickets, git_log.

### Phase 1: Invoke Story Generation Agents

Invoke 3 agents in parallel via Task tool (single message with 3 tool calls):

- **release-readiness** (`subagent_type: "work:release-readiness"`, `model: "opus"`): Analyzes branch for release readiness. Pass archived tickets list and branch name.
- **overview-writer** (`subagent_type: "work:overview-writer"`, `model: "opus"`): Generates overview, highlights, motivation, and journey. Pass branch name and base branch.
- **section-reviewer** (`subagent_type: "work:section-reviewer"`, `model: "opus"`): Generates sections 4-8 (Outcome, Historical Analysis, Concerns, Ideas, Successful Development Patterns). Pass branch name and archived tickets list.

Wait for all 3 agents to complete. Track which succeeded and which failed.

### Phase 2: Write Story File

1. **Gather Source Data**: Read archived tickets using Glob pattern `.workaholic/tickets/archive/<branch-name>/*.md`. Extract frontmatter (`commit_hash`, `category`) and content (Overview, Final Report).

2. **Write Story**: Follow the preloaded report skill (Write Story section) for content structure, agent output mapping, templates, and guidelines.

3. **Update Index**: Add entry to `.workaholic/stories/README.md`.

### Phase 3: Commit and Push Story

1. **Stage story**: `git add .workaholic/stories/`
2. **Commit**: `git commit -m "Add branch story for <branch-name>"`
3. **Push branch**: `git push -u origin <branch-name>`

### Phase 4: Create PR and Generate Release Note

Run sequentially:

1. **Create PR** first: Invoke **pr-creator** (`subagent_type: "work:pr-creator"`, `model: "opus"`). Reads story file, derives title, runs `gh` CLI operations. Capture PR URL from response.

2. **Generate release note** with PR URL: Invoke **release-note-writer** (`subagent_type: "work:release-note-writer"`, `model: "haiku"`). Pass the PR URL obtained from pr-creator in the prompt. Reads story file, generates concise release notes, writes to `.workaholic/release-notes/<branch-name>.md`.

Capture PR URL from pr-creator response for final output.

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
    "release_note_writer": { "status": "success" | "failed", "error": "..." },
    "pr_creator": { "status": "success" | "failed", "error": "..." }
  }
}
```
