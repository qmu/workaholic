---
created_at: 2026-09-01T07:00:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: 20260828121729-deliver-what-the-loop-already-knows-to-the-person-who-can-act.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
claim: work-20260901-070504
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

## Final Report

Development completed as planned.

### Step 1 — the walk, before choosing a seam

Every slug present in **both** `missions/active/` and `missions/archive/`:

| Slug | `active` created_at / record | `archive` created_at / record | Same acceptance? |
| ---- | ---------------------------- | ----------------------------- | ---------------- |
| `deliver-what-the-loop-already-knows-to-the-person-who-can-act` | 2026-08-28T12:20:17Z / `20260828121729-…` | 2026-08-28T18:19:13Z / `20260828181639-…` | yes — three criteria, same substance, different wording |
| `say-when-the-loop-has-run-out-of-direction` | 2026-08-26T07:19:28Z / `20260826071745-…` | 2026-08-26T08:19:15Z / `20260826081729-…` | yes — 5 of 8 queued tickets have exact-title archived twins |

Two pairs, one cause, and **neither is a slug reused for different work**: in both, two feedback
records were written for one ask (6 hours and 1 hour apart), and `/specificate` dedups on the
ask's **feedback refs**, so different refs meant no duplicate was seen while the slug — derived
from the title — collided. In both pairs the **later** record's mission was driven and archived
while the earlier sat in a publication the transport had refused, landing days later.

### Step 2 — the seam, and why the other two do not own it

**Chosen: (c), the audit.** `layout-doctor.sh` names each same-slug pair as an **advisory**.

- **(a) prevent at the slug — rejected, and provably insufficient.** This is the finding that
  settled it: `create.sh` **already** refuses a slug `mission_resolve` finds in either area
  (pinned by the suite: *"create.sh refuses a slug that exists in archive/"*). It did not fire
  here because it resolves against **the checkout it runs in**, and `/specificate` writes into a
  publish tree cut from `origin/main` — a mission on an unmerged publication is invisible there.
  Worse, the collision arrives by **merge**, where no create runs at all. So prevention at create
  is not merely costly (it would refuse a legitimate second attempt at an abandoned ask), it
  cannot reach this case, and it would leave the two pairs already in the tree unreported forever.
- **(b) refuse at the close or the move — rejected.** It fires at the moment the collision bites,
  but `archive.sh` runs unattended with no person attached, so it converts a silent collision
  into a refusal nobody reads.
- **(c) the audit — chosen.** It is where this repository already puts a structural finding the
  operator must rule on, beside `retired-area`, `renamed-area` and `retired-ticket-state`, and it
  is the only one of the three that names the pairs **already in the tree** — which is what the
  ticket was written about.

**Advisory, not a finding, and that is a decision rather than a default.** A finding sets
`conforming: false` and fails the `Validate Plugins` merge gate; both pairs are in the tree today,
so it would turn the base red and block every merge until somebody ruled on history that harms
nothing until something tries to move an active copy into an occupied archive.

### Step 3 — neither record deleted

Nothing here deletes, moves or rewrites either copy, and the advisory says so in its own text
(*the operator rules which record survives -- delete neither*). Both are history: the archived
copies carry the implementation changelogs and `actual_hours`, the active ones carry the
verification changelogs written earlier in this run.

### Step 4 — documented in the same change

`CLAUDE.md`'s mission-lifecycle section and `skills/mission/SKILL.md`'s *Lifecycle*, both stating
why `create.sh`'s existing guard cannot reach this and why the other two seams were refused.

### Verification

- `node scripts/test-workflow-scripts.mjs` — **5751 passed, 0 failed** (5748 before this ticket).
  The new case pins the advisory on exactly the shared slug, the *delete neither* wording, and
  that `conforming` stays `true` with zero findings.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` — `conforming: true`, both real pairs named.
- `build.mjs` + `verify.mjs` — clean.
- No script gained a second derivation of a mission's slug or of its lifecycle state: the walk is
  a directory-existence test in the audit and nowhere else.

### Discovered Insights

- **Insight**: A guard that resolves against "the tree" is only as wide as the checkout it runs
  in, and `/specificate` deliberately runs in a publish tree cut from `origin/main`. Any
  uniqueness check written for that caller is blind to every unmerged branch by construction.
  **Context**: `list-proposed-refs.sh` exists precisely because the dedup it does needed to walk
  unmerged branches. `create.sh`'s slug check never got that treatment, and the gap is invisible
  until a publication stays open long enough to matter.

- **Insight**: The collision arrives by **merge**, and a merge runs no writer — no create, no
  close, no move. A whole class of invariant cannot be enforced at any write seam for that
  reason, which is what makes the audit the right home rather than a weaker one.
  **Context**: This is the general form of the same lesson `/moderate`'s `cadence-lapse` step
  records: some findings have no object that a write seam ever touches, so only something that
  walks the tree can see them.
