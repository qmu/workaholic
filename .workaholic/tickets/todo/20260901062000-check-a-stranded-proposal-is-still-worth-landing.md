---
created_at: 2026-09-01T06:20:00+00:00
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
