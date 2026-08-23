---
created_at: 2026-08-23T09:38:03+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: route-a-stalled-unit-to-a-person-who-is-asked-by-name
merge_policy:
verification_handoff: 
---

# Ask the owner of a stalled unit, by name, through the tick

## Overview

With the sibling landed, the tick knows which units have stopped and for how long. This ticket
turns that into the thing the developer actually expects: **a question that names them, so Slack
notifies them, carrying the session link they answer in.**

The vehicle already exists and is already correct. `🙋 <@U…>` names a resolved person, rides
inside the tick's own thread, carries the session URL and is asked once. Nothing about it needs
inventing — what was missing was a finding to put in it.

**The alert shapes are not the fix.** `🔴 Blocked` and `↳ still failing` carry no mention token,
and that stays: they are the run's record of an outcome, not a demand on a person. Making them
louder is the direction this repository has twice retired — the failure was never volume.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — takes `needs_agent`
  candidates and holds the per-tick cap, the day cap, the working-week gate and quiet hours.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the four gates and the
  `already_asked` ledger keyed on the content key's step id.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `🙋 <@U…>` shape.
- `plugins/workaholic/skills/gather/scripts/owners.sh` — the one ownership oracle; the person to
  name comes from here, never from a guess.
- `plugins/workaholic/skills/moderate/SKILL.md`, `CLAUDE.md` — both state what the tick asks about.

## Implementation Steps

1. Resolve the `## Open Decisions` item below before writing code; record the ruling in the Final
   Report.
2. **Reproduce.** Confirm that today a long-stalled unit produces no check-in candidate at all.
3. Hand each stalled unit past the ruled threshold to the check-in as a candidate, with a content
   key stable across ticks (so `already_asked` works) and the owner resolved through `owners.sh`.
4. Write the question so it can be **answered**: what is stuck, what the run could not decide,
   and that the answer is given in the moderator's session through the link on the question.
5. Keep every existing gate: the per-tick cap, the day cap, quiet hours and the working-week hold
   apply unchanged. A held question is still a delay, never a loss.
6. Leave `🔴 Blocked` and `↳ still failing` exactly as they are, and say in the SKILL why: they
   record an outcome, the question demands an answer, and the two are different speech acts.
7. Update `moderate/SKILL.md` and `CLAUDE.md` in the same commit.

## Open Decisions

- **How long a unit must be stopped before a person is asked.**

  Sources read: `workaholic:notify` (a red alert is deduped by signature with a 24-hour
  cool-down, and the `↳ still failing` reply carries the tick count — so the plugin already has a
  notion of "still, after N"); `workaholic:moderate` (the working-week gate exists because a
  question posted when nobody is reading is worse than one held); the measured case — eleven
  ticks, spanning a Friday evening into a weekend. These establish that repetition alone is not
  the trigger and that the working day matters; they do not fix a number.

  - **(a) A fixed tick count.** Simple and testable. Cost: an arbitrary constant, and the
    measured failure was not really "eleven" — it was "a whole working day passed".
  - **(b) The unit has been stopped across a working-day boundary.** No new constant; composes
    the boundary the quiet-hours gate already owns, and matches what actually went wrong. Cost:
    a unit that stalls at 09:05 waits nearly a day before anyone is asked.
  - **(c) The unit made no progress across two consecutive ticks AND has an unresolved
    `## Open Decisions` item.** Fast, and targets the one blocker class a person can actually
    clear. Cost: says nothing about the other blocker classes — a missing credential, a failing
    gate — which also need a person.

  The driving session rules explicitly and records why; it may not pick silently.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit stopped past the ruled threshold produces one check-in candidate naming its owner.
- The question is asked once; a held question is reported as held, not dropped.
- `🔴 Blocked` and `↳ still failing` are unchanged.
- The Open Decision is resolved in the Final Report with its reasoning.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- Fixtures: freshly stalled, past-threshold, past-threshold-already-asked, and off-day.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the moderate drill are clean.

## Considerations

- The question must be answerable by a person who has not read the run report. Naming the
  signature is not naming the problem.
- Do not let this become a second route into work. The tick asks; it never claims, never drives
  and never resolves a blocker itself.
