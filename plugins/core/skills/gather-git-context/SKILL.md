---
name: gather-git-context
description: Gather git context and branch data in one call.
allowed-tools: Bash
user-invocable: false
---

# Gather Git Context

Gathers all context needed for documentation subagents in a single shell script call.

## Usage

```bash
bash .claude/skills/gather-git-context/sh/gather.sh
```

## Output

JSON with all context values:

```json
{
  "branch": "feature-branch-name",
  "base_branch": "main",
  "repo_url": "git@github.com:owner/repo.git",
  "archived_tickets": [".workaholic/tickets/archive/branch/ticket1.md", "..."],
  "git_log": "abc1234 First commit\\ndef5678 Second commit"
}
```

## Fields

- **branch**: Current branch name
- **base_branch**: Default branch of the remote (usually `main`)
- **repo_url**: Remote origin URL
- **archived_tickets**: Array of archived ticket paths for current branch
- **git_log**: Git log from base branch to HEAD (oneline format)
