---
name: gather
description: Gather git context and ticket metadata in single calls.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
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

## Project Label

Emits a short label — the git repository's directory name, truncated to 12 characters — used as a `[label]` prefix at the start of interactive-prompt question text, so a developer running several Claude Code sessions across tmux panes can tell which repository a waiting dialog belongs to.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh
```

Output:

```json
{
  "project": "workaholic"
}
```

Field: `project` (repo-root basename, ≤12 chars for the header chip). Deliberately network-free — unlike `git-context.sh` it makes no `git remote` call, because it is invoked at prompt time on every question.

## Story Sections

Measures where a branch story's lines actually are, section by section, over any set of story files. It exists because the story template has been edited on assumption: four structural edits landed to make stories shorter and the mean grew instead, and nobody could say which section had absorbed the difference.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/story-sections.sh [--table] <story-file>...
```

Output (JSON by default; `--table` renders the same numbers aligned for a report):

```json
{
  "files": 9,
  "total_lines": 1140,
  "mean_lines": 126.7,
  "sections": [
    { "name": "Changes", "files": 9, "total": 281, "mean": 31.2, "blocks": 9 }
  ]
}
```

`mean` is per **story measured**, not per story carrying the section, so a section present in half the set contributes half as much — the question is what a story costs on average. `blocks` counts the `###` subsections beneath a section, which is what separates "long because it has many blocks" from "its blocks are verbose": Concerns held its block count across the two sets above while its lines per block rose 61%. Ordinals are stripped from heading names (`## 5. Concerns` and `## 6. Concerns` aggregate), frontmatter is excluded, and a `##` line inside a fence is body text rather than a heading.

**Control for workload before reading a delta.** Story length tracks how many tickets the branch drove, so compare sets holding that constant — the cleanest control is to restrict both sets to single-ticket stories. Dividing a whole set's lines by its ticket count is the wrong normalization: multi-ticket stories amortize the per-story overhead, so a heavier set looks *shorter* per ticket while every individual story got longer.
