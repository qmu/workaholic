---
created_at: 2026-08-26T11:00:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826110016-add-the-moderate-step-direction-health.md
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Render the direction reading on the tick root

## Overview

Every `🔎 Moderation` root line names a repository **event**, supplied by the step beside
its log-facing `summary`. `direction-health` must supply one too — and, critically, must
supply **none** on a tick where every direction reads `live`. A step with no `event`
renders no line, which is the independent guard against a nothing-happened line reaching
the root even when the change diff calls the step changed.

`/standup`'s `no_strategies` no-op is left **untouched**, and the reason is recorded in the
skill rather than left to be re-derived: a digest about nothing teaches its readers to skip
the surface, which is why the reading goes to the question surface instead.

## Policies

- `workaholic:design` / `policies/interaction.md` — a status line addressed to nobody is noise
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — supplies `event`.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the renderer; it reads
  `event` and must need no change, which is what this ticket verifies rather than assumes.
- `plugins/workaholic/skills/standup/SKILL.md` — records why its no-op is untouched.
- `plugins/workaholic/skills/moderate/reference/workflow.md`, `CLAUDE.md`.

## Implementation Steps

1. Read `render-tick-post.sh` and confirm the `event`/`summary` split and the
   empty-event-renders-no-line rule hold as documented; if the renderer needs a change,
   that is a finding to report, not a licence to add a second rendering path.
2. In `step-direction-health.sh`, supply `event` naming the repository event — how many
   directions read `overdue`/`dormant`, or that the repository holds no live direction.
3. Supply an **empty** `event` when every direction reads `live`, and when the reader was
   `unreadable` — the second because a degradation is not a repository event.
4. Keep `summary` as the audit-trail line it is: counters, degradations, everything a
   maintainer diagnosing the tick needs. The two audiences stay separate.
5. Verify the root's change diff still works: the summary must not embed a timestamp or a
   bare object name, or the diff reads "changed" on every tick by construction.
6. Record in `standup/SKILL.md` why `no_strategies` stays a no-op there.
7. Update `reference/workflow.md` and `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick with a non-`live` reading renders one root line naming the event
- A tick where every direction reads `live` renders **no** line for this step
- An `unreadable` reader renders no line and is named in the tick log
- `/standup`'s `no_strategies` behaviour is byte-identical
- The step's `summary` contains nothing the change diff must normalize away

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — cases for all-`live`, one-`dormant`, and
  `unreadable`, asserting the rendered root in each
- A case asserting two consecutive ticks with identical state produce identical summaries

**Gate** — what must pass before approval:

- The suite passes; no existing root-rendering case changes

## Considerations

- The root carries questions; the line is context for the question beneath it. A line with
  no question under it is exactly what the `no_question` gate already suppresses, so this
  adds no new posting path.
