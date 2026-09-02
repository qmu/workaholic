---
created_at: 2026-09-01T12:33:58+00:00
status: done
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

## Final Report

Development completed as planned, with one part of the ask narrowed by name. `strategy-pace` now
carries a `plan` block — `advancing`, `held`, `held_reasons`, `wip` — lifted off the one survey it
already makes, and puts the same numbers in its own summary, because that string is what the
root's change diff compares. `render-tick-post.sh` renders one `📋` line from the block, beside the
change lines: gated on the diff, earning no post of its own, carrying no identifier and no mention
token, naming a degraded reading as degraded, and saying so with the count and the limit when the
repository's own `wip_limit` is holding the tick.

**What the ticket asked for and this does not give**: *what is next in the executor's order*. That
order is `plan-units.sh`'s, which no `/moderate` step may reach — the survey runs the living
migrations and **stages** what they converge — and naming which unit is next would put an
identifier on a line addressed to nobody, which the root's own rule forbids. Both rules are older
than this clause and neither is worth bending for it, so the delta says how the board moved and
the question says which artifact needs a person. The narrowing is stated in the clause's own
header, in `reference/workflow.md` and in `CLAUDE.md` rather than left to be rediscovered.

### Discovered Insights

- **Insight**: The delta's *gate* and the delta's *content* have to come from the same string.
  The root's change diff compares a step's `summary` against the last **speaking** tick's, read
  from the log — and the log carries only `status` and `summary`, never a structured payload. So a
  clause whose content lives in a JSON block can only be diffed if the same numbers are also in
  the summary. One derivation, two renderings; the impairment clause has exactly this shape and
  for exactly this reason.
- **Insight**: `render-tick-post.sh`'s three existing passes tokenise the input with `tr '{'`, one
  row per line, which works for scalar fields and **tears a nested object apart**. The `plan`
  block therefore has to be read with `jq`, and its extraction has to tolerate both shapes the
  script is fed (`{rows: [...]}` from the tests, `{steps: [...]}` from `run.sh`).
- **Insight**: The morning digest could not be the source. `step-strategy-digest.sh` fires only
  after 09:00 JST and only once a day, so an hourly delta composed over it would be silent for
  twenty-three hours out of twenty-four. `strategy-pace` is the step that reads the board every
  tick, which is why the block lives there.
