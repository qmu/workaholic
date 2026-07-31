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

**Its subject is an external event, which is what made it fragile.** The earlier prompt
said "about the pull request" without ever saying *which*, and a cloud session has no
state and no memory of what was already announced — so when two PRs merged four seconds
apart (2026-08-01 04:19 JST, #135 and #137), two sessions started and **each announced
both**, producing four messages in visibly different wording. N merges landing before
their sessions run gives N sessions × N merges. A single merge in isolation looked
correct, which is why it survived until a productive drive loop merged twice in a minute.

## Prompt

Announce **exactly one** merged pull request: the one whose merge started this session.

Post to the Slack channel "dev-[project name]" in the format below.

-----------
🟣 PR merged - [#123 Issue Title](https://github.com/org-name/repo-name/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.

-----------

Rules, in order of precedence:

1. **One message, one pull request.** Never announce more than one, even when several merged recently. Other recent merges are not this session's to report — another session was started for each of them.
2. **If you cannot identify which merge started this session, post nothing and stop.** Silence is the correct failure mode for a notification. Do not fall back to "announce whatever merged most recently": that fallback is exactly the defect this rule exists to prevent, and it produces a message that looks right while being unrelated to the event.
3. Never re-announce a pull request that already has a merge notification in the channel. Check the recent channel history before posting.
