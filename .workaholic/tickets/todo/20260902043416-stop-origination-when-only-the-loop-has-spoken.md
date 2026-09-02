---
created_at: 2026-09-02T04:34:16+00:00
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
