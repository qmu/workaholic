---
created_at: 2026-08-28T12:21:10+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Make a tick that reached nobody a visible event

## Overview

The root's gate is *a question*, so a tick with fifteen findings and zero delivered posts
nothing — byte-identical to a quiet hour, measured over eight consecutive ticks. A
**delivery failure is itself the event the root exists to carry**: the check-in supplies
its own `event` when it had candidates and delivered none, so the gate carries it.

## Policies

- `workaholic:implementation` / `policies/observability.md` — the running system says what it did
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — supplies `event`
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — renders the root's
  lines from each step's `event`
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the posting gate
- `plugins/workaholic/skills/notify/reference/notifications.md` — the post shapes

## Implementation Steps

1. When the check-in had **candidates** and delivered **zero questions**, supply an `event`
   naming that, in one line, in the tick's own voice. Read it from ticket 4's reading —
   do not re-derive it.
2. Make the posting gate carry it. The gate is *at least one question*; this is the one
   other thing worth a root, and it is exactly the case where a question could not be the
   trigger. Keep every other silent state silent: `idle`, `no_question` with no candidates,
   `no_previous_tick` and `no_log` post nothing, unchanged.
3. **One line, and it names no dedup key** — the printed-key retirement stands. The line
   says what could not be delivered and why, and links nothing it cannot link.
4. Do not restate. The line is a function of the reading, so an unchanged world renders an
   unchanged summary and the diff suppresses the repeat by construction — the property that
   makes an hourly root admissible at all.
5. Add the new shape to `notify/reference/notifications.md` and keep the `[Moderate]`
   template's copy byte-identical; the drift pin in the suite covers it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick with candidates and zero delivered posts a root line naming that.
- A genuinely idle tick still posts nothing.
- The line carries no dedup key and no mention token.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the gate over both fixtures, plus the
  notify-copy drift pin.

**Gate** — what must pass before approval:

- The step still asks nothing extra and writes nothing but its own log line.

## Considerations

- The risk to hold against is the one this repository has learned twice: `🔧 Needs a
  decision` and `📦 Release Preparation` were retired for restating an unchanged answer
  hourly. This line survives that test only while the diff genuinely suppresses it — so
  the summary it derives from must be stable under an unchanged world (ticket 4).
- It is addressed to nobody, deliberately: it reports that the loop could not reach
  anyone, and naming a person for the loop's own degradation is what `strategy-pace`
  already refuses.
