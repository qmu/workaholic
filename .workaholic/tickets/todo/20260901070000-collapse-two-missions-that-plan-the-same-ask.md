---
created_at: 2026-09-01T07:00:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: 20260828121729-deliver-what-the-loop-already-knows-to-the-person-who-can-act.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
---

# Collapse two missions that plan the same ask

## Overview

Minted mid-run 2026-09-01 while draining mission
`deliver-what-the-loop-already-knows-to-the-person-who-can-act`. **That slug now names two
missions**, both tracked, both `status: achieved`:

- `.workaholic/missions/archive/<slug>/mission.md` — created 2026-08-28T18:19:13Z from feedback
  record `20260828181639-…`, driven on `work-20260828-184133`, `actual_hours: 1.05`, changelog
  naming seven `20260828182002-*` tickets and a story. **This one did the work.**
- `.workaholic/missions/active/<slug>/mission.md` — created 2026-08-28T12:20:17Z from feedback
  record `20260828121729-…`, carrying seven `20260828122110-*` tickets that describe the same
  three acceptance criteria in different words. It reached `main` on 2026-09-01 when the
  four-day-stranded proposal #688 merged, and this run drained it — every ticket verified as
  already implemented and archived with that finding recorded.

So `/specificate` planned one ask twice, six hours apart, from **two feedback records for the
same ask**. The earlier plan sat in a stranded publication while the later one was driven; when
the stranded publication finally landed, the repository gained a second mission with the same
slug and a queue of finished work.

**Why this is not fixed in the run that found it.** Both records carry real history — the
archived one holds the implementation changelog and the run hours, the active one holds this
run's verification changelog — so choosing which survives is a judgement about the durable
record, not a mechanical merge. `archive.sh`'s auto-close correctly wrote `achieved` and
correctly did not move the directory (the move is `/mission-close`'s act), so nothing here is a
script behaving wrongly; what is missing is a rule for the collision.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/mission/scripts/close.sh` — the one writer of an end state. Where a
  same-slug collision would be detected, if the answer is to refuse rather than to collapse.
- `plugins/workaholic/skills/mission/scripts/archive.sh` and `plugins/workaholic/commands/mission-close.md`
  — the archive move that will collide the next time anything tries to move the active copy.
- `plugins/workaholic/skills/moderate/scripts/step-closable-missions.sh` — closes a mission the
  archive gate can prove; it will meet this pair.
- `plugins/workaholic/skills/specificate/scripts/` — the slug derivation. Two records for one ask
  produced one slug twice; whether that is the defect or a symptom is step 1's question.
- `plugins/workaholic/hooks/layout-doctor.sh` — the audit that would name a same-slug pair, if
  the answer is to report rather than to prevent.

## Implementation Steps

1. **Establish how many such pairs exist and how they arose, before choosing a fix.** Walk
   `missions/active/` against `missions/archive/` for shared slugs; for each pair record both
   `created_at` values, both `feedback:` lines, and whether the two ticket sets describe the same
   acceptance. A pair from one ask planned twice and a pair from a slug genuinely reused for
   different work are different findings; do not collapse them.
2. **Decide which of three seams owns the answer, and say why the other two do not.**
   (a) **Prevent it at the slug** — `/specificate` refuses to create a mission whose slug already
   exists in either area. Cheapest, and it would have stopped this; but it also refuses a
   legitimate second attempt at an ask the first attempt abandoned.
   (b) **Refuse at the close/move** — `close.sh` or the archive move names the collision rather
   than colliding. Narrow and safe, but it fires long after the duplicate work was queued and
   driven, which is where the cost actually was.
   (c) **Notice it in the audit** — `layout-doctor.sh` reports a same-slug pair and the operator
   rules. Most honest about the judgement, and it never prevents the wasted drive.
3. **Do not delete either record as part of the fix.** Whichever seam wins, the two files are
   history; collapsing them is the operator's act, and this ticket must not do it silently.
4. **State the outcome where the mission model is documented** — `CLAUDE.md`'s mission-lifecycle
   bullet and `skills/mission/SKILL.md` — in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The walk of step 1 is recorded, naming every same-slug pair currently in the tree and how each
  arose.
- Exactly one seam owns the answer, and the ticket's Final Report says why the other two do not.
- Neither the `active/` nor the `archive/` copy of any existing pair is deleted by this change.
- `CLAUDE.md` and `skills/mission/SKILL.md` agree with the shipped behaviour.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — carrying a hermetic case for the chosen seam.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The step-1 walk is in the Final Report, not merely asserted.
- No script gains a second derivation of a mission's slug or of its lifecycle state.

## Considerations

- **This is a consequence of repairing the stranded-publication path, not an argument against
  it.** The same incident is already recorded from the other side in
  `20260901062000-check-a-stranded-proposal-is-still-worth-landing.md`, which asks whether a
  long-stranded proposal is still worth landing at all. That ticket and this one are the two
  halves — one about not queuing finished work, one about the collision it left behind — and
  whichever is driven first should read the other.
- **Do not fix it by making the driving run skip a mission whose slug is archived.** The run
  would then silently ignore a legitimately re-opened ask, and the queued tickets would sit
  undrivable with nothing saying why.
