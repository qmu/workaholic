---
created_at: 2026-09-03T08:59:28+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-a-post-the-transport-refused-or-say-it-reached-nobody
merge_policy:
verification_handoff: 
---

# Carry an unposted line on the unit story for the next tick

## Overview

A post that failed once has a natural second chance: the loop turns every five minutes. Nothing
carries the line forward, so a denied post is lost at the moment it is reported. The unit's story
already exists as the place a run leaves a fact about itself — `record-merge-outcome.sh` writes a
section there for exactly that reason — so an unsent line can be left where a later tick will
find it, and re-sent once.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/record-merge-outcome.sh` — the existing single writer of a run's own outcome onto its branch story
- `plugins/workaholic/skills/drive/SKILL.md` — the run's route and its report contract
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — where a later tick reads what a unit is carrying
- `plugins/workaholic/skills/notify/SKILL.md` — the transport model this retry rides
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for the writer and the reader

## Implementation Steps

1. **Reproduce and localize first.** Establish what a run does today with a line it could not
   post: read the route's own text and `record-merge-outcome.sh`, and name where the outcome is
   reported and where it stops. Confirm no store carries it forward.
2. Decide the record's shape and its home on the unit's story — one section, append-only, naming
   the shape, its text and why it did not post.
3. Write it at the point the refusal is reported, through one writer, idempotently, so a re-run
   leaves the story byte-identical.
4. Read it at the head of a later tick and re-send once, never duplicating a line that landed;
   a send that is refused again leaves the record standing and says so.
5. Report the retry's outcome in the run report in the same vocabulary the first attempt used.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- An unposted line is recorded on the unit's own story with its shape, its text and the reason it did not post
- A later tick re-sends it exactly once and reports the outcome; a line that landed is never re-sent
- The writer is idempotent — a re-run leaves the story byte-identical

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with a hermetic case covering write, re-run, read and re-send
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The suite passes and the hermetic case proves the idempotence rather than asserting it

## Considerations

- The retry must not become a second liveness authority or a background timer; it rides a tick
  that already runs, and a tick that does not run simply does not retry.
- A duplicate post is the loud failure here and a lost one the quiet failure; the record has to be
  precise enough to tell a landed line from an unsent one.
- Depends on the sibling ticket naming `post_refused`: without the word, the record cannot say why.
