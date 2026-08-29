---
created_at: 2026-08-29T19:31:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-two-executors-agree-about-a-proved-empty-claim
merge_policy:
verification_handoff: 
---

# Let the retirement act re-derive superseded where CI runs

## Overview

PROPOSED. The repair behind the silence ticket 1 makes legible. `Claim Retirement` is
green on every run and deletes nothing, because its candidate reader finds nothing — not
because an act is refused.

**Localized 2026-08-29, and this is the hypothesis to confirm before repairing anything**:
`lib/claims.sh` derives the resumability verdict **identity first**, by its own comment —
*"Identity first: a foreign claim is untouchable at any age, so its liveness never even
needs measuring."* An empty `_cs_me` answers `identity_unresolved` and a differing author
answers `foreign_identity`, both **before** `claims_superseded` is consulted. `_cs_me` is
`git config user.email`; `actions/checkout@v4` configures none. Every claim would then
read `identity_unresolved`, `superseded` would never be reached, and the candidate set
would be empty with `ok: true` — exactly the recorded reading.

This is **not** the failure PR #728 answered. That repair (`gh-rest.sh available`,
`GET /user` → `GET /rate_limit`) is on the base and correct; the earlier finding that
*"under an Actions-style credential the two executors' candidate readers agree"* varied the
**credential** and never varied the **git identity**, which is the term that decides here.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:safety` / `policies/least-privilege.md` — a destructive act keeps its narrowest bound
- `workaholic:operation` / `policies/runtime-resilience.md` — a proof that cannot be read is not a proof

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the verdict precedence
  (identity → ancestry → `claim_active` → `superseded` → the drained fork) and
  `claims_superseded`, the proof itself.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the bounded
  act, which **re-derives the verdict at the moment of the delete** and refuses every
  other verdict by its own word.
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate
  reader, answering only `superseded_only` units.
- `.github/workflows/claim-retirement.yml` — the executor, its `contents: write` grant and
  its defined full-history checkout.
- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*, *Which
  act runs where*, and the bounds the act must keep.

## Implementation Steps

1. **Reproduce and confirm the localization before changing anything.** Run
   `list-retirable-claims.sh` in a fixture with `user.email` **unset** and again with it
   set to the claims' author, and show the candidate count moving 0 → 3. If it does not,
   the hypothesis above is wrong and the real term must be found before step 3.
2. Establish the same for `delete-retired-claim-branch.sh`'s own re-derivation, since it
   re-proves the verdict independently and would refuse for the same reason.
3. Choose the repair and **argue it in the branch story**. Candidates, with the
   trade-off that decides between them:
   - Configure `user.email` in the workflow from the claim's own author. Cheapest, and the
     most dangerous if done globally — CI would then read *every* claim as its own.
   - Reorder so `superseded` is consulted before the identity gate. `superseded` is a proof
     about the **tree** and is identity-independent by construction, but reordering a
     safety-critical precedence affects every consumer, not just this one.
   - Resolve identity per claim inside the bounded act, leaving the shared precedence
     untouched. Narrowest, and the only one whose blast radius is one script.
4. **The bound no repair may cross**: a branch behind a **live** claim, or behind a claim
   whose author is not this repository's own runner, must not become deletable. The
   identity gate exists to protect a takeover; whatever replaces it here must protect the
   same thing, and the drill in ticket 3 is what proves it.
5. Widen nothing else: no verdict word is added, the proof gate stays `superseded`
   re-derived at the moment of the act, and `retire-claim.sh`'s container behaviour is
   byte-identical.
6. After the change lands, confirm on this repository that the three named units'
   branches (`work-20260819-063001`, `work-20260821-035855`, `work-20260818-205051`) are
   gone from origin and the claim table has shrunk.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The two executors' candidate readers agree over the same refs.
- The three named branches are gone from origin and the claim scan no longer lists them.
- No branch behind a live or foreign claim is deletable by either executor.
- No verdict word added; `retire-claim.sh`'s container behaviour byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-ci-retirement` and `verify-retire`
- Ticket 3's new drill row, including its breaker.
- `git ls-remote --heads origin 'work-*'` after the change, on this repository.

**Gate** — what must pass before approval:

- All drills pass, the breaker is proved able to fail, and the step-1 reproduction and the
  step-3 argument are both recorded in the branch story.

## Considerations

- Step 6's confirmation runs against the live origin and is the one part a hermetic drill
  cannot prove; the drill proves the mechanism, the origin proves the outcome.
- If step 1 disproves the hypothesis, the remaining suspects are the refspec (the job
  widens it and fetches every head explicitly), the graft boundary, and
  `claim-merged.sh`'s three-valued lookup answering `unanswerable` under the installation
  token — all reachable from the same reproduction.
- Doing nothing is not neutral: every later tick re-derives the same refusal and asks the
  same person the same held question, while the claim table only grows.
