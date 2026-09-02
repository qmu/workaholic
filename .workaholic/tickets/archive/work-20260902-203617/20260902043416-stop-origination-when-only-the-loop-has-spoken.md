---
created_at: 2026-09-02T04:34:16+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refuse-an-ask-the-loop-wrote-to-itself
merge_policy:
verification_handoff: 
---

# Stop origination when only the loop has spoken

## Overview

PROPOSED. The operator's third instruction is the one with no existing analogue: *when the
loop is the only one talking in the channel, that is the signal to stop, not to propose.*

Every brake in `/propose` reads the repository — a strategy's status, its date, its
attributed work, its open proposals. None reads whether anybody is still there. A loop
whose channel carries only its own posts is a loop with no one to serve, and the measured
cost of proposing into that silence was a day of merged work the operator tore out.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` — the loop serves an operator; a loop with no operator serves nobody

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md`, *The inbound sweep* — the one place that
  already reads the channel, over a bounded window, with standing consent.
- `plugins/workaholic/skills/propose/reference/loop.md` step 0 — the sweep runs before the
  strategy judgment, so the reading this needs is already in hand at the right moment.
- `plugins/workaholic/skills/propose/scripts/list-swept-slack-refs.sh` — the dedup ledger;
  the sweep's own messages and their authors pass through here.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shape catalog; the
  loop's own posts are identifiable by shape, which is how the sweep already excludes them.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — untouched: this is a
  run-level brake, not a per-strategy gate.
- `CLAUDE.md` — the `/propose` contract.

## Implementation Steps

1. Derive the reading from the sweep the run **already makes** — no second query, no second
   window, no cursor. Over the sweep's own window, was there any human message at all?
   The sweep already tells the loop's posts from a person's by shape, which is the same
   distinction this needs.
2. Answer it three-valued: `human_spoke` / `only_the_loop_spoke` / `unreadable:<reason>`.
   A channel that could not be read is **not** silence — a gate that cannot be read is not a
   gate, the rule `inbox_unreadable` already holds — so an unreadable read never stops
   origination and is reported by name.
3. On `only_the_loop_spoke`, stop origination for the tick: propose nothing, report the
   refusal by its own word, and post nothing. This is a run-level brake and refuses every
   strategy at once, unlike every existing gate, which is per-direction. State that
   difference where the gate is stated.
4. Do not stop the reactive half. An issue somebody filed, an ask swept from the channel, a
   `/specificate` run — all still work. The brake is on **origination**, exactly as
   `observing` and `arrived` are, and that asymmetry is the whole point.
5. Choose and justify the window. The sweep's own default is 26 hours, which is the
   evidence the judgment is made against; introducing a second, different number would be a
   constant nobody can defend. Reuse it and say so.
6. Report the reading in the run report whether or not it fired, so a reader can tell a
   quiet channel from a quiet loop. Update `workaholic:propose` and `CLAUDE.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A window carrying no human message stops origination for that tick, by a named word.
- An unreadable channel never stops origination.
- The reactive path — issues, sweeps, `/specificate` — is unaffected.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A dry run against a window with no human message reports the refusal and opens nothing.

**Gate** — what must pass before approval:

- No second channel query is added: the reading comes off the sweep already made.

## Considerations

- The obvious failure mode is a legitimate quiet stretch — a weekend, a holiday — reading
  as abandonment. That is the operator's own framing accepted deliberately: they said a
  silent channel is the signal to stop, and a stopped origination costs one hour of
  proposals while the alternative costs a day of work they tear out. Say the cost where the
  gate is stated rather than tuning a threshold against it.
- A repository with no Slack transport at all must not be braked by this: no transport is
  `unreadable`, not silence.

## Final Report

Development completed as planned. The brake is stated as **step 0b** of `/propose`'s loop,
with its own section in `workaholic:propose` and a line in `CLAUDE.md`.

- **The reading comes off the sweep already made** (steps 1 and 5): the same window, the same
  connector read, the same shape-based distinction between the loop's own posts and a
  person's. **No second query, no second window, no cursor**, and the window is the sweep's
  own `WORKAHOLIC_INBOUND_SLACK_WINDOW_HOURS` (default 26) because that is the evidence the
  judgment is made against — a second, different number would be a constant nobody can defend.
- **Three values** (step 2): `human_spoke` / `only_the_loop_spoke` / `unreadable:<reason>`. An
  unreadable channel — and a repository with **no Slack transport at all** — never brakes; a
  gate that cannot be read is not a gate, which is the rule `inbox_unreadable` already holds.
- **On `only_the_loop_spoke` the tick originates nothing** (step 3): steps 1-5 are skipped, no
  proposal opens, nothing is posted, and the run ends reporting that word — never as idle and
  never as an error. It is the **one run-level brake**, refusing every direction at once where
  every other gate is per-direction, and that difference is stated where the gate is stated.
- **The reactive half is untouched** (step 4): an issue somebody filed, an ask the sweep just
  captured, a `/specificate` run — all still work. The brake is on **origination**, exactly as
  `observing` and `arrived` are.
- **The reading is reported whether or not it fires** (step 6), so a reader can tell a quiet
  channel from a quiet loop.
- **The cost is written where the gate is**, not tuned against: a weekend or a holiday reads
  as abandonment and costs one tick of proposals, against the measured day of merged work the
  operator tore out by hand.

Thirteen hermetic rows pin the statement at all three surfaces, the never-brake-on-unreadable
property, the run-level framing, the reactive exemption, the reused window, and that the brake
did **not** leak into `survey-strategies.sh` — which would silently turn a run-level stop into
a per-strategy eligibility change with the same name.

### Discovered Insights

- **Insight**: The dangerous refactor for this brake is not "it fires too often" but "it
  becomes a per-strategy gate". Folded into `survey-strategies.sh` it would still look
  correct — directions would come back refused — while quietly changing `selected` instead of
  stopping the tick, and the run would go on posting. The pin is on that specific leak.
  **Context**: The same distinction separates every run-level reading in this loop from the
  per-artifact ones beside it.
