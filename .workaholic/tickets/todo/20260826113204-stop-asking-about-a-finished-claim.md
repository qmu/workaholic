---
created_at: 2026-08-26T11:32:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Stop asking about a finished claim

## Overview

PROPOSED. Ticket 7 of 8, and two changes to one step for one reason: the question channel
is being spent on things that are not questions.

First, `step-stalled-units.sh` drops a `superseded` row from its question set and reports
it as a finding in the tick log instead. A person is currently being asked to look at
three merged pull requests, and a question layer that cries wolf is worse than none —
the asked-once ledger means the real stalled unit arrives in a stream a person has
learned to skip.

Second, separate the step's log-facing `summary` from its root-facing `event`. The summary
embeds an age in hours that increments every tick, so the moderation diff calls the step
changed hourly and the root has restated the same stalled units four times today — the
shape `📦 Release Preparation` was retired for.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — both changes.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — READ. It renders
  `event` and diffs on `summary`; this is why the two must differ.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the step's input.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step's contract.
- `scripts/test-workflow-scripts.mjs` — the question set and the diff stability.

## Implementation Steps

1. Read `render-tick-post.sh` and the 2026-08-23 `event`-versus-`summary` rule. The
   renderer normalises a timestamp, a bare hex object name and a clock time out of both
   sides — and **only** those — so an age in hours is not normalised away and must not be
   in the summary the diff reads.
2. Drop `superseded` rows from the question set, and report them in the tick log as a
   finding instead. A finished claim is a fact, not a question.
3. Give the step an `event` distinct from its `summary`, with the age kept out of whatever
   the diff compares. A step with no finding supplies no event, so no root line renders.
4. Confirm the asked-once keying is untouched: `stalled-unit:<unit>` still keys a genuine
   stall, and this ticket changes only which rows reach it.
5. Update `SKILL.md` for both halves.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No question is emitted for a `superseded` claim; it appears in the tick log instead.
- Two consecutive ticks with an unchanged stalled set produce no root line the second
  time.
- A genuinely stale, unmerged claim still produces its question, keyed once.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the question set, and a two-tick diff with an
  unchanged set.
- `sh scripts/e2e/loop-drill.sh verify-moderate`

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.

## Considerations

- The two halves are one change because they share a cause — the step announcing what is
  not news — and because splitting them would leave the root restating a set the first
  half just shrank.
