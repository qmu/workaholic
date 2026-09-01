---
created_at: 2026-09-01T08:32:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-where-the-work-stands-not-only-what-is-wrong
merge_policy:
verification_handoff: 
---

# Make a mission's direction readable without a field

## Overview

The ask's second half is that "a person opening a mission file cannot tell which direction
it serves", and it proposes a readable `strategy:` field on the mission. The need is real;
the proposed mechanism is the one thing this repository has ruled against by name.

The sources say so plainly. `mission/SKILL.md`, *The strategy layer: retired, then
redefined*: when the strategy artifact returned on 2026-08-13 (issue #436), *what did not
return* was "the `strategy:` relation on a mission, and the ownership hop it fed"; a legacy
`strategy:` key in an old mission "stays tolerated history and is still read by nothing".
`CLAUDE.md`, *The strategy layer*: the readers compose with "no second walker, no relation
of its own, **no field on any artifact**", and "the retired `strategy:` mission relation
and its ownership hop stay retired — **do not re-add them**".

The reader that answers the question already exists and is named in that same table:
`mission-strategy.sh`, the inverse of `attributed-work.sh`. Bare `/mission` already renders
each mission with its strategy, and an explicit *no strategy* where nothing could be
attributed. So this ticket makes the join reachable from where a person actually looks,
and records why the field is not the answer.

## Policies

- `workaholic:design` / `policies/history-structures.md` — a derived relation is not duplicated into a field
- `workaholic:implementation` / `policies/objective-documentation.md` — the ruling is cited where the question recurs
- `workaholic:development` / `policies/commit-change-history.md` — a standing ruling is cited, not silently reversed

## Key Files

- `plugins/workaholic/skills/strategy/scripts/mission-strategy.sh` — the inverse reader;
  the answer to "which direction does this mission serve", already written.
- `plugins/workaholic/skills/mission/SKILL.md` — *The strategy layer: retired, then
  redefined*; the ruling and its reasons.
- `plugins/workaholic/skills/mission/reference/schema.md` — the mission's field list and
  its *History* section, where the tolerated legacy `strategy:` key is recorded.
- `plugins/workaholic/skills/mission/SKILL.md` and `commands/mission.md` — the bare
  roadmap render that already names each mission's strategy.
- `CLAUDE.md` — the strategy-layer reader table and the do-not-re-add rule.

## Implementation Steps

1. **Read the whole of both sources first**, not the paragraph this ticket quotes:
   `mission/SKILL.md`'s *The strategy layer: retired, then redefined* in full, and
   `CLAUDE.md`'s *The strategy layer* in full. The measured failure this repository has
   already paid for is a partial read of one section with the answer further down the page.
2. **Reproduce the gap**: open a mission file and try to name its direction; then run
   `mission-strategy.sh <slug>` and get the answer. The gap is a surfacing one, not a
   missing reading.
3. Name the direction where a person meets a mission: the morning digest's nesting (the
   previous ticket) is one such surface; add the reader's answer to whichever mission-facing
   render still omits it, in the render only, deriving it through `mission-strategy.sh` and
   through no second walk.
4. Record the answer where the question will be asked again: one short paragraph in
   `mission/reference/schema.md` naming `mission-strategy.sh` as how a mission's direction
   is read, and why the frontmatter key is not the answer. Update `CLAUDE.md` in the same
   commit if this changes what it states.
5. Write **no** `strategy:` key, revive **no** ownership hop, and add **no** second walker.
   A migration that would stamp one onto existing missions is out of scope by the same rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A person can read which direction a mission serves from a mission-facing surface, without
  running a set intersection by hand.
- No artifact gains a `strategy:` field; `attributed-work.sh` stays the only walker and
  `mission-strategy.sh` the only inverse reader.
- `mission/reference/schema.md` records how the direction is read and why the field is not
  re-added, and `CLAUDE.md` agrees with it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/skills/strategy/scripts/mission-strategy.sh <an active slug>`
  beside the rendered surface, showing the same answer
- `grep -rn 'strategy:' .workaholic/missions/active/` — no new key written

**Gate** — what must pass before approval:

- The suite passes and the diff introduces no frontmatter key on any artifact.

## Considerations

- **The reporter's proposed mechanism is recorded as a hypothesis and declined with its
  sources**, per the diagnosis-first rule: a readable field on the mission is what the ask
  asks for, and the repository ruled against exactly that relation with reasons (a mission's
  owner is on the mission, a strategy's owner is on the strategy; two homes for direction
  drift when both are inboxes). What the ask actually needs — legibility for a person — is
  met by the render.
- If the operator, having read the ruling, wants the field anyway, that is their reversal to
  make and it belongs in a new ask naming the retirement it reverses. This ticket does not
  make that decision, and it does not quietly do it either.
- `mission-strategy.sh` inherits attribution's lossiness: a mission no direction claims
  renders an explicit *no strategy*, exactly as bare `/mission` already does. Do not render
  a guess.

## Final Report

Development completed as planned. The reporter's proposed mechanism — a readable `strategy:`
field on the mission — is **declined with its sources**, and the need behind it is met.

Both sources were read in full, not the paragraphs the ticket quotes. `mission/SKILL.md`, *The
strategy layer: retired, then redefined*: what did **not** return on 2026-08-13 was "the
`strategy:` relation on a mission, and the ownership hop it fed"; a legacy key "stays tolerated
history and is still read by nothing". `CLAUDE.md`, *The strategy layer*: the readers compose
with "no second walker, no relation of its own, no field on any artifact", and the relation and
its hop "stay retired — do not re-add them".

The gap reproduced exactly as the ticket predicted: the mission file's frontmatter carries
`feedback:` refs and names no direction, while `mission-strategy.sh <slug>` answers it in one
call. It is a surfacing gap, so the repair is a render.

The surface that still omitted it is the **Mission Position Report** — the one definition of
*where does the mission stand*, stated by `/mission-close` before the outcome is asked and by
`/drive` for each unfinished mission unit. It was three things and is now four, the direction
first, read through `mission-strategy.sh` and rendered in the bare `/mission` roadmap's own
vocabulary so a person meets one answer: `— <strategy title>`, an explicit `— no strategy`, or
an unreadable walk named as unreadable. One definition point, so both seams gained it at once.

The ruling is recorded beside the frontmatter block in `mission/reference/schema.md`, where the
question recurs, with both standing reasons — the ownership hop the relation drags behind it,
and that a field would be a hand-maintained copy of a derived fact, wrong the moment a
strategy's `feedback:` line moves. `CLAUDE.md` agrees. No `strategy:` key was written: the three
survivors are in `missions/archive/`, are tolerated history, and `missions/active/` has none.

### Discovered Insights

- **Insight**: the Mission Position Report is defined once and stated by two seams, so a change
  to *what a handoff says about a mission* is a single edit — and correspondingly, a surface
  added there reaches an unattended `/drive` run as well as an attended close.
  **Context**: it is the reason this was the right surface rather than `/catch`'s Missions
  section, which is a cross-developer synthesis and would have needed its own read.

- **Insight**: three `strategy:` keys survive in `.workaholic/missions/archive/`, and the
  ruling's own words cover them — tolerated history, read by nothing. A gate written against
  the whole `missions/` tree would fail on history that harms nothing.
  **Context**: the ticket's own verification command is scoped to `active/` for exactly that
  reason; a future audit should keep that scope rather than "cleaning up" the archive.

- **Insight**: the render already had a three-way vocabulary — attributed / `no strategy` /
  unreadable — established by the bare `/mission` roadmap, and reusing it verbatim was the
  whole design work.
  **Context**: attribution is transitive and lossy by construction (`exhaustive: false`), so
  every consumer needs all three; inventing a second wording for one of them is how two
  readings of one fact drift.
