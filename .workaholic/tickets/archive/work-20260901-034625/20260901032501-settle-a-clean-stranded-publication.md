---
created_at: 2026-09-01T03:25:01+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-a-stranded-publication-that-needs-nothing-but-a-merge
merge_policy:
verification_handoff: 
---

# Settle a clean stranded publication

## Overview

`settle-stranded-publication.sh` acts on `mergeability == mechanical` alone and refuses every
other class by name. Its own header states the reasoning for `clean`: it "needs no catch-up at
all" — true, and the consequence was not followed through, because the one REST merge that
delivers a publication sits *after* the catch-up. So a publication that needs nothing but a
merge reaches no act at all.

Measured 2026-09-01 and reproduced by the proposing run: `list-stranded-publications.sh` named
six open publications and five of them were `clean` (#813, #799, #688, #635, #625), the oldest
opened 2026-08-26. They are stranded by a race with their own CI — `publish-tree-pr.sh` opens
the pull request and attempts the merge in the same breath, GitHub answers 405 before any check
has started, and `merge-reason.sh` correctly classifies it `merge_not_allowed`, which is not a
retryable word for the caller.

This ticket gives the `clean` class the act. The three other classes keep exactly the answers
they have: `mechanical` catches up first, `content` refuses and waits on a person, and
`unanswerable` is the absence of a reading and is never actable.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — the act. The
  class gate (`case "$CLASS" in mechanical) ;; *) refuse "not_mechanical:${CLASS}" ;; esac`) and
  everything between it and the delivery block.
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` — the reader whose
  verdict is re-derived at the moment of the act. Read only; it does not change.
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` and
  `gate-decision.sh` — the gate that must still run before any merge attempt.
- `plugins/workaholic/skills/gather/scripts/merge-method.sh`, `gh-rest.sh`,
  `plugins/workaholic/skills/branching/scripts/merge-reason.sh` — the delivery seam, unchanged.
- `plugins/workaholic/skills/branching/SKILL.md` — the act's contract, if it states the class.

## Implementation Steps

1. **Reproduce the gap before changing anything.** Run
   `bash plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` and record
   which publications read `clean`. Run `settle-stranded-publication.sh <number>` against one of
   them and record the refusal verbatim — it must read `settle_refused` with
   `not_mechanical:clean`. That refusal is the failure this ticket removes; without it recorded,
   a later reader cannot tell a fix from a coincidence.
2. **Localize.** Confirm from the script that the class gate is the only thing between a `clean`
   publication and the delivery block, and that every step in between (worktree attach,
   `catchup-main.sh --resolve-mechanical`, regeneration, regeneration commit, push) exists to
   serve the catch-up. Write down which of them a `clean` publication needs. The gate scan is the
   one that is **not** part of the catch-up and must survive.
3. **Widen the class gate to accept `clean` beside `mechanical`**, keeping every other class
   refused by its own word: `content` stays `not_mechanical:content`, `unanswerable` stays
   `not_mechanical:unanswerable`, and an empty class stays `not_mechanical:unreadable`. Do not
   invent a new refusal word and do not rename an existing one — the report surfaces quote these.
4. **Take no catch-up for `clean`.** Skip `catchup-main.sh`, the regeneration, the regeneration
   commit and the push: the branch is already mergeable and none of those has anything to do.
   `merged`, `regenerated` and `pushed` therefore report `false` for a `clean` settlement, which
   is the truth and is what a reader needs in order to tell the two paths apart in the report.
5. **Keep the gate.** The release-safety scan must run before the merge attempt, on the same
   terms it runs today: `secret` refuses `scan_held:hard`, a `leak` block refuses
   `scan_held:confirm`, an unreadable gate refuses `scan_unreadable` and never reads as `pass`.
   Decide how the scan gets a checkout for a `clean` publication and say why in the code comment
   — see Considerations for the two shapes and the trade between them.
6. **Deliver through the same seam.** One `PUT repos/<slug>/pulls/<n>/merge` through
   `gh-rest.sh`, with the method read from `merge-method.sh` and never spelled here, and the
   refusal word taken from `merge-reason.sh`. No second merge engine, no loop, no retry.
7. **Prove the four terms of a bounded act still hold** for the new class, in the script's own
   header and in the behaviour: the verdict is re-derived here and now from the reader; a second
   run finds the pull request merged and refuses `not_a_stranded_publication`; the act writes no
   ref on the refusal paths; every bound refuses by its own word.
8. **Update the script header** so `clean` is named as an accepted class with what it skips, and
   so the sentence "`clean` needs no catch-up at all" no longer reads as a reason to refuse it.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `settle-stranded-publication.sh` against a `clean` publication reports `outcome: settled` with
  `merged: false`, `regenerated: false`, `pushed: false`, and a `delivery` in the merge
  vocabulary (`merged` or `merge_refused: <word>`).
- `content`, `unanswerable` and an unreadable class are still refused `not_mechanical:<class>`;
  `mechanical` behaves byte-for-byte as it does today.
- A gate finding still refuses `scan_held:hard` / `scan_held:confirm`, and an unreadable gate
  still refuses `scan_unreadable`, on the `clean` path as on the `mechanical` one.
- A re-run over a delivered publication refuses by name and touches no ref.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `sh scripts/e2e/loop-drill.sh verify-stranded-publication`
- The step-1 reproduction re-run: the same publication that refused `not_mechanical:clean` now
  settles, with its refusal and its settlement both quoted in the ticket's outcome.

**Gate** — what must pass before approval:

- No gate is overridden and no refusal word is renamed or dropped.
- `reference/claims.md` gains no row and no claim verdict word is emitted: a publication is
  not a claim.

## Considerations

- **Where the gate scan gets its checkout is the one open shape.** Two candidates, and the
  driving session picks one and says why in the code: (a) attach the worktree exactly as the
  `mechanical` path does and skip only the merge/regeneration/push, so the scan runs unchanged
  at the cost of one worktree; (b) run the scan without a worktree against the remote refs.
  (a) is the smaller change and reuses the existing teardown; (b) is cheaper per act. Either is
  acceptable provided the scan actually runs and its refusals are unchanged.
- **A local `clean` and GitHub's own state can disagree.** `claim-mergeability.sh` reads
  `git merge-tree` against a local `origin/<base>` ref, so a stale ref can read `clean` where
  GitHub answers 405 or 409. That is already handled by the contract and must stay handled by it:
  the delivery reports `merge_refused: <word>` and the act does not loop, retry or escalate.
  Observed while proposing: #688 and #625 read `clean` locally and `dirty` at the API.
- **The reporter proposed two repairs and this is the first of them** — the other was widening
  `/moderate`'s `stranded-publication` question past `content`. It is not taken: the `content`
  question exists because only a person can judge a collision, while a `clean` publication needs
  no judgement at all, and `moderate/reference/workflow.md` already records that the repairable
  half "is not a finding at all". Asking a person to press merge on five green pull requests is
  the noise this repository has twice retired status roots for. Recorded here as the rejected
  alternative rather than left implicit.

## Final Report

Development completed as planned.

The gap was reproduced before anything changed: `settle-stranded-publication.sh 813` against a
publication `list-stranded-publications.sh` classified `clean` returned
`{"outcome": "settle_refused", "reason": "not_mechanical:clean", "delivery": "not_attempted"}`.
After the change the same publication returned
`{"outcome": "settled", "class": "clean", "merged": false, "regenerated": false,
"validated": false, "pushed": false, "delivery": "merge_refused: merge_not_allowed"}` — settled,
no catch-up taken, no ref written, and the delivery reported in the merge vocabulary.

The class gate now sets one variable (`NEEDS_CATCHUP`) and nothing else: `clean` skips the merge,
the regeneration, the regeneration commit, the fast checks and the push, because each of them has
nothing to do on a branch that collides with nothing and is pushed nowhere. `content`,
`unanswerable` and an unreadable class keep `not_mechanical:<class>` verbatim, and `mechanical`
runs the identical code path it ran before.

Where the gate scan gets its checkout: candidate (a) — the worktree is attached for both classes.
The scan is not part of the catch-up, and `scan-branch-safety.sh` diffs a checkout of the branch
against the base, so it needs one. Scanning against the remote refs without a worktree would be
cheaper per act but would give the gate a second invocation shape; one worktree, attached and torn
down by machinery that already exists, keeps the gate's refusals byte-identical on both paths.

`validated` reports `false` on the `clean` path. The fast checks are stated in their own comment
as the guard on the push, and a `clean` settlement pushes nothing: the branch is byte-identical to
the one its own CI already ran on, so re-running the suite would assert nothing new.

### Discovered Insights

- **Insight**: The suite's idempotency row for this act was resting on the class gate rather than
  on the pull request's state. After a `mechanical` settlement the branch contains the base, so
  the reader reclassifies it `clean` — which used to refuse, and now does not. The row was
  asserting `not_mechanical:` where the real guard is that a merged pull request is no longer
  open and the reader never names it.
  **Context**: The fixture's `gh` stub kept the merged pull request in its open list, which GitHub
  never does. The row now re-issues the stub without it — modelling the merge — and asserts
  `not_a_stranded_publication` with the branch tip unmoved. Any future widening of the accepted
  classes is now checked against the guard that actually holds in production.
- **Insight**: A local `clean` and GitHub's own `mergeable` can disagree, and the disagreement is
  not rare here. `#813` read `clean` from `git merge-tree` against a freshly fetched `origin/main`
  while the API answered `mergeable: false, mergeable_state: "dirty"`, so the delivery came back
  `merge_refused: merge_not_allowed`.
  **Context**: The ticket anticipated exactly this and the contract held — one attempt, the
  refusal reported in the merge vocabulary, no loop and no escalation. It does mean the act can
  settle a publication the remote still declines, which is a fact about GitHub's cached
  mergeability rather than about this script.
