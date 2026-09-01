---
created_at: 2026-09-01T06:20:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: 20260901032409-a-clean-stranded-publication-is-delivered-by-nothing.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
claim: work-20260901-070504
---

# Check a stranded proposal is still worth landing

## Overview

Minted mid-run 2026-09-01 by the tick that first delivered the loop's own long-stranded
publications. Giving the `clean` class an owner and repairing the mergeability reader worked: three
proposals that had been open for up to six days were caught up and merged in one tick.

**What they queued was work the loop had already done.** Both merged proposals carried a mission
plus its ordered ticket set, written against a base six days older than the one they landed on:

- `#625` (opened 2026-08-26) → mission `say-when-the-loop-has-run-out-of-direction`, 8 tickets
  including *write the one reader of a direction's lifecycle state* and *add the moderate step
  direction-health*. Both exist on the base:
  `plugins/workaholic/skills/strategy/scripts/direction-state.sh` and
  `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh`, and `CLAUDE.md` documents
  the whole reader table and the step.
- `#688` (opened 2026-08-28) → mission `deliver-what-the-loop-already-knows-to-the-person-who-can-act`,
  7 tickets including *drill the check-in delivery path with no network* and *read back what the
  check-in delivered and held*. Both exist: `verify-checkin-delivery` is in
  `scripts/e2e/loop-drill.sh` and `step-human-checkin.sh` reports `delivered` / `held_count` /
  `candidates`.

So the same tick that unblocked the delivery path put ~15 tickets for finished work into
`tickets/todo/`, where the next `/implement` will claim them. **Nothing anywhere checks whether a
proposal is still worth landing**, because until this week no proposal stayed open long enough for
it to matter: `publish-tree-pr.sh` auto-merges on opening, so a proposal's plan was written and
landed minutes apart.

This is a consequence of the repair, not an argument against it. What is missing is the check that
the repair made necessary.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — the act that
  delivers a stranded publication. Where a staleness reading would sit, if it belongs in the act.
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` — the reader. It
  already carries `created_at` per publication, so an age is in hand with no extra call.
- `plugins/workaholic/skills/moderate/scripts/step-stranded-publications.sh` — where a publication
  a person must judge already reaches that person, and the natural home for a second such case.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` and
  `plugins/workaholic/skills/mission/scripts/` — the survey and the mission readers, if the answer
  is instead to notice a queued ticket whose work already exists.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the `stranded-publications` step's
  own spec, and the `closable-missions` step, which closes a mission the archive gate can prove.

## Implementation Steps

1. **Establish the size of the problem before choosing a place to fix it.** For every open
   publication the reader names, record its age and whether its diff would queue a mission or a
   ticket set. Then, for the two missions this incident queued, record how many of their tickets
   name files that already exist and how many name behaviour `CLAUDE.md` already documents. A
   ticket whose work is done and a ticket whose work is merely *similar* are different findings;
   do not collapse them.
2. **Decide which of three seams owns the check, and say why the other two do not.**
   (a) **The act** — refuse to settle a publication older than some age, or one whose diff adds a
   mission, and send it to a person. Cheapest, and the bluntest: it would strand exactly the
   publications this week's work exists to deliver.
   (b) **A question** — `/moderate`'s `stranded-publications` step already asks about what a
   person must judge; a second key could ask *is this still worth landing* before anything merges
   it. Keeps the act unconditional and puts the judgement where judgements go.
   (c) **After the fact** — notice a *queued* ticket whose work is already on the base, wherever it
   came from. The most general and the hardest to make honest: "already implemented" is a judgement
   about behaviour, not a file test.
   State the decision and the rejected alternatives with their costs, as this repository does.
3. **Whatever is chosen, no age becomes a gate that silently drops work.** A publication nobody
   settles must reach a person; the failure this repository has paid for repeatedly is a reading
   that stops something and tells nobody.
4. **Do not auto-close or auto-abandon the two missions this incident queued.** They are the
   evidence, and `abandoned`/`carried` assert intent that only the operator holds
   (`mission/scripts/close.sh`). If the reading is that they are finished, the honest route is the
   `closable-missions` proof — acceptance checked, queue empty — and neither is.
5. **Say in the docs which seam owns it**, in the same change, wherever the class boundary is
   already stated (`CLAUDE.md`, `workaholic:drive` §5/§7, `moderate/reference/workflow.md`).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The measurement from step 1 is written down: per open publication its age, and per queued ticket
  from the two affected missions whether its work exists on the base.
- A stranded proposal whose plan the loop has already executed is either not merged unattended, or
  is merged and the fact reaches a person — never merged silently as it was this tick.
- No age threshold drops a publication without telling anybody, and the `content` question's key,
  cap and addressee are unchanged.
- No mission is closed, abandoned or carried by this change.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` with each
  publication's `created_at` read beside its class.
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-stranded-publication`
- The two affected missions read by hand against the tree.

**Gate** — what must pass before approval:

- The act keeps one merge attempt, its own refusal words, and the release-safety gate ahead of the
  merge; no loop, no poll, no gate override.
- `reference/claims.md` gains no row and no claim verdict word is introduced.

## Considerations

- **The window this opens is new, and small.** `publish-tree-pr.sh` auto-merges on opening, so a
  proposal is normally landed within minutes of being written; only a publication the transport
  refused stays open long enough to go stale. That is exactly the set this week's work delivers,
  which is why the check is needed now and was not before.
- **A queued ticket for finished work is not free.** The next `/implement` claims it, drives it,
  finds nothing to do and produces an empty or near-empty change — a full unit's cost per ticket,
  and roughly fifteen of them are queued right now.
- **Rejected while minting**: reverting the two merges. They carry the missions' own records and a
  revert would lose the evidence and the attribution; and the proposals were correct when written.

## Final Report

Development completed as planned.

### Step 1 — the measurement, before choosing a seam

**Open publications, with ages** (`list-stranded-publications.sh`, 2026-09-01 07:10 UTC): one
remains — `#622`, 140 hours (5 days), class `content`. The other five were settled earlier the
same run: `#799` and `#635` delivered, `#813`, `#688` and `#625` settled with the merge refused
`merge_not_allowed` and delivered shortly after.

**The two missions those publications queued**, counted separately for *done* and *similar*, as
the ticket required:

| Mission (from) | Queued tickets | Exact-title archived twin | Work exists under another title |
| -------------- | -------------: | ------------------------: | ------------------------------: |
| `deliver-what-the-loop-already-knows-…` (#688) | 7 | 0 | **7** |
| `say-when-the-loop-has-run-out-of-direction` (#625) | 8 | **5** | 3 |

The first mission's seven were verified individually against the running behaviour and archived
earlier in this same run; its acceptance closed 3/3 with an empty queue. The second mission's
five exact-title twins all sit in `.workaholic/tickets/archive/work-20260826-084111/`; the
remaining three name no twin but their work is present anyway — `direction-state.sh`,
`step-direction-health.sh` and the `dormant`/`overdue` readings in `survey-strategies.sh` all
exist on the base under differently-worded ticket titles.

**That table is the argument against seam (c).** Five of eight were catchable by an exact-title
match; three were not, and their work was done. *Already implemented* is a judgement about
behaviour, exactly as the ticket warned, and a file test would have been wrong three times out
of eight in the one place it was measured.

### Step 2 — the seam, and why the other two do not own it

**Chosen: (b), the question — with the act left unconditional.**

- **(a) the act — rejected.** An age threshold that refuses to settle would strand precisely the
  publications this week's work exists to deliver: five of six open publications were `clean`
  and 1–6 days old, so any threshold under six days refuses all five. The `clean` widening
  landed hours earlier for exactly the reason that they were green and delivered by nothing.
- **(c) after the fact — rejected as a gate**, on step 1's own numbers above. It survives as
  *evidence* — which is what a driving run should do by hand, and did seven times this run — but
  it cannot be a mechanism.
- **(b) the question — chosen.** `/moderate`'s `stranded-publications` step already asks about
  what a person must judge; the second key puts this judgement in the same place. The act stays
  unconditional, so nothing is stranded and nothing is dropped, and the acceptance criterion's
  second branch is satisfied: merged **and** the fact reaches a person.

### Step 3 — no age becomes a gate that silently drops work

Nothing refuses, holds, delays or closes on the age. Pinned as behaviour by the suite: the act
settles and delivers a publication over the threshold identically to one under it, reporting the
age it acted on. The `content` question's key, cap and addressee are untouched.

### Step 4 — no mission closed, abandoned or carried

Nothing here closes a mission. (Separately in this run, `archive.sh`'s own arithmetic gate closed
`deliver-what-the-loop-already-knows-…` `achieved` after its queue drained — that is the
`closable-missions` proof the ticket names as the honest route, not this change.)

### What was built

- `branching/scripts/lib/publication-age.sh` — the one derivation, now shared by
  `publication-effect.sh` (whose output shape is unchanged: `age_hours: 78` on #694),
  `list-stranded-publications.sh` and `settle-stranded-publication.sh`. Null, never `0`.
- `list-stranded-publications.sh` gains `age_hours` per publication, from the `created_at` it
  already carried — no extra call.
- `settle-stranded-publication.sh` reports `age_hours`, read off the row whose verdict it
  re-derived at the moment of the act. No refusal added.
- `step-stranded-publications.sh` gains `stranded-publication-stale:<number>`, disjoint from the
  `content` set by construction.
- Documented in `CLAUDE.md`, `moderate/reference/workflow.md` and `workaholic:drive` §7.

### Verification

- `node scripts/test-workflow-scripts.mjs` — **5748 passed, 0 failed** (5737 before; 11 new
  assertions in `moderate/stranded-publications: a publication old enough that its plan may be stale`).
- `sh scripts/e2e/loop-drill.sh verify-stranded-publication` — pass, 11 load-bearing, 2 breakers.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` — `conforming: true`.
- `build.mjs` + `verify.mjs` + `validate-metadata.mjs` — clean.
- `reference/claims.md` gained no row and no claim verdict word was introduced.

### Discovered Insights

- **Insight**: The act and the question deliberately race, and the race is safe in both
  directions — if the act wins the hour, the question is the record that nothing landed
  silently; if the person wins, they close the pull request.
  **Context**: The instinct is to make the question a precondition of the act, which would
  reintroduce seam (a) through the back door and strand the deliverable set. Independence is the
  design, not an accident of scheduling.

- **Insight**: `age_hours` had to be `null` rather than `0` on an unreadable timestamp, because
  zero reads as *opened this second* — the one answer that makes a stale publication look fresh.
  **Context**: `cadence-state.sh` records the identical reasoning for its own null age. That is
  now twice in this repository, which makes it a convention rather than a local choice.
