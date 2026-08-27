---
created_at: 2026-08-27T16:19:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827161956-add-the-moderate-step-base-health.md
mission: read-whether-the-base-survived-what-the-loop-merged
merge_policy:
verification_handoff: 
---

# Render the base's health as a moderation event

## Overview

<!-- PROPOSED. -->

Every `/moderate` step supplies two things: a log-facing `summary` (the audit trail
a maintainer reads when diagnosing the tick) and an `event` (what the `🔎 Moderation`
root renders, which must name a **repository event** rather than the tick's own
bookkeeping). Ticket 3 gives `base-health` its question; this ticket gives it its
event, so the hour's root says the base went red and links the commit.

The guard is the one already in place and this ticket must not weaken it: **a step
with no event renders no line**. A green base supplies no event, so a healthy hour
renders nothing — which is the independent protection against a nothing-happened
line reaching the root even when the tick's diff calls the step changed.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-base-health.sh` — from ticket 3; this
  ticket adds its `event`.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the renderer. It reads
  `event` for the line and `summary` for the change diff; **neither contract moves here**.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — where per-step `summary`/`event`
  are collected.
- `plugins/workaholic/skills/moderate/SKILL.md` — the root's shape and the event rule.

## Implementation Steps

1. Read the event rule in `moderate/SKILL.md` before writing a word of it: a line used
   to be the log summary verbatim, which is why `0 already captured` and `no new
   documentation drift` reached the root announcing that nothing happened.
2. Supply `event` **only** for a red base. Green supplies none. A degraded read supplies
   none — it is our own failure to read, not a repository event, and it is already named
   in `summary`.
3. Word the event as the repository event it is: the base is red, at which commit, from
   which merge, with which checks failing. Link the commit, so the root line is followed
   rather than merely read.
4. Keep the `summary` unchanged in kind — the audit trail loses nothing, and the diff
   against the previous tick still reads `summary`.
5. Make the summary **diff-stable**: the tick's change detection normalizes out a
   timestamp, a bare hex object name and a clock time, and **only** those. A summary
   whose only moving part is something else would report "changed" every hour by
   construction — the defect `inbound-sweep` and `doc-drift` were fixed for. A commit
   sha is normalized out, so make sure what remains distinguishes a genuinely new
   reading from a restatement of the same one.
6. Confirm the posting gate is untouched: the root posts when the tick has **at least
   one question**. This event never posts on its own, and must not become a second gate.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- a red base contributes one root line naming the reading and linking the commit
- a green base and a degraded read contribute **no** event and therefore no line
- the step's `summary` still distinguishes this hour's reading from last hour's
- the root's posting gate (at least one question) is unchanged

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-base-health` (ticket 7) rendering a tick post
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- a simulated green tick renders no base-health line at all
- two consecutive ticks over one unchanged red reading do not read as two changes

## Considerations

- This repository has retired two keyed status roots for restating an unchanged answer
  hourly. The event must not become a third: it names an event, and the root it rides
  only posts when there is a question to carry.
- Resist putting the failing check names in the `summary` **and** the `event` in a form
  that reorders between reads — an unstable ordering makes every tick look changed.
