---
type: Routine Template
id: fb
name: "[FB] {repo_name}"
trigger: event
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [FB] — turn a Slack-reported issue into a feedback record and a PR

Event-driven (no cron): it fires on the inbound report, not on a clock.

## Prompt

- Use qmu/workaholic skills, don't proceed without workaholic
- /fb and /propose via pull request
- Brief PR description, detail in file, and refer FB issue number to close when merged
- Notify Slack channel `dev-[repo name]` when PR created by the format below:

------------
🟢 PR opened - [#123 Issue Title](https://github.com/org-name/repo-name/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.

{{#if blocker}}
⚠️ Attention
- One line, max 25 words.
{{/if}}
------
