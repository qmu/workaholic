---
created_at: 2026-08-27T11:25:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-operator-revise-a-live-direction-through-the-loop
merge_policy:
verification_handoff: 
---

# Hold a revised strategy to the write-time floor

## Overview

PROPOSED. `hooks/validate-strategy.sh` holds a strategy to three properties — a
`YYYY-MM-DD` `target_date`, non-empty `assignees`, non-empty `## Aim` and `## Schedule` —
and **grandfathers git-tracked files**, because history is never retro-blocked. Every
strategy an amendment touches is git-tracked, so the hook is silent on exactly the writes
this mission adds. The floor must therefore hold at the writer, refusing **before**
anything is written rather than leaving a half-applied file.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/hooks/validate-strategy.sh` — the floor's canonical definition and
  the grandfathering rule that makes it silent here.
- `plugins/workaholic/skills/strategy/scripts/amend.sh` — where the floor is enforced.
- `plugins/workaholic/skills/strategy/scripts/create.sh` — already refuses the same four
  things; the refusal names must match it exactly rather than being re-invented.

## Implementation Steps

1. Read `validate-strategy.sh` in full and enumerate its three properties as the hook
   states them — not as remembered.
2. In `amend.sh`, evaluate the **post-revision** artifact against those properties before
   writing: an empty Aim, an empty Schedule, an empty assignee list or a non-`YYYY-MM-DD`
   date is refused with nothing written and the file byte-identical.
3. Reuse `create.sh`'s refusal vocabulary verbatim (`bad_target_date` / `no_assignees` /
   `empty_schedule` / `empty_aim`) so one artifact does not acquire two names for one
   refusal.
4. Prove the ordering, not just the outcome: a refused revision leaves the working tree
   and the index untouched — no partial write, no staged half.
5. Say in the hook's own header that the writer carries the floor for amendments and why
   the grandfathering makes that necessary, so the next reader does not conclude the hook
   covers it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each of the four breaches is refused by its `create.sh` name with nothing written.
- A refused amendment leaves the file and the index byte-identical.
- A valid amendment satisfies `validate-strategy.sh` by construction.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Hermetic exercise over a throwaway root, asserting the file's hash across each refusal.

**Gate** — what must pass before approval:

- The suite is green and the byte-identity assertion is present, not implied.

## Considerations

- The temptation is to write first and validate after, then revert. Do not: a revert is a
  second write, and the contract this artifact needs is that a refusal never wrote.
