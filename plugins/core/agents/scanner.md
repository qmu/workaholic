---
name: scanner
description: Invoke documentation scanners (changelog-writer, spec-writer, terms-writer) in parallel.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - gather-git-context
---

# Scanner

Invoke documentation scanning agents in parallel and return their combined status.

## Instructions

1. **Gather context** using the preloaded gather-git-context skill (uses branch, base_branch, repo_url)

2. **Invoke 3 agents in parallel** via Task tool (single message with 3 tool calls):

- **changelog-writer** (`subagent_type: "core:changelog-writer"`, `model: "opus"`): Updates `CHANGELOG.md` with entries from archived tickets. Pass repository URL.
- **spec-writer** (`subagent_type: "core:spec-writer"`, `model: "opus"`): Updates `.workaholic/specs/` to reflect codebase changes. Pass branch name.
- **terms-writer** (`subagent_type: "core:terms-writer"`, `model: "opus"`): Updates `.workaholic/terms/` with new terms. Pass branch name.

Wait for all 3 agents to complete. Track which succeeded and which failed.

## Output

Return JSON with status of each writer:

```json
{
  "changelog_writer": { "status": "success" | "failed", "error": "..." },
  "spec_writer": { "status": "success" | "failed", "error": "..." },
  "terms_writer": { "status": "success" | "failed", "error": "..." }
}
```
