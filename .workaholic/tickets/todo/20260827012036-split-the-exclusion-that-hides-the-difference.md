---
created_at: 2026-08-27T01:20:36+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Split the exclusion that hides the difference

## Overview

`claimed_reported` covers two states a reader cannot tell apart: a unit **legitimately waiting on
a person** (a scan finding holds its pull request open) and the loop's **own undelivered work** (a
transport refusal stopped the merge and nobody was told). Both read `queue_drained` in
`lib/claims.sh`, both are excluded `claimed_reported` by `plan-units.sh`, and no later survey
offers either again — so the second is reachable by nothing.

This is precisely the shape the 2026-08-19 `report_incomplete` split fixed one layer up, and its
own header says why: a reason must imply its own next action, and folding two next actions into
one word is what makes the invisible half invisible. Give the undelivered state its own reason.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — one reason, one next action

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the shared derivation that produces
  `queue_drained` / `report_incomplete` / `superseded`. **Read its header whole** before adding a
  verdict: the ordering of the verdicts (`claim_active` first, then `superseded`, then the drained
  fork) is load-bearing and each position is justified there.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — lines ~60–140 and ~270: the exclusion
  vocabulary and its mapping from claim reason to exclusion reason, plus the header paragraphs
  recording why each reason exists separately.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the per-claim row the survey reads.
- `plugins/workaholic/skills/drive/scripts/claim.sh` — its refusal loop reads the same derivation,
  so the offer and the refusal cannot disagree (the 2026-08-27 `superseded` fix).
- `plugins/workaholic/skills/drive/reference/claims.md` — the protocol's full statement.

## Implementation Steps

1. Read `lib/claims.sh`'s header and `plan-units.sh`'s reason paragraphs, and write down where the
   new verdict sits in the existing order and why — the position is part of the change.
2. Derive the split from the reading the first ticket added (pull request open, and the run's own
   recorded merge outcome), never from a second lookup.
3. Emit the new reason from `lib/claims.sh`, surface it in `list-claims.sh`'s row and map it to its
   own exclusion reason in `plan-units.sh`. `claimed_reported` keeps meaning **waiting on a
   person** and nothing else.
4. Decide and state whether the new state is resumable, in the header, with the reason — the
   2026-08-19 split's `resumable: true` and 2026-08-26's `resumable: false` are both precedents and
   they went opposite ways for stated reasons.
5. Make `claim.sh`'s refusal loop read the same derivation, so a unit the survey offers is not
   refused by the claim (the failure the 2026-08-27 `superseded` fix records).
6. Update `drive/reference/claims.md`, `drive/SKILL.md` and `CLAUDE.md`'s claim-protocol section in
   the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A drained, reported claim whose merge was refused by the transport reads the new reason; one
  held by a scan finding still reads `claimed_reported`.
- `list-claims.sh` and `plan-units.sh` agree, both reading `lib/claims.sh`.
- `claim.sh` does not refuse a unit the survey offers.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Walk both claim shapes over a fixture and compare the row, the exclusion and `claim.sh`'s answer.

**Gate** — what must pass before approval:

- Every existing verdict is byte-identical over the existing fixtures; only the new one appears.

## Considerations

- Adding a verdict to `lib/claims.sh` changes what every consumer sees. The regression bar is that
  each existing verdict is unchanged over the existing fixtures — assert it rather than assume it.
- Resist deriving the split from a fresh network read per claim. `claim-merged.sh`'s three-valued
  `unanswerable` contract exists because a wrong verdict here releases work still in flight; an
  answer the run already recorded is stronger evidence than one re-fetched later.
