---
created_at: 2026-08-27T08:22:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-re-resuming-a-declared-handoff-unit
merge_policy:
verification_handoff: 
---

# Classify the verdict and update the documents

## Overview

Finish the change where this repository requires it: the new word must be classified in the
one table that says which verdicts a consumer may **act** on, and every document describing
the claim protocol and the handoff route must say what is now true. Outdated documentation is
a defect by `CLAUDE.md`'s own rule, and the classification is pinned by the suite rather than
left as prose.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*, the one
  place a word is classified, and the verdict definitions.
- `plugins/workaholic/skills/drive/SKILL.md` — §6 (the `handoff` route) and §7 (the token
  table).
- `CLAUDE.md` — the *Claim protocol* section and the `verification_handoff` paragraph under
  *The ticket spine*.
- `scripts/test-workflow-scripts.mjs` — the pin that fails when the table and its consumers
  disagree.

## Implementation Steps

1. Classify the word in *Proofs and judgements*. The reading it rests on **can become false
   by looking again** — that is the release condition, and it is the property the table's own
   definition of a proof excludes — so it is a **judgement**, and no consumer may act on it
   beyond declining to offer it. State that reasoning in the table's own terms rather than
   asserting the verdict.
2. Extend the suite's existing pin to cover the new word, so a later change that acts on it
   from `retire-claim.sh` or `retry-undelivered.sh` fails the suite.
3. Update `drive/SKILL.md` §6: the claim stays standing **and** is no longer offered, which is
   what §6 already meant and could not deliver.
4. Update `CLAUDE.md` in the same change: the `verification_handoff` paragraph's claim that a
   standing handoff claim "is not re-surveyed and costs nothing per tick" becomes true, and the
   *Claim protocol* section gains the new word with its measured origin (PR #647, 2026-08-27).
5. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) — the drive skill's script
   closure changed — and verify it.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The new word appears exactly once in *Proofs and judgements*, classified with its reason.
- The suite fails when the table and a consumer disagree about it.
- §6, §7 and `CLAUDE.md` describe the shipped behaviour, with no surviving sentence claiming
  the old one.
- `outputs/` is regenerated and clean.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — no diff.
- `git grep` for the retired wording returns nothing outside git history.

**Gate** — what must pass before approval:

- The suite, the build and the verify all pass, and `outputs/` shows no diff.

## Considerations

- Classifying it a **proof** is the tempting error: the declaration is read straight off the
  tree, which looks like the property `superseded` has. It is not — a proof is a reading that
  *cannot* become false by looking again, and this one is designed to, which is exactly the
  release condition the mission demands.
- The documentation update is part of this mission and not a follow-up: shipping the behaviour
  without it leaves `CLAUDE.md` asserting the defect's absence, which is how the gap survived
  from 2026-08-14 to 2026-08-27.
