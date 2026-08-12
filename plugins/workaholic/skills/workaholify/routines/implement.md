---
type: Routine Template
id: implement
name: "[Implement] {repo_name}"
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 30 * * * *
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Implement] — the unattended executor

**Fires on a fixed hourly schedule (:30 — the API floor is one hour)** — FB `20260810085032`/issue #336:
loop-engineering cadence over instant reaction on the merge event. Every developer's
copy fires independently, and the **data** decides whose work it is: a proposal
carries the triggering issue's assignee as its `assignees`, so a runner whose work
this is not surveys, sees `owned_by_other`, takes nothing, and ends `ok`. No prompt change is needed for this — the survey already filters ownership, and the survey
itself (not a trigger payload) is what decides what gets driven this tick — a
schedule fire carries no PR/issue context at all, unlike the retired merge-event
trigger. **The tradeoff this reintroduces**: `[Implement]` no longer starts the
instant a `[Proposal]` PR merges — a merged proposal now waits up to 30 minutes for
the next tick, same as any other claimable backlog item (`workaholic:workaholify`
SKILL, *Routines*; `reference/routines.md`, *The trigger surface, measured*). The
wiring is entered by hand in the routines UI; the `trigger_kind`/`cron_expression`
keys declare the design, not a stored field a session can read back (no
`RemoteTrigger`-family tool is exposed to this session — verified empty by
`ToolSearch`, ticket `20260810085351`).

**The prompt is the developer's own** (P3, reshaped by Q2: three instructions and two
post formats — the finish post carries the session URL and the
requester's mention) and states no rule
a skill already owns: `workaholic:drive` owns the run and its terminal contract,
`workaholic:notify` owns every notification rule (the stateless thread lookup, red-alert
dedup, mention resolution), and the always-loaded `rules/` own the standing prohibitions.
The one literal format below stays embedded rather than deferred — Q2's reasoning holds:
a routine cannot defer its own output contract — but `workaholic:notify`'s
`reference/notifications.md` mirrors them verbatim as the sole sanctioned shapes for
these two events (P10, 2026-08-07), so a future edit to either copy is a drift to fix,
never a second wording to reconcile against a third.
The reply thread is **found**, never carried (Q1) — the notify SKILL's exact-token lookup, not a
target read out of a triggering event and not a channel name in the prompt — so no
repository is named here and the same prompt pastes into every project. A schedule
fire carries no single PR/issue at all (unlike the retired merge-event trigger), so
the lookup runs **per claimed unit** — `workaholic:drive`'s own §3/§6 already resolve
each unit's feedback-item thread via `unit-feedback-stems.sh`, this prompt only fixes
the two literal post shapes. `{repo}` in the format lines is the developer's own
placeholder for the pull request links. (Named `[Drive]` until P1, when the
unattended executor became `/implement`.)

## Prompt

Run `/implement`. For each PR-unit it claims, find its reply thread (the workaholic:notify lookup) and notify it when the unit finishes, in the following format — the finish is the only post; there is no "started" line (developer's order, 2026-08-11); and if the run stops before claiming anything, on a precondition-stop signature (`workaholic:notify`, the closed `unbound_in_claude_session`/`loaded_version_behind_registry` list), post the calm-first, escalate-on-persistence shape notify defines for it instead:

```
🟢 Implemented - [#123 Title]({repo}/pull/123)
by the [routine](https://claude.ai/code/session_***) of <@U…>
```
