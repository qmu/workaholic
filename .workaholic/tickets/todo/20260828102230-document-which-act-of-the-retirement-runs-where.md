---
created_at: 2026-08-28T10:22:30+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-a-proved-retirement-where-the-write-is-permitted
merge_policy:
verification_handoff: 
---

# Document which act of the retirement runs where

## Overview

PROPOSED. The split now spans two executors, and this repository's rule is that a change
altering behaviour updates every affected document in the same change. Three documents
carry the retirement's record today and each currently says the act cannot be taken at all.

The correction is narrow and must not overstate itself: the 2026-08-27 finding that *no
second transport can take the act* was **measured and remains correct about the container**.
What changes is that the act moves to a different executor, which is precisely why
`release-note-draft.yml` exists. Write it that way — the finding closed the gap inside the
box; this mission moves the act outside it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — *When an act of the retirement is
  refused*: the transport table, the "no second transport" paragraph and the licence
  sentence at its end
- `CLAUDE.md` — the claim-protocol bullet on the retirement, and the drill enumeration
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — its header's account
  of why the question exists and what it is narrowed to
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — Act 2's header comment
- `plugins/workaholic/rules/shell.md` — read to confirm nothing there needs a qualification

## Implementation Steps

1. Update `drive/reference/claims.md`: keep the measured transport table verbatim, keep the
   "no second transport **in the container**" finding, and add which act runs where and why
   a workflow is a different executor rather than a second transport.
2. State explicitly that `superseded` stays a **proof**, that no verdict word was added, and
   that the *Proofs and judgements* tables are unchanged — a later reader must not have to
   re-derive that.
3. Update the licence sentence: the blocked question is narrowed to what CI could not take.
4. Update `CLAUDE.md`'s claim-protocol bullet and add `verify-ci-retirement` to the drill
   enumeration.
5. Update the two script headers to name their own side of the split, and re-read Act 2's
   comment so it no longer reads as "and nothing can be done".
6. Confirm `rules/shell.md` needs no change: the REST-only rule is untouched, and CI reaches
   GitHub through the same `gh-rest.sh` seam.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- All three documents describe which act runs where, and the container's measured refusal
  is preserved rather than deleted
- `superseded` is stated to remain a proof with no new verdict word
- `CLAUDE.md`'s drill enumeration names `verify-ci-retirement`
- No document claims the container can take the delete

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the pins over the proofs tables
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- Both pass, `git diff` shows no generated file hand-edited, and a reader of
  `claims.md` alone can say which executor takes each act

## Considerations

- The failure mode here is deleting the measurement. The 403 table and the reasoning behind
  it are the evidence for the whole mission; they stay, with the scope of the finding made
  explicit rather than narrowed by omission.
- Do not add a row to the *Proofs and judgements* tables. The executor of an act is a
  different axis from what a claim reads, exactly as `branch_delete_failed` already is.
