---
created_at: 2026-08-30T08:22:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Make the claim contend for one ref per unit

## Overview

**The repair ticket 2 named.** A fresh claim pushes a clock-named `work-*` branch, so two runners
contend for nothing and both win. The claim must contend for **one ref per unit**, so that the
first push wins at the **remote** — the only arbiter both runners share — and the second is
refused.

The oracle, its verdict vocabulary and the `work-*` branch naming stay exactly as they are: the
unmerged-`work-*`-branch scan is still the claim oracle, and a claim is still a `Claim <unit-id>`
commit on a `work-*` branch. What changes is that publishing the claim also publishes a
**unit-keyed ref** whose creation is atomic at the server, so winning is decided by the remote
rather than by the clock.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early
- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` §6 — where the claim commits and pushes
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_scan`, which must keep answering from `work-*` refs alone
- `plugins/workaholic/skills/branching/scripts/create.sh` — the clock-derived name, unchanged
- `plugins/workaholic/skills/drive/reference/claims.md` — records the mechanism ticket 2 described
- `scripts/e2e/loop-drill.sh` — `verify-claim-race` from ticket 1

## Implementation Steps

1. Re-read ticket 1's reproduction and `claim.sh` §§4–6 end to end before choosing a mechanism —
   the push is the last act of a sequence that has already created a worktree and a commit, and
   where the contention is inserted decides how much the loser has written when it loses.
2. Choose the contended ref and record the choice in `claims.md`: a ref derived **from the unit id**
   rather than the clock, so two claimants for one unit name one ref and two claimants for
   different units never collide. Push it with a **create-only** refspec, so the server refuses the
   second rather than fast-forwarding it.
3. Keep `claims_scan` reading `work-*` refs and nothing else — the contended ref is the **arbiter**,
   not a second oracle. A reader that consults it would be the second derivation this repository
   refuses by name.
4. Make the push **atomic** with the claim branch's own push where the transport allows it, so a
   won arbitration and an unpublished claim cannot come apart; where it cannot, push the contended
   ref **first**, since a won ref with no branch is recoverable and a branch with no ref is the
   defect.
5. Release the ref wherever the claim is released: `release-claim.sh`, `retire-claim.sh`, and the
   merge that releases a claim by definition. A ref nothing deletes makes every unit
   claimable exactly once, forever — name the release path for each in `claims.md`.
6. Run `verify-claim-race`: the second claimant must now fail at the push. Its refusal wording is
   ticket 4's; this ticket only has to make the push lose.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two claimants for one unit contend on one ref; the second push is refused by the server.
- Two claimants for **different** units never collide.
- `claims_scan` still answers from `work-*` refs alone and its verdicts are byte-identical for every
  claim in the existing fixtures.
- Every path that releases a claim releases the ref, each named in `claims.md`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-claim-race` shows the second push refused.
- `sh scripts/e2e/loop-drill.sh verify-all` passes (no other drill's verdicts move).
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- The race is lost at the remote, not by comparing clocks, and no verdict word was added.

## Considerations

- **Hypothesis, not design** (the ask proposed "one ref per unit" and this ticket adopts it after
  ticket 1's reproduction; if the reproduction shows the contention must sit earlier than the push,
  say so and re-scope rather than forcing the named mechanism).
- The container's transport refuses some ref writes (`retire-claim.sh`'s Act 2 is refused
  `branch_delete_failed` in a routine-fired container). Measure whether **creating** the contended
  ref is permitted there before building on it; if it is not, that is a finding for the mission, not
  a workaround to invent here.
- A leaked ref is worse than the race: it makes a unit permanently unclaimable. Step 5 is not
  optional, and ticket 8 should assert the release.
