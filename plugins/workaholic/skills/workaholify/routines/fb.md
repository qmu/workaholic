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

**Deliberately kept event-triggered, not moved to a schedule** (FB `20260810085032`/
issue #336 asked for both `[Propose]` and `[Implement]` to move; only `[Implement]`
did — `implement.md`, ticket `20260810085347`). `/propose`'s whole design is **the ask
in hand**: the reported ask and the ask alone decide what gets proposed, with
`nothing_in_hand` the honest answer when there is none (`CLAUDE.md`, `/propose` row) —
a design that exists *because* the earlier `[Propose Batch]` swept the backlog instead
and was retired for it (`reference/routines.md`, *The retired routines*). A schedule
fire carries no issue number, no assignee, nothing in hand at all — every tick would
report `nothing_in_hand` unless `/propose` grew a sweep back, which is the exact
mechanism this repository already rejected once. `[Implement]` has no such conflict:
it is survey-driven, not ask-driven, so a schedule fire loses nothing but the merge
event's instant start. Revisiting this would mean redesigning how `/propose`
discovers an ask under a clock instead of an event — out of scope here; tracked as its
own concern rather than assumed away.

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
