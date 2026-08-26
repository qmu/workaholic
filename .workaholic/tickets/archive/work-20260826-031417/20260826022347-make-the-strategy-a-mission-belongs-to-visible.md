---
created_at: 2026-08-26T02:23:47+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: turn-the-loop-at-mission-granularity
merge_policy:
verification_handoff: 
---

# Make the strategy a mission belongs to visible

## Overview

The operator asks that missions be designed to hang off a strategy — **not mandatory**, but
the normal case, because a strategy is created first and instructions are given in its
context. The link already exists and needs no new field: `attributed-work.sh` walks
`strategy.feedback[] ∩ artifact.feedback[]` plus the `via_mission:<slug>` hop, `/propose`
puts the strategy's refs on the issue it opens, and `/specificate` carries them onto the
mission. What is missing is that **nobody can see it**: `/mission`'s roadmap, the mission
file and the tick's readers all render a mission with no indication of which direction it
serves.

Make the link visible where missions are read. The `strategy:` relation stays retired — a
mandatory frontmatter field would also contradict the ask's own "必須でなくて良い".

## Policies

- `workaholic:implementation` / `policies/observability.md` — an existing relation is shown,
  not re-stored
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — the one attribution
  reader; read its header and its lossy/transitive contract before composing it
- `plugins/workaholic/skills/mission/scripts/list.sh` — the roadmap's source
- `plugins/workaholic/commands/mission.md` and `plugins/workaholic/skills/mission/SKILL.md` —
  the bare `/mission` roadmap render
- `plugins/workaholic/skills/standup/scripts/digest.sh` — already renders per strategy; the
  inverse view is what this adds
- `scripts/test-workflow-scripts.mjs` — hermetic coverage

## Implementation Steps

1. Add the **inverse read**: given a mission, which strategy (if any) it is attributed to.
   Compose `attributed-work.sh` rather than writing a second walker; if a per-mission entry
   point is genuinely absent, add one thin script beside it that reuses the same derivation.
2. Render it where missions are read: the bare `/mission` roadmap names each mission's
   strategy, and a mission attributed to none renders an explicit "no strategy" rather than
   a blank — the two must not look alike.
3. Report what could not be attributed, as every consumer of this reader already must: the
   attribution is transitive and lossy, so the render never implies the answer is exhaustive.
4. Add nothing to any artifact's frontmatter. Confirm the retired `strategy:` relation has
   not returned before finishing.
5. Add hermetic cases: a mission carrying a strategy's refs; a mission carrying none; a
   strategy whose refs resolve to nothing.
6. Regenerate `outputs/` and verify.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Given a mission, the strategy it belongs to is readable through the existing attribution
  derivation
- The bare `/mission` roadmap names it, and renders an explicit "no strategy" when there is none
- No artifact gained a field; `strategy:` did not return
- What could not be attributed is reported, never implied to be nothing

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `git grep -n "^strategy:" plugins/workaholic/skills .workaholic` — expects no artifact field
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The roadmap renders both states distinguishably, and the smoke tests pass

## Considerations

- **The temptation is a `strategy:` field on the mission**, which would make the render
  trivial. It is refused three times over: the relation was retired on 2026-07-28 with its
  ownership hop, the 2026-08-17 no-new-field ruling chose the citation walk deliberately, and
  the ask itself says the link need not be mandatory — a required field is the opposite of
  optional.
- This ticket is the one that makes "missions hang off strategies" *true to a reader*. The
  mechanism that makes it true to a machine is the carry-forward, already being floored by
  the mission `prove-the-loop-s-closing-link`; the two are complementary, not duplicates.

## Final Report

Development completed as planned. `strategy/scripts/mission-strategy.sh` answers *which strategy
does this mission belong to* by **composing** `attributed-work.sh` — no second walker, no relation
of its own, no field on any artifact — and `/mission`'s bare roadmap (`command-flows.md`, the
planning session's Status step) now names each mission's strategy, rendering an explicit
**`— no strategy`** where nothing could be attributed so that "belongs to no direction" and "could
not be attributed" never look alike. The section closes with the honest line the reader supplies:
how many missions could not be attributed, and any strategy named in `unreadable`.

Step 1's "if a per-mission entry point is genuinely absent, add one thin script beside it" is what
happened: `attributed-work.sh` answers strategy → work and has no inverse, so the inverse is a
reader over the reader. `exhaustive: false` is emitted on every call, by construction.

The `strategy:` field was **not** added and the pre-retirement survivors were checked:
`git grep -n "^strategy:"` finds it only in three archived missions written before the 2026-07-28
retirement (history, not a return) and in `propose/SKILL.md`'s illustration of the issue *body*
marker, which is not an artifact field.

### Discovered Insights

- **Insight**: "Read successfully and attributed nothing" and "could not be read" needed to be two
  outputs, not one.
  **Context**: A strategy citing a record nothing answers is the ordinary early state; folding it
  into `unreadable` would have made a healthy new direction render as a broken one — the same
  blur `no_citing_artifacts` versus `no_feedback_refs` already exists to prevent.
- **Insight**: The inverse read is O(strategies), not O(missions).
  **Context**: `attributed-work.sh` is a per-strategy walk, so the inverse runs it once per active
  strategy and pivots the result. That is what keeps it a composition rather than a second walker,
  and it is why the render reads it **once** before rendering rather than per mission line.
- **Insight**: A mission is not de-duplicated across strategies.
  **Context**: `attributed-work.sh` already states that attribution is not a partition; the render
  therefore has to tolerate a mission naming two directions rather than picking one.
