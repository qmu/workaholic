---
type: Routine Template
id: implement
name: "[Implement] {repo_name}"
scope: developer
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 30 * * * *
autofix_on_pr_create: true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Implement] — the unattended executor

**`scope: developer`** — every developer needs their own copy, so `/setup-dev-routines`
converges it and `/setup-repo-routines` never sees it. The scope is the template's own
field because both commands and both setup sheets have to read one source
(`workaholic:workaholify` §5, *Two scopes, two commands*).

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

**The prompt is the developer's own** (P3, reshaped by Q2, trimmed again 2026-08-12 after
the developer read dated decision notes in the live prompt: the command, the load
fallback, and one literal finish shape carrying the session URL and the requester's
mention — nothing else) and states no rule
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
the literal finish shape. `{repo}` in the format lines is the developer's own
placeholder for the pull request links. (Named `[Drive]` until P1, when the
unattended executor became `/implement`.)

## Prompt

Run `/implement`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/implement.md` and follow it with every script path under `<src>`.

Post one finish line per claimed PR-unit into its reply thread (the workaholic:notify lookup) — one line per unit, never one per feedback stem:

```
🟢 Implemented - [#123 Title]({repo}/pull/123)
by the [routine](https://claude.ai/code/session_***) of <@U…>
```

If that lookup finds no thread, post this description root first and the finish line above as a reply into it — no mention token of any kind on the root:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
`fb:<stem>`
<session URL>
```

If the run stops before claiming anything, post notify's precondition-stop shape instead.
