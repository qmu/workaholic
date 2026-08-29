---
created_at: 2026-08-29T21:20:56+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
verification_handoff: 
---

# Order an improving direction against its rivals

## Overview

PROPOSED. The ask's 改良中 carries one behaviour the other two do not: the direction's
"priority rises and falls **relative to the other active strategies**", because the
operator runs several directions that reference each other and improve as a blend.

The survey already has the seam for this and no other: eligible strategies are **ordered**
(nearest `target_date` first, late-first within that) and the order is a **proposal about
attention, never eligibility** — `pace` was admitted on exactly that ground, that it
changes order and never a gate. So the stage participates in the **sort** and in nothing
else.

The rule: among eligible directions, 改良中 sorts by the terms the survey already holds
(late-first, then nearest date), while 進行中 sorts after them on the same terms — a
direction that cannot be cut over yet is still building, and a blend's attention belongs
to the ones that can absorb it. 観察中 never appears here at all, having been refused one
ticket earlier. **No new term, no weight, no tunable constant** — the ordering is a
lexicographic key over fields already on the row.

Since `over_cap` was retired, a tick proposes against **every** eligible direction, so
the sort decides only which one a tick that dies partway has advanced. That bounds the
blast radius of this change and is why it is admissible as a sort rather than a gate.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:planning` / `policies/prioritization.md` — how competing directions are ranked

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the eligible sort;
  the stage joins the existing key and the header states the full ordering in one place.
- `plugins/workaholic/skills/propose/SKILL.md` — the ordering rule and its bound.
- `plugins/workaholic/skills/strategy/SKILL.md` — 改良中's competitive reading.
- `CLAUDE.md`.

## Implementation Steps

1. Read the survey's sort and the retired-`over_cap` argument in its header whole —
   the reason the cap ran *backwards* is the reason a sort must not become a gate.
2. Extend the eligible sort key with the stage as its **first** component (改良中 before
   進行中), leaving the existing components and their order untouched beneath it.
3. Leave `refused[]`, every gate, `selected`'s membership and every reading
   byte-identical: only the **order** of `eligible[]` and `selected[]` may move, and only
   among directions of different stages.
4. State the whole ordering in the script header in one place, so no consumer re-derives
   it, and name the refusals: no weight, no score, no tunable constant, and no
   cross-direction arithmetic — the operator's declared stage is the only new input.
5. Record why 進行中 sorts second rather than first, and record the counter-argument
   (work that cannot be cut over is the riskiest and might deserve attention first) with
   the reason it lost: 改良中 is the stage the operator declared *can absorb* proposals,
   and a blend's proposing energy belongs where it converts to shipped behaviour.
6. Update `CLAUDE.md` in the same change.
7. Extend the hermetic suite: a fixture with one 改良中 and one 進行中 direction sharing a
   `target_date` sorts 改良中 first; membership of `eligible[]` and `selected[]` is
   unchanged; a fixture with one stage present sorts byte-identically to today.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two eligible directions with equal date terms sort 改良中 before 進行中.
- Set membership of `eligible[]`, `refused[]` and `selected[]` is byte-identical to today
  for every fixture.
- A repository whose directions all carry one stage (or none) produces byte-identical
  output to the pre-change survey.
- No numeric priority, weight or constant is introduced anywhere.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose`

**Gate** — what must pass before approval:

- The stage changes order and nothing else; a hermetic diff proves eligibility unmoved.

## Considerations

- "Priority rising and falling" could be read as an operator-set numeric rank. It is
  refused here: a rank is a second thing to keep current, and the stage plus the existing
  date terms already order the set. If the operator later asks for an explicit rank, it
  is a separate ask against a working ordering rather than a guess made now.
- With `over_cap` retired the sort is nearly cosmetic on a healthy tick. That is stated
  rather than hidden — it is what makes the change cheap and reversible.
