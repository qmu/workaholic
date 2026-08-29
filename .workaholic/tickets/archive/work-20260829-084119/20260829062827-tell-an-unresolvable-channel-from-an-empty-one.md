---
created_at: 2026-08-29T06:28:27+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: point-the-inbound-readers-at-the-channel-that-exists
merge_policy:
verification_handoff: 
---

# Tell an unresolvable channel from an empty one

## Overview

PROPOSED. A channel name that resolves to no channel is a different fact from a channel
with nothing waiting in it, and today only the second is ever visible. Both readers report
their reason honestly inside the tick, but neither fact reaches a person, so from outside
the tick a dark inbound path and a calm hour are indistinguishable — which is why this
divergence ran for a day before a tick happened to name it.

Setting the channel (the ticket beside this one) fixes today's instance. This ticket is
what makes the **next** one visible, and it is the half that survives whatever the channel
is called.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` — reports
  `degraded` with a named reason today; the question is which reasons reach a person.
- `plugins/workaholic/skills/propose/SKILL.md` — the sweep's degradation vocabulary
  (`no_slack_transport`, `channel_unreadable`, `sweep_dedup_unreadable`).
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the findings classification
  table, and the step contracts that decide what supplies an `event`.
- `plugins/workaholic/skills/workaholify/scripts/check-slack-channel.sh` — read its header
  first: it already refuses to report "cannot check" as "does not exist", and that
  distinction is the one this ticket must not lose.

## Implementation Steps

1. Read `check-slack-channel.sh`'s header before designing anything. Slack answers
   "not found" for a channel the calling token cannot **see**, so *absent* and *invisible*
   are the same response — a reader that reports "this channel does not exist" would be
   reintroducing that script's own 2026-08-01 bug at a different seam.
2. So the fact to surface is the honest one: **the channel could not be read**, named
   distinctly from **the channel was read and held nothing**. Do not claim absence.
3. Give the unreadable case a route to a person, in the shape the tick already has — a
   step's `event`, or a keyed question — rather than a new surface. Decide and state which,
   with the reason; an hourly restatement of an unchanged reading is what this repository
   has retired two roots for, so whatever is chosen must be quiet when nothing changed.
4. Report the channel **name** the reader resolved, so a divergence is legible from the
   report without anyone re-deriving it.
5. Update the step contracts and the findings table in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `could not read the channel` and `channel held nothing` are distinct, named outcomes.
- Neither claims a channel is absent — the invisible/absent ambiguity is preserved.
- The unreadable case reaches a person by an existing route, quiet when unchanged.
- The resolved channel name is in the report.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- A fixture with an unresolvable channel produces a different, named outcome from one with
  an empty window, and a second tick over an unchanged reading is silent.

## Considerations

The tempting shape is a loud alert on every tick that cannot read the channel. That is the
`📦 Release Preparation` failure this repository retired: an unchanged answer restated
hourly. Whatever route is chosen has to be silent while the reading is unchanged, which is
the property the tick's diff-against-the-previous-tick already provides.

## Final Report

Development completed as planned.

`check-slack-channel.sh`'s header was read first, as step 1 requires, and its rule is the
one this change is built around: Slack answers *not found* for a channel the calling token
cannot **see**, so absent and invisible are one response. Nothing here claims a channel is
absent — the fact surfaced is the honest one, *the channel could not be read*.

The agent's read now has **three** outcomes named apart in the step's own contract:
`asks_found`, `window_empty` (the channel **was** read and held nothing — an ordinary quiet
hour) and `channel_unreadable` (the read did not happen).

**The route is the one the tick already has.** On `channel_unreadable` only, one question
goes through `ask-question.sh` keyed `inbound-channel-unreadable:<channel>` — so the
asked-once gate is what makes it quiet while the reading is unchanged, rather than a
suppression list, and the per-tick cap, the quiet hours and the working-day hold apply
untouched. A new surface was refused: an hourly restatement of an unchanged reading is the
`📦 Release Preparation` failure this repository retired. The cost is stated rather than
hidden — a channel that breaks, is fixed and breaks again is not re-asked, the same
property `base-red:<commit>` and `stalled-unit:<unit>` already carry; a **different**
channel is a different key, which is the change that actually matters.
`no_slack_transport` asks nothing: it is this session holding no connector, not a fact
about the channel.

The **resolved channel name** rides the summary and is asked for in the report, on both
readers — the tick step and the `:40` sweep — so a divergence between the channel the loop
posts to and the one it reads is legible without anyone re-deriving the default. That is
exactly what let one run for a day.

Contracts updated in the same change: `moderate/reference/workflow.md` §16 (the three
outcomes as a table, the never-claim-absence rule, the quietness argument and its cost) and
its findings-classification row, plus `propose/SKILL.md`'s degradation vocabulary. The
classification stays `needs_ruling`: a channel the tick could not read needs a connector, a
token or a name, and only a person supplies one.

### Discovered Insights

- **Insight**: `.claude/settings.json`'s `env` block **does** reach every Bash invocation in
  a session started in this repository — measured directly this run:
  `printenv CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` returns `1`, from that block.
  **Context**: it is read at **session start**, so a value added mid-session is not visible
  to that session — which is why the sibling ticket's setting reads as absent here and will
  take effect from the next container. That makes the settings `env` block a verified home
  for a repository-scoped `WORKAHOLIC_*` value, and the verification is a one-line
  `printenv` rather than an argument.
