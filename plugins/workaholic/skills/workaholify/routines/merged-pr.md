---
type: Routine Template
id: merged-pr
name: "Merged PR {repo_name}"
trigger: event
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# Merged PR — announce a merge to Slack

Event-driven (no cron). This is the routine that makes a merge an announceable event,
which is the whole reason every artifact reaches `main` through a pull request.

## Prompt

Post short notification to the slack channel "dev-[project name]" about the pull request by the format below:

-----------
🟣 PR merged - [#123 Issue Title](https://github.com/org-name/repo-name/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.

{{#if blocker}}
⚠️ Attention
- One line, max 25 words.
{{/if}}
-----------
