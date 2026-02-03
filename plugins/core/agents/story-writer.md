---
name: story-writer
description: Invoke story generation agents (overview-writer, section-reviewer, release-readiness, performance-analyst) in parallel.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
---

# Story Writer

Invoke story generation agents in parallel and return their combined outputs for integration by story-moderator.

## Input

You will receive:

- Branch name to generate story for
- Base branch (usually `main`)
- Repository URL
- List of archived tickets for the branch
- Git log main..HEAD

## Instructions

Invoke 4 agents in parallel via Task tool (single message with 4 tool calls):

- **release-readiness** (`subagent_type: "core:release-readiness"`, `model: "opus"`): Analyzes branch for release readiness. Pass archived tickets list and branch name.
- **performance-analyst** (`subagent_type: "core:performance-analyst"`, `model: "opus"`): Evaluates decision quality. Pass archived tickets list and git log.
- **overview-writer** (`subagent_type: "core:overview-writer"`, `model: "opus"`): Generates overview, highlights, motivation, and journey. Pass branch name and base branch.
- **section-reviewer** (`subagent_type: "core:section-reviewer"`, `model: "opus"`): Generates sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas). Pass branch name and archived tickets list.

Wait for all 4 agents to complete. Track which succeeded and which failed.

## Output

Return JSON with outputs from each agent:

```json
{
  "overview_writer": { "status": "success" | "failed", "output": {...}, "error": "..." },
  "section_reviewer": { "status": "success" | "failed", "output": {...}, "error": "..." },
  "release_readiness": { "status": "success" | "failed", "output": {...}, "error": "..." },
  "performance_analyst": { "status": "success" | "failed", "output": "...", "error": "..." }
}
```

The `output` field contains the structured data from each agent that story-moderator uses for story integration.
