---
created_at: 2026-09-01T12:33:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: adjust-the-plan-hourly-not-only-report-it
merge_policy:
verification_handoff: 
---

# Carry the plan's delta in the hourly post

## Overview

PROPOSED. The ask: "make the plan the artifact the hourly post reports — what landed, what that
changed in the plan, what is next in order, and what needs a person: the delta of a plan, not an
anomaly list." The daily digest already says where the work stands, once a day. The hourly root
still carries only change lines derived per step, so an hour in which a mission advanced and the
next unit changed reads as a list of anomalies. This puts the plan's delta on the hourly post,
beside the anomaly lines rather than instead of them.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — composes the root, its change lines and the post gate.
- `plugins/workaholic/skills/moderate/scripts/step-strategy-digest.sh` — the daily digest, the reading this composes over.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `🔎 Moderation` shape.
- `plugins/workaholic/commands/moderate.md` — the notification ceiling.

## Implementation Steps

1. Derive the plan delta from readings that already exist: what landed since the last speaking
   tick (the digest's window), what that changed in acceptance and queue counts, and what is
   next in the executor's order (ticket 3's stated order). **No new walker and no new field.**
2. Render it as **lines on the existing root**, beside the change lines, not as a second post
   and not as a new shape. The two retired status roots are the standing warning: a status
   line addressed to nobody is noise whatever its dedup key.
3. Hold it to the root's own rules: it names a **repository event** and carries **no
   identifier** — *how many* is news, *which* is a task, and a slug belongs in the question
   addressed to whoever can act.
4. Keep it inside the existing gate. An hour where the plan did not move adds no line, so this
   cannot become an unchanged answer restated hourly — which is exactly what
   `📦 Release Preparation` was retired for.
5. Name a degraded reading as degraded rather than rendering an empty delta, and never as
   *nothing moved*.
6. When ticket 2's limit holds a tick, say so here with the count and the limit: a held loop
   must not look like a stopped one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An hour in which the plan moved carries a delta line naming what landed and what is next.
- An hour in which it did not moves nothing and adds no line.
- The lines carry no slug or identifier.
- A degraded reading is named as degraded, never as an empty delta.
- A tick held by the work-in-progress limit says so with the count and the limit.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — render rows for moved, unmoved, degraded and held.
- `render-tick-post.sh` run over fixtures for each.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **This ticket collides with the mission from issue #843**, which reworks the same file: that
  one changes the root's *thread key* and its *post gate*, this one changes *what the root
  says*. Drive them in sequence rather than in parallel, and take #843's first — a delta line
  restated hourly in a fresh root every hour is the worst of both.
- The ask says "the delta of a plan, **not** an anomaly list". The anomaly lines are kept
  anyway: they are what surfaces a stuck claim or a red base, and dropping them would trade one
  blindness for another. What changes is that the plan is on the post at all.
- Resist letting this grow into a second digest. The daily digest exists and is deliberately
  daily; an unchanged board restated every hour is the failure this repository keeps retiring.
