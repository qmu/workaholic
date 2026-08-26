---
created_at: 2026-08-26T08:20:29+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Render the direction reading on the moderation root

## Overview

The `🔎 Moderation` root renders each step's `event` — the repository event, never the
tick's bookkeeping — and a step with no event renders no line. Give
`direction-health` its `event` beside its log-facing `summary`, so a tick on which the
direction layer changed says so where the questions are read.

A tick on which **every** direction reads `live` supplies no event and therefore renders
no line: that is the independent guard against a nothing-happened line reaching the root
even when the change diff calls the step changed. `/standup`'s `no_strategies` no-op is
left untouched, and the reason is recorded in the skill rather than left to be
re-derived — a daily digest about nothing teaches its readers to skip the surface, which
is why this reading goes to the question surface instead.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — supplies
  `event`; the renderer does not know what a reading means.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — read to confirm the
  contract; it should need no change.
- `plugins/workaholic/skills/standup/SKILL.md` — records why its `no_strategies` no-op
  stands.
- `plugins/workaholic/skills/moderate/SKILL.md`, `CLAUDE.md`.

## Implementation Steps

1. Read `render-tick-post.sh` and the `event`/`summary` split in `moderate/SKILL.md`
   before writing a line of wording: the renderer takes what the step supplies, and the
   split is what stopped `no new documentation drift` announcing that nothing happened.
2. Supply `event` only when a non-`live` reading exists. All-`live` supplies the empty
   string, which is how a step says nothing happened here.
3. Word the event as a repository event — *a direction has run past its date*, *no live
   direction* — not as a counter of what the step examined.
4. Keep `summary` as it is: the tick log is an audit trail and loses nothing.
5. Link the item, as every root line does, so a person following the direction sees the
   question in its own place.
6. Record in `standup/SKILL.md` why `no_strategies` stays a no-op there, so the
   asymmetry between the two surfaces is a written decision rather than an oversight.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The root renders one line for the direction layer when any reading is non-`live`, and
  no line at all when every direction reads `live`
- The line names a repository event and links its item
- `/standup`'s `no_strategies` behaviour is byte-identical, and the reason is written
  down

**Verification method** — the commands/tests/probes that prove them:

- `sh plugins/workaholic/skills/moderate/scripts/run.sh --only direction-health` piped
  into `render-tick-post.sh`, against a seeded overdue direction and against an all-`live`
  tree
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No posting rule, post shape or gate moved: the root still posts only when it has at
  least one question
- The documentation this change makes wrong is updated in the same commit

## Considerations

- The root's single gate is a question, so a direction reading that produced no question
  (because the ask was held by quiet hours, or already asked) renders a line on a root
  that may not post. That is the existing design's stated cost — a real change with no
  question attached is visible only in the tick log — and this step inherits it rather
  than arguing it again.

## Final Report

Development completed as planned.

`direction-health` supplies `event` beside its log-facing `summary`, worded as a repository event
(*a direction has run past its date*, *the repository has no live direction*) rather than as a
counter of what the step examined, with each named direction linked. A tick on which every
direction reads `live` supplies the empty string and renders no line — verified by piping the
step's output through `render-tick-post.sh` against a seeded previous tick. `render-tick-post.sh`
needed no change, exactly as the ticket predicted. `standup/SKILL.md` now records why its
`no_strategies` no-op stands.

### Discovered Insights

- **Insight**: no other step's `event` carries a URL, so "every root line links its item" was an
  aspiration the shipped steps did not implement. This one derives the base URL from
  `remote.origin.url` locally — no network call — and degrades to the repo-relative path when
  there is no remote.
  **Context**: worth knowing before someone concludes from this line that the renderer resolves
  links. It does not: the event is a plain string and the linking is the step's own doing, so a
  future step wanting the same must do the same.
- **Insight**: a tick whose only non-`live` reading is `unreadable` also renders no line, and
  that is a third case the ticket did not enumerate.
  **Context**: it follows from the same rule that keeps `unreadable` out of the questions — our
  own degradation is not a repository event — and it is stated in the step and in the reference
  so it is not later read as a hole.
