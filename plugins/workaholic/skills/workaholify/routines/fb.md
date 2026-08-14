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

**A schedule fire carries nothing in hand, so `/propose` discovers its own asks**
(developer's instruction, 2026-08-12, closing the cost the schedule migration first
stated as unresolved): a tick that starts with no argument, no fresh record and no
trigger payload runs the propose skill's *Clock-fired discovery* —
`list-inbound-issues.sh` lists the open GitHub issues on this repository assigned to
the session's own identity, minus those a feedback record already names — and takes
each returned issue as an ask in hand, oldest-first, one full run per issue. This is
**not** the retired `[Propose Batch]` sweep (`reference/routines.md`, *The retired
routines*): that read the repository's own backlog for something to propose; this
reads the inbound ask channel — the issues the retired event trigger used to hand
over one at a time — and feedback stays the only input that can originate a proposal.
A tick whose discovery returns nothing still reports `nothing_in_hand` and ends —
the honest answer, now meaning "the inbox is empty" rather than "I could not look".

**The prompt is the developer's own** (P3, reshaped by Q2, trimmed again 2026-08-12 after
the developer read dated decision notes in the live prompt: the command, the load
fallback, and one literal finish shape carrying the session URL and the requester's
mention — plus, since 2026-08-14, the description root the finish replies into when
the lookup finds no thread, which the ceiling rule requires the prompt to name before
any session may emit it) and states no rule
a skill already owns: `workaholic:propose` owns the judgment, the single pull request
and the `[Proposal]` prefix; `workaholic:feedback` owns the record; `workaholic:notify`
owns every notification rule; the always-loaded `rules/` own the standing
prohibitions. The one literal format below stays embedded rather than deferred — Q2's
reasoning holds: a routine cannot defer its own output contract — but
`workaholic:notify`'s `reference/notifications.md` mirrors them verbatim as the sole
sanctioned shapes for these two events (P10, 2026-08-07), so a future edit to either
copy is a drift to fix, never a second wording to reconcile against a third. The root
block is copied from that catalog **byte for byte**, placeholders included, so the two
copies diff clean — `<repo-url>` there is the `{repo}` of the finish line above it. The reply
thread is **found**, never carried (Q1) — the notify SKILL's exact-token lookup, not a
target read out of a triggering event and not a channel name in the prompt — so no
repository is named here and the same prompt pastes into every project. A schedule
fire carries no specific Issue in its payload (unlike the retired assignment
trigger) — the issues come from `/propose`'s own clock-fired discovery — so the
lookup runs once per ask `/propose` actually took in hand. `{repo}` in the format
lines is the developer's own placeholder for the issue and pull request links.

## Prompt

Run `/propose`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/propose.md` and follow it with every script path under `<src>`.

If it finds an ask in hand, post one finish line into its reply thread (the workaholic:notify lookup):

```
🔵 Proposed - [#123 [Proposal] PR Title]({repo}/pull/123)
by the [routine](https://claude.ai/code/session_***) of <@U…>
```

If that lookup finds no thread, post this description root first and the finish line above as a reply into it — no mention token of any kind on the root:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
`fb:<stem>`
<session URL>
```
