---
type: Routine Template
id: merged-pr
name: "Merged PR {repo_name}"
trigger: event
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# Merged PR — announce a merge into its feedback item's thread

Event-driven (no cron). This is the routine that makes a merge an announceable event,
which is the whole reason every artifact reaches `main` through a pull request.

**It replies; it does not found.** A merge is one event in a feedback item's life, so it
lands in that item's thread rather than as a top-level line of its own. The threading
model, the key and the not-found fallback are stated once in the `workaholify` SKILL,
*One thread per feedback item*; this template implements it and does not restate it.

**Its subject is an external event, which is what made it fragile.** The earlier prompt
said "about the pull request" without ever saying *which*, and a cloud session has no
state and no memory of what was already announced — so when two PRs merged four seconds
apart (2026-08-01 04:19 JST, #135 and #137), two sessions started and **each announced
both**, producing four messages in visibly different wording. N merges landing before
their sessions run gives N sessions × N merges. A single merge in isolation looked
correct, which is why it survived until a productive drive loop merged twice in a minute.

## Prompt

Announce **exactly one** merged pull request: the one whose merge started this session.

First derive its **feedback key** — the filename stem of the feedback record the merged work traces to. It is in the repository, not in Slack: the PR's own diff when the PR published the record, or the `feedback:` field of the mission the PR's tickets name. Then search the channel `dev-[project name]` for `` fb:<stem> `` and reply **in that thread**, in the format below.

-----------
🟣 Proposal merged by @<developer> - [#123 Issue Title](https://github.com/org-name/repo-name/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.
<session URL>

-----------

Rules, in order of precedence:

1. **One message, one pull request.** Never announce more than one, even when several merged recently. Other recent merges are not this session's to report — another session was started for each of them.
2. **If you cannot identify which merge started this session, post nothing and stop.** Silence is the correct failure mode for a notification. Do not fall back to "announce whatever merged most recently": that fallback is exactly the defect this rule exists to prevent, and it produces a message that looks right while being unrelated to the event.
3. Never re-announce a pull request that already has a merge notification in the channel — in a thread or at top level. Check the recent channel history before posting.
4. **A missing key is not a reason to stay silent, and never a reason to post keyless.** If the merge traces to no feedback record, or the record's thread cannot be found, post a **new root** carrying `` `fb:<stem>` `` (or, with genuinely no record, the merged PR's own `#<number>` as the key) and put this message in it. Rule 2 governs *which merge*; this rule governs *where it lands*, and the two must not be confused — a merge you identified always gets posted somewhere attributable.
