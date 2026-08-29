---
created_at: 2026-08-29T06:28:27+00:00
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
