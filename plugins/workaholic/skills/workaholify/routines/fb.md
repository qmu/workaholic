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

Its announcement names a PR this session created, so the ambiguity that broke `merged-pr`
does not arise — the scoping is stated anyway, because "the pull request" reads the same
in both and the next editor should not have to work out which case they are in.

## Prompt

- Use qmu/workaholic skills, don't proceed without workaholic
- /fb via pull request. Do NOT run /propose here: the record you just wrote is still on an unmerged branch, so the proposal batch's window cannot see it by design. Proposals ride the scheduled `[Propose]` routine, which picks the record up once this PR merges.
- Brief PR description, detail in file, and refer FB issue number to close when merged
- Notify Slack channel `dev-[repo name]` when PR created by the format below. Announce **only the pull request you just created in this session**, exactly once; never announce another session's PR, and post nothing if you created none:

------------
🟢 PR opened - [#123 Issue Title](https://github.com/org-name/repo-name/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.

------
