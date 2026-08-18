---
created_at: 2026-08-17T11:37:54+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817113750-add-the-housekeep-command-and-skill.md
mission: add-the-housekeep-hourly-operations-routine
merge_policy:
verification_handoff: 
---

# Implement the human check-in step

## Overview

Step 9 of the ask: ask humans questions when there is something worth confirming — at most
five per run, and never during late-night hours.

The step exists because the eight steps before it will keep finding things they cannot
decide, and the loop's current answer to that is to write them down and move on (an
`## Open Decisions` item, a deferred concern). This step gives the tick a way to actually
ask. What it may not do is use `AskUserQuestion`: a routine-fired session has nobody
watching, and the whole unattended contract turns on that. The question goes to Slack.

## Policies

- `workaholic:operation` / `policies/observability.md` — a question nobody sees is not a question
- `workaholic:development` / `policies/code-of-conduct.md` — an hourly agent asking questions is a demand on people's attention
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — **The bright line** (what earns a post),
  *The prompt is the ceiling* (a shape must be named in the routine's prompt), the red-alert
  cool-down (the existing precedent for time-based suppression), and the mention rules: a
  person is `<@U…>` resolved from their email; a Claude mention token on a routine's own
  post re-triggers the app and is prohibited.
- `plugins/workaholic/rules/interaction.md` — the **Recommended-label test**: if an option
  could honestly be marked "(Recommended)", do not ask. This is the bar that keeps five
  questions an hour from becoming five questions an hour.
- `plugins/workaholic/skills/gather/scripts/owners.sh` — who to address; empty `assignees`
  means team-owned, and a question to nobody in particular is a question nobody answers.
- `plugins/workaholic/skills/housekeep/` — the tick log, which is where an asked question
  and its answer are recorded.

## Implementation Steps

1. Collect the tick's genuinely undecidable items from the other eight steps — not
   everything they skipped. Apply the Recommended-label test to each: an item with an
   honest recommendation is **decided and recorded**, never asked.
2. Rank and cap at five. The cap is a ceiling, not a quota: most ticks should ask zero.
3. Apply the quiet-hours gate (Open Decision 1) before posting. A question suppressed by
   quiet hours is **held, not dropped** — carried to the next eligible tick — and the log
   says so.
4. Post as one message per question, each into the thread of the item it concerns (the
   stateless lookup: exact-string `fb:<stem>`, then the issue/PR URL, then a new keyed
   root), addressed to the resolved owner with `<@U…>`. Never a bare `@name` — it pings
   nobody.
5. Dedup on the question's own content key, the way the red-alert cool-down and
   `deploy:<digest>` both do: the same unanswered question is not re-asked every hour.
6. Record each asked question and, when it arrives, its answer in the tick log and — if it
   resolves something durable — as a `kind: answer` feedback record.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- At most five questions per tick, and zero when nothing passes the Recommended-label test.
- No `AskUserQuestion` call anywhere in the step.
- The same unanswered question is asked once, not once per hour.
- No question is posted inside the configured quiet window; suppressed questions are held
  and reported, never dropped.
- Every question carries a resolved `<@U…>` mention of a person, and no Claude mention
  token.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Two consecutive ticks with the same open question: the second posts nothing.
- A tick simulated inside the quiet window: nothing posted, the question held, the log
  naming the suppression.

**Gate** — what must pass before approval:

- The Open Decisions resolved and recorded in the Final Report.

## Open Decisions

1. **What is "late-night", in whose clock?** The workspace's timezone is `Asia/Tokyo`, but
   the routine runs in a container whose clock is UTC and a team may span timezones. The
   boundary needs a start hour, an end hour, and a rule for whose local time governs — the
   addressed person's Slack profile timezone is available and is the most defensible input,
   at the cost of making the gate per-recipient rather than per-tick.
2. **Does an unanswered question ever escalate?** The red-alert cool-down posts a
   `↳ still failing` reply on persistence. A question that goes unanswered for days is
   either not worth asking or worth re-raising, and the two need different handling.
   Silence is not consent, and the step must not treat it as an answer.

## Considerations

- **Five questions an hour is 120 a day at the ceiling.** The cap alone does not protect
  anyone's attention; the Recommended-label test does. Consider a second bound the cap
  cannot exceed — questions per day, not per tick.
- The answer path is the harder half: a question posted with no way to record its answer
  produces a thread the loop cannot read back. Wiring the answer into a `kind: answer`
  record is what closes the loop.

## Final Report

Development completed as planned. Both Open Decisions resolved, with the reasoning recorded in
`ask-question.sh` and `reference/workflow.md` where the next reader meets them.

1. **What is "late-night", in whose clock? — One gate per tick, in the workspace's timezone.**
   Default `Asia/Tokyo`, 22:00–08:00; both overridable (`WORKAHOLIC_QUIET_TZ`,
   `WORKAHOLIC_QUIET_HOURS`). The per-recipient alternative the ticket named as most defensible —
   each addressee's Slack profile timezone — was considered and not taken, for a reason the ticket
   itself supplies: a suppressed question is **held, not dropped**, so a coarse gate costs a few
   hours of delay rather than a lost question, while a per-recipient gate costs a profile read per
   person per tick against a surface this project deliberately keeps to exact-string queries. The
   gate is one function reading one zone, so swapping it later is a small change rather than a
   rewrite.
2. **Does an unanswered question escalate? — No, and silence is never treated as an answer.** A
   question is asked once (content-keyed) and never re-posted. The red-alert `↳ still failing`
   precedent covers a *machine-observable state that persists*; a question is a *demand on a
   person's attention*, and repeating it hourly turns asking into nagging — which the
   code-of-conduct policy names as a real cost. The unanswered set stays visible where humans
   already look (the tick log, the run report) and the post is still sitting in its thread.

The Consideration's second bound is implemented rather than noted: five per tick is 120 a day at
the ceiling, so `--max-per-day` (default 10) is the bound the per-tick cap cannot aggregate past.
Both are one constant each, in one place.

### Discovered Insights

- **Insight**: The tick log's idempotence is per `(tick, step)`, so a step that records **several**
  facts in one tick cannot use one step id. Five questions in a tick are five ids
  (`human-checkin-ask-<slug>`), and counting them needs the new `--step-prefix` on `log-read.sh`.
  **Context**: This is the general shape for any future step that acts more than once per tick —
  spell each act as its own id and count by prefix. Reusing one id would have silently capped the
  step at one question per tick while appearing to work.

- **Insight**: The gate/composer split is what makes a ceiling real. *Whether* something is worth
  asking is a judgement (the Recommended-label test) and belongs to the model; *how many, when,
  and was this asked before* are mechanical and belong to a script.
  **Context**: A model asked to police its own volume does it inconsistently, and inconsistency in
  this particular dimension is spent human attention. The same split is why `ask-question.sh`
  hands back the `log_step` to record under rather than trusting the caller to invent it.

- **Insight**: "Held, not dropped" needs a place to live, and the tick log is it —
  `human-checkin-held-<slug>` written by the agent, read back by the step on the next eligible
  tick, and dropping out once the question has been asked.
  **Context**: Without that, quiet hours would be indistinguishable from a lost question, and the
  cheap per-tick timezone gate would not have been affordable at all.
