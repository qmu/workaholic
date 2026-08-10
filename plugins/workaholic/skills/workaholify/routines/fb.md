---
type: Routine Template
id: fb
name: "[Propose] {repo_name}"
trigger: github-issue-assigned
trigger_kind: github
trigger_event: issues.assigned
trigger_filters: (none - the session checks the assignee itself)
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Propose] — turn a reported ask into a record and the work it warrants

**Fires when a GitHub issue is assigned — for every developer, and `/propose` decides
whether it is theirs** (the routines UI offers no assignee filter, so the trigger cannot
narrow this). The check is the command's, never this prompt's — `/propose` reports
`not_mine` and stops — so the prompt carries no guard. The wiring lives in the GitHub
integration, outside the routine record (`workaholify` SKILL, *What a routine can be
triggered by*).

**The prompt is the developer's own** (P3, reshaped by Q2: three instructions and two
post formats — the start post is formatted too, and both carry the session URL and the
requester's mention) and states no rule
a skill already owns: `workaholic:propose` owns the judgment, the single pull request
and the `[Proposal]` prefix; `workaholic:feedback` owns the record; `workaholic:notify`
owns every notification rule; the always-loaded `rules/` own the standing
prohibitions. The two literal formats below stay embedded rather than deferred — Q2's
reasoning holds: a routine cannot defer its own output contract — but
`workaholic:notify`'s `reference/notifications.md` mirrors them verbatim as the sole
sanctioned shapes for these two events (P10, 2026-08-07), so a future edit to either
copy is a drift to fix, never a second wording to reconcile against a third. The reply thread is **found**, never carried (Q1) — the notify SKILL's
exact-token lookup, not a target read out of the Issue and not a channel name in the prompt — so no
repository is named here and the same prompt pastes into every project. `{repo}` in
the format lines is the developer's own placeholder for the issue and pull request links.

## Prompt

Read the feedback (FB) from the Issue and find its reply thread (the workaholic:notify lookup).

Notify to the thread that proposing process has started:

```
📐 Proposing for [#45 [FB] Issue Title]({repo}/issues/45)
by the [routine](https://claude.ai/code/session_***) of <@U…>
```

After running `/propose [FB]`, notify the thread in the following format:

```
🔵 Proposed - [#123 [Proposal] PR Title]({repo}/pull/123)
by the [routine](https://claude.ai/code/session_***) of <@U…>
```
