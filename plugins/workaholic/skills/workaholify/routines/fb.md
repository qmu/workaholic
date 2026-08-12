---
type: Routine Template
id: fb
name: "[Propose] {repo_name}"
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 15 * * * *
autofix_on_pr_create: true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Propose] — turn a reported ask into a record and the work it warrants

**Fires on a fixed hourly schedule (:15 — the API floor is one hour)** — FB `20260810085032`/issue #336,
ticket `20260810085347`, 2026-08-10: loop-engineering cadence over instant webhook
reaction, for both `[Propose]` and `[Implement]` (the developer's explicit correction
— an earlier draft of this ticket kept `[Propose]` event-triggered on the reasoning
below; the developer asked for both). Every developer's copy fires independently on
its own tick, and the **data** decides whose work it is exactly as before: `/propose`
reads whatever ask is in hand and reports `not_mine` when it is not theirs.

**The cost this accepts, stated plainly rather than assumed away**: `/propose`'s
design is **the ask in hand** — the reported ask and the ask alone decide what gets
proposed, with `nothing_in_hand` the honest answer when there is none (`CLAUDE.md`,
`/propose` row) — a design that exists *because* the earlier `[Propose Batch]` swept
the backlog instead and was retired for it (`reference/routines.md`, *The retired
routines*). A schedule fire carries no issue number, no assignee, nothing in hand at
all, so a `[Propose]` tick fired purely by the clock reports `nothing_in_hand` and
ends — the schedule alone does not give `/propose` anything new to act on. What the
schedule buys is a periodic sweep for whatever *is* in hand by other means (a
developer-invoked ask, a queued item another surface left for it); it is not a
redesign of `/propose`'s ask-discovery, which stays exactly as documented in
`CLAUDE.md`. Whether `/propose` should eventually gain its own clock-compatible
discovery mechanism is a separate, unscoped question.

**The prompt is the developer's own** (P3, reshaped by Q2: three instructions and two
post formats — the finish post carries the session URL and the
requester's mention) and states no rule
a skill already owns: `workaholic:propose` owns the judgment, the single pull request
and the `[Proposal]` prefix; `workaholic:feedback` owns the record; `workaholic:notify`
owns every notification rule; the always-loaded `rules/` own the standing
prohibitions. The one literal format below stays embedded rather than deferred — Q2's
reasoning holds: a routine cannot defer its own output contract — but
`workaholic:notify`'s `reference/notifications.md` mirrors them verbatim as the sole
sanctioned shapes for these two events (P10, 2026-08-07), so a future edit to either
copy is a drift to fix, never a second wording to reconcile against a third. The reply
thread is **found**, never carried (Q1) — the notify SKILL's exact-token lookup, not a
target read out of a triggering event and not a channel name in the prompt — so no
repository is named here and the same prompt pastes into every project. A schedule
fire carries no specific Issue at all (unlike the retired assignment trigger), so the
lookup runs only when `/propose` actually found an ask in hand. `{repo}` in the format
lines is the developer's own placeholder for the issue and pull request links.

## Prompt

Run `/propose`. If it finds an ask in hand, find its reply thread (the workaholic:notify lookup) and notify it when the run finishes, in the following format — the finish is the only post; there is no "started" line (developer's order, 2026-08-11):

```
🔵 Proposed - [#123 [Proposal] PR Title]({repo}/pull/123)
by the [routine](https://claude.ai/code/session_***) of <@U…>
```
