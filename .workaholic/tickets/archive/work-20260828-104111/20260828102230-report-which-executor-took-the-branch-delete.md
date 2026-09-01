---
created_at: 2026-08-28T10:22:30+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-a-proved-retirement-where-the-write-is-permitted
merge_policy:
verification_handoff: 
---

# Report which executor took the branch delete

## Overview

PROPOSED. Once CI can take the delete, two different things can make a branch disappear,
and a reader must be able to tell them apart. `retire-claim.sh`'s three-act vocabulary
stays exactly as it is — `deleted`, `already_gone`, `failed`, `not_attempted` — and a
delete taken **elsewhere** must be reported as such rather than as one this container took.

The honest reading in the container is already available and already correct:
`already_gone` means the ref is not on origin. What this ticket adds is that the container
does not claim the act, and that `step-retire-claims.sh`'s summary and event distinguish
*this tick deleted it* from *it was already gone when this tick looked*, which the row's
existing states carry and the rendering currently blurs.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — Act 2; its vocabulary must
  not gain or lose a word
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the renderer of the
  retired/refused rows and of `event`
- `plugins/workaholic/skills/drive/reference/claims.md` — *When an act of the retirement is
  refused*; the record of what each word means

## Implementation Steps

1. Confirm by reading Act 2 that `already_gone` is emitted purely from
   `git rev-parse --verify refs/remotes/origin/<branch>` and asserts nothing about who
   removed the ref. Keep it that way.
2. Leave `retire-claim.sh`'s output shape byte-identical. This ticket adds no field and no
   word to it.
3. In `step-retire-claims.sh`, render a row whose delete was `already_gone` as the branch
   having been removed **elsewhere**, distinct from a row this tick deleted (`deleted`).
   The two states are already on the row; only the wording is wrong today.
4. Keep the event rule: the root line still names a repository event and a tick that
   retired nothing supplies no event. A branch CI deleted between two ticks is a real
   change and its summary moves; an unchanged block still renders identically.
5. Do not introduce a per-executor field anywhere. Which executor took the act is derivable
   from the two states that already exist.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `retire-claim.sh`'s JSON shape and its four Act-2 words are byte-identical to today
- A delete this container took and one it found already done render as different sentences
- No field is added to any artifact and no new word enters the claim vocabulary
- A held, unchanged block still renders an identical summary tick after tick

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire`

**Gate** — what must pass before approval:

- Both pass, and a fixture shows the two renderings differing on the same unit across two
  ticks (deleted, then already gone)

## Considerations

- The tempting design is a `deleted_by: ci|container` field. It is refused: the fact is
  already derivable from the row, and a stored answer is a second derivation that will
  disagree with the first.
- `already_gone` is a **success**, not a degradation, and must keep rendering as one — the
  same rule `already_closed` and `absent` already carry.

## Final Report

Development completed as planned.

`retire-claim.sh` is byte-identical: its JSON shape is unchanged and its four Act-2 words
(`deleted`, `already_gone`, `failed`, `not_attempted`) still come from exactly where they came
from — `already_gone` is still emitted purely from `git rev-parse --verify
refs/remotes/origin/<branch>` and asserts nothing about who removed the ref. Only
`step-retire-claims.sh`'s wording moved: a delete this tick took renders as *branch deleted here*
and one it found already done as *branch removed elsewhere*, derived through one jq definition
shared by the retired and refused lines. `already_gone` keeps rendering as the success it is;
`failed` and `not_attempted` render exactly as before, which is why `verify-retire`'s existing
string assertions stayed green untouched. No per-executor field anywhere, and the event rule is
unchanged — a tick that retired nothing supplies no event.

### Discovered Insights

- **Insight**: `already_gone` is very nearly unreachable in a fixture, because the ref that
  produces the claim row and the ref Act 2 checks are the *same* freshly-pruned remote-tracking
  ref — so no two-tick fixture can hold a row whose branch is already gone.
  **Context**: that is why the two renderings are pinned at the source rather than driven
  behaviourally, and it is also why the wording matters: the state a reader meets rarely is
  exactly the one they will misread. The reasoning is recorded in the suite beside the assertion
  so a later reader does not spend an afternoon trying to build the fixture.
