---
created_at: 2026-09-02T06:28:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: retire-a-claim-whose-work-is-finished-or-abandoned
merge_policy:
verification_handoff: 
---

# Name a claim whose mission ended as a retirement candidate

## Overview

PROPOSED. `list-retirable-claims.sh` names two classes today — `superseded_only` and,
per branch, `pull_request_merged` / `pull_request_closed_unmerged`. A claim whose mission
was closed `abandoned` while its pull request is still open matches none of them, so it is
retired by nobody. Add that third class, bounded exactly as the other two are.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate
  reader; the per-branch arm is where the class joins.
- `plugins/workaholic/skills/drive/scripts/claim-mission-state.sh` — the previous ticket's
  reader, composed here and never reimplemented.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the act, whose
  bounds (`not_a_work_branch` / `release_branch` / `not_on_base` / `pull_request_open`)
  decide what this class may hand it.
- `.github/workflows/claim-retirement.yml` — the runner that acts on the candidates.
- `plugins/workaholic/skills/drive/reference/claims.md`, `CLAUDE.md` — where the class and
  its bound are stated.

## Implementation Steps

1. **Reproduce and localize first.** Show that a branch whose unit's mission is archived
   and whose pull request is open yields no candidate today, and name which arm dropped it.
2. Add `candidate_reason: mission_not_active` to the per-branch arm, keyed on
   `claim-mission-state.sh`'s `not_active`, carrying the mission's `status` on the row.
3. Keep every existing precedence: a **live** claim row beats it, a branch already named by
   the first class is not read twice, and an unreadable mission yields **no** candidate and
   its reason on `unreadable[]` — never a candidate.
4. Decide and state whether `delete_branch_on_merge`'s `pull_request_open` bound still holds
   for this class. The mission is abandoned but the pull request may be open, so the act
   would refuse; either the bound is widened for this reason with the argument written down,
   or the class closes the pull request first through `retire-claim.sh`'s existing order.
   Write the decision into `claims.md`; do not widen a bound silently.
5. Carry the `branch_empty` evidence onto the row as the other classes do — evidence, never
   a gate.
6. State the class in `claims.md` and in `CLAUDE.md`'s retirement paragraph, in the same
   commit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A branch whose unit's mission is archived is a candidate with
  `candidate_reason: mission_not_active` and the mission's `status` on the row.
- A live claim row on that unit beats it and yields no candidate.
- An unreadable mission yields no candidate and appears in `unreadable[]` with its reason.
- A `batch-<ts>` unit is never named by this class.
- The delete act's behaviour under an open pull request is what `claims.md` says it is.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic cases in `scripts/test-workflow-scripts.mjs` over throwaway repositories, one
  per criterion, with no network and no `gh`.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

## Considerations

- The strongest existing candidate is a proof about content (`superseded`). This one is a
  person's decision, which is weaker; the safety argument therefore has to be written, not
  assumed, and step 4 is where it is written.
- An abandoned mission's branch may hold work found on no other ref. Closing the mission
  `abandoned` is the operator saying that work is not wanted — the same reasoning
  `pull_request_closed_unmerged` already rests on — and `branch_empty` records how often it
  actually happens.
