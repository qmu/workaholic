---
name: gather
description: Gather git context and ticket metadata in single calls.
allowed-tools: Bash
user-invocable: false
---

# Gather

Bundled probes that emit JSON for the work flow. Each script is independent; preload this skill once and call whichever script you need.

## Git Context

Gathers all context needed for documentation subagents in a single shell script call.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh
```

Output:

```json
{
  "branch": "feature-branch-name",
  "base_branch": "main",
  "repo_url": "https://github.com/owner/repo",
  "archived_tickets": [".workaholic/tickets/archive/branch/ticket1.md", "..."],
  "git_log": "abc1234 First commit\ndef5678 Second commit"
}
```

Fields: `branch` (current branch), `base_branch` (default branch of the remote), `repo_url` (HTTPS form; SSH URLs are converted), `archived_tickets` (array of ticket paths for current branch), `git_log` (oneline log from base to HEAD).

## Ticket Metadata

Gathers all dynamic metadata values needed for ticket frontmatter in a single shell script call.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh
```

Output:

```json
{
  "created_at": "2026-01-31T19:25:46+09:00",
  "author": "developer@company.com",
  "filename_timestamp": "20260131192546"
}
```

Fields: `created_at` (ISO 8601 with timezone for frontmatter), `author` (git user email), `filename_timestamp` (YYYYMMDDHHmmss for the ticket filename).
