---
type: Routine Template
id: implement
name: "[Implement] {repo_name}"
trigger: github-pr-merged
trigger_kind: github
trigger_event: pull_request.closed
trigger_filters: is merged = true; title contains [Proposal]
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Implement] — the unattended executor

**Fires when a proposal's pull request merges** — for every developer's copy, and the
**data** decides whose work it is: a proposal carries the triggering issue's assignee
as its `assignees`, so a runner whose work this is not surveys, sees `owned_by_other`,
takes nothing, and ends `ok`. No prompt change is needed for this — the survey already
filters ownership. The wiring is set in the routines UI; the `trigger_*` keys declare
the design, not a stored field.

**The prompt is the developer's own** (P3, reshaped by Q2: three instructions and two
post formats — the start post is formatted too, and both carry the session URL and the
requester's mention) and states no rule
a skill already owns: `workaholic:drive` owns the run and its terminal contract,
`workaholic:notify` owns every notification rule (the stateless thread lookup, red-alert
dedup, mention resolution), and the always-loaded `rules/` own the standing prohibitions.
The two literal formats below stay embedded rather than deferred — Q2's reasoning holds:
a routine cannot defer its own output contract — but `workaholic:notify`'s
`reference/notifications.md` mirrors them verbatim as the sole sanctioned shapes for
these two events (P10, 2026-08-07), so a future edit to either copy is a drift to fix,
never a second wording to reconcile against a third.
The reply thread is **found**, never carried (Q1) — the notify SKILL's exact-token lookup, not a
target read out of the pull request and not a channel name in the prompt — so no
repository is named here and the same prompt pastes into every project. `{repo}` in
the format lines is the developer's own placeholder for the pull request links. (Named
`[Drive]` until P1, when the unattended executor became `/implement`.)

## Prompt

Read the Mission/Ticket from the PR and find its reply thread (the workaholic:notify lookup).

Notify to the thread that implementation has started:

```
🟠 Implementing for [#123 Proposal PR Title]({repo}/pull/123)
by [Claude Code on the Web](https://claude.ai/code/session_***) of <@U…>
```

After running `/implement [Mission/Ticket]`, notify the thread in the following format:

```
🟢 Implemented - [#123 Title]({repo}/pull/123)
by [Claude Code on the Web](https://claude.ai/code/session_***) of <@U…>
```
