---
created_at: 2026-08-29T19:21:37+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: follow-the-pull-requests-the-loop-opens-for-a-person
merge_policy:
verification_handoff: 
---

# Release a ruling hold the ruling's own silence has outlived

## Overview

PROPOSED. `ruling-suppression.sh` holds a subject's hourly question the moment an open
ruling names it — correct while the ruling is moving, and **wrong** once the ruling itself
has gone unanswered. The loop is then silent about the ruling **and** about what that
ruling holds, at the same time.

Measured 2026-08-29: #694 open 18 hours, `undrivable-unit:` questions held for the very
addresses it names, and `plan-units.sh` offering nothing over a backlog of 10 — 7 of them
excluded `owned_by_other` on the one address #694 would map.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one derivation, two readings
- `workaholic:operation` / `policies/observability.md` — a hold that outlives its reason is a silence

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ruling-suppression.sh` — the hold; its own
  header states the two properties that must survive (keyed on the **subject**, never on
  the existence of a ruling; an unreadable read suppresses nothing).
- `plugins/workaholic/skills/moderate/scripts/step-undrivable-units.sh` — one consumer.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the other.
- `plugins/workaholic/skills/moderate/scripts/step-standing-rulings.sh` — the drafter, and
  the *at most one open ruling at a time* brake the hold interacts with.
- `plugins/workaholic/skills/moderate/scripts/list-open-rulings.sh` — the brake's reader.

## Implementation Steps

1. **Reproduce first**: over the live tree, show a subject held by a ruling whose own
   pull request is un-acted, and show that no question about either reaches anybody.
2. Decide the repair between the two the ask names, and **prefer the one that adds no
   second reading**: either the ruling's *own* question (ticket 3's) makes the subject
   reachable — the person is asked about the pull request that holds it — or the hold is
   released once the ruling is un-acted. Ticket 3 already asks the holder about the
   ruling, so releasing the hold **as well** would ask one person twice about one thing,
   which is the doubling `handoff-units` and `stalled-units` were split to avoid.
   Recommended: keep the hold, and let ticket 3's question be what breaks the silence —
   with the hold's own reading and ticket 3's candidate set sharing **one** derivation so
   they cannot diverge.
3. Wire whichever is chosen so both readings compose the same script. Two copies of *is
   this ruling still moving* is exactly the drift `ruling-suppression.sh`'s header forbids.
4. Preserve, provably: the hold stays keyed on the **subject**; a partially covered
   residue still asks and says so; `overdue` and `dormant` are never held; an unreadable
   read holds nothing; `ask-question.sh` gains nothing.
5. Hermetic coverage: an open, recently-drafted ruling still holds its subjects; the same
   ruling un-acted produces a question that reaches its person; and no subject the ruling
   does not name is affected in either state.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The loop is never silent about a ruling and about what that ruling holds at the same time.
- One person is never asked twice, in two vocabularies, about one pull request.
- Both readings share a single derivation of whether the ruling is still moving.
- The hold stays keyed on the subject; an unreadable read holds nothing; `overdue` and
  `dormant` are never held.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the three cases in step 5)
- Ticket 7's drill asserting the held and released states over consecutive ticks.

**Gate** — what must pass before approval:

- The suite passes and `ask-question.sh` is byte-identical.

## Considerations

- Releasing the hold on a timer would introduce a threshold this layer has refused
  elsewhere by name; the un-acted reading is already available from ticket 1 and needs no
  new constant.
- The brake (*at most one open ruling at a time*) is deliberately untouched here: a second
  ruling drafted over an unanswered one hands the operator two competing diffs, which is
  the failure that brake exists to prevent.

## Final Report

**Implemented — as the ticket's own recommended option, which required no behaviour change to
the hold.**

- **Reproduced first (step 1).** Live: #694 open **18 hours**, `ruling-suppression.sh` reporting
  `any_open: true`, and no question about the ruling reaching anybody from any step.
- **A second measurement changed the picture and is recorded rather than smoothed over.** #694
  holds **nothing**: its body carries no `ruling: <kind> / subject: <subject>` markers at all
  (`publish-tree-pr.sh` composes the body itself from a fixed template), so
  `ruling-suppression.sh` answers `held: {"attribution": [], "identity_mapping": []}`. The ask's
  measured claim that #694 was *holding the `undrivable-unit:` questions for the very addresses
  it names* is therefore **not reproducible today** — the questions were being asked. What **is**
  real, and what this mission fixes, is the other half: nothing told anybody about the ruling
  itself. That marker loss is a separate defect and is minted as ticket
  `20260829200500-carry-the-ruling-s-subject-markers-into-its-pull-request-body`.
- **The repair (step 2): keep the hold; ticket 3's question is what breaks the silence.**
  Releasing the hold *as well* would ask one person twice, in two vocabularies, about one pull
  request — the doubling `handoff-units` and `stalled-units` were split to avoid. Releasing on a
  **timer** is refused by name as a threshold this layer has refused elsewhere.
- **One derivation (step 3):** `step-operator-pulls.sh` **composes `ruling-suppression.sh`** for
  what a ruling holds rather than re-deriving the subject list, so the hold's reading and the
  question's cannot diverge. Pinned by the drill and by the suite.
- **Preserved, provably (step 4):** `ruling-suppression.sh` is behaviourally **byte-identical**
  (header prose only) — the hold stays keyed on the **subject**, an unreadable read suppresses
  nothing, `overdue` and `dormant` are never held; `ask-question.sh` gained **nothing**; both
  consumers are untouched.

**Gate:** the suite passes and `ask-question.sh` is byte-identical (`git diff` shows no change
to it). Ticket 7's drill asserts the shared reading and the subject-keying over consecutive
ticks.
