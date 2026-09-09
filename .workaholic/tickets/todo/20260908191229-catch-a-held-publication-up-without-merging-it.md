---
created_at: 2026-09-08T19:12:29+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-loop-grow-a-mission-without-handing-it-back-to-a-person
merge_policy:
verification_handoff: 
---

# Catch a held publication up without merging it

## Overview

A publication held for the operator has no catch-up path, so the base moving under it is pure
loss: the conflict deepens each hour and the work can lose its home entirely — measured
2026-09-08, where a held publication's target mission was archived while it waited and the
publication was closed as a duplicate. The repair is the split `catch-up-claim.sh` already makes:
being caught up and being delivered are different outcomes. This act catches such a publication
up to the base and pushes it, and stops there — the merge stays the operator's ruling.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — the existing
  act. It catches up *and* merges in one call, which is why it cannot be reused whole here.
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — the precedent: `outcome` and
  `delivery` are separate fields, and `delivery: not_attempted: <reason>` is the honest word for
  a branch made current whose merge belongs to someone else.
- `plugins/workaholic/skills/ship/scripts/catchup-main.sh` — the one merge engine
  (`--resolve-mechanical`); never a second one.
- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` — `--branch` attaches
  a worktree to an already-published branch; the scan needs a checkout.
- `plugins/workaholic/skills/release-scan/` and `drive/scripts/gate-decision.sh` — the scan runs
  before any push, read through the severity tier.
- `plugins/workaholic/skills/branching/scripts/lib/publication-refusal.sh` — the word the act
  re-derives at the moment of the act.

## Implementation Steps

1. **Reproduce.** Take a held publication from the previous ticket's reader whose class is
   `mechanical` or `content`, and record that no script in the repository will move it.
2. **Take the candidate from that reader**, never from a second walk, and re-derive the refusal
   word at the moment of the act: a publication that is no longer the operator's is not this
   act's business.
3. **Attach, catch up, regenerate, check, push.** `create-mission-worktree.sh --branch`, then
   `catchup-main.sh --resolve-mechanical`, regenerate with the repository's own tooling, run the
   fast checks, run the release scan through `gate-decision.sh`, and push.
4. **Stop there, and say so in its own field.** Report `delivery: not_attempted: operator_facing`
   beside the catch-up outcome — never collapsed into one word, because a publication can be
   genuinely current while its merge belongs to a person.
5. **Refuse by name, with nothing pushed**: `not_operator_facing:<word>`, `content_conflict`,
   `pull_request_reviewed` (a push resets an approval), `scan_held:<tier>`,
   `validation_failed:<check>`, `push_failed`, `has_claim_commit`, `not_a_work_branch`,
   `mergeability_unanswerable:<reason>`.
6. **Be idempotent and reversible**: `already_current` touches no ref, leaves no worktree behind,
   and a re-run reports the same word.
7. **Wire it to the tick that already runs** — no timer, no queue, no cursor — and report what it
   touched in that tick's report.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A held publication with a resolvable class is pushed current and **not** merged.
- The report carries the catch-up outcome and `delivery: not_attempted: operator_facing`
  separately.
- Every refusal is by its own word, with nothing pushed and no worktree left behind.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- No merge call site anywhere in the act, and no second merge engine.

## Considerations

- Pushing to a branch a person has reviewed resets their approval; carry
  `catch-up-claim.sh`'s three-valued `pull_request_reviewed` refusal rather than inventing one.
- Whether this is a flag on `settle-stranded-publication.sh` or a sibling act is an
  implementation choice; what must not happen is one act whose merge is conditional on a word,
  because that is how a held publication gets merged by accident.

## Final Report

**The base landed this while the branch was driving it.** This run re-derived every acceptance
criterion and the Gate against the merged tree rather than re-implementing them; its own parallel
act is stashed on the claim worktree, not merged.

The base took the ticket's Considerations seriously and answered them in the shape the ticket
preferred: **preparation and delivery are two files, not one act with a conditional merge.**
`prepare-publication.sh` holds everything up to and including the push and contains **no merge
call site at all**; `settle-stranded-publication.sh` is a 51-line wrapper that runs the
preparation and only then delivers. `catch-up-operator-publication.sh` is a five-line entry point
that execs the preparation with `--catchup-only`, which swaps the reader to
`list-operator-facing-pulls.sh` and pins `delivery` to `not_attempted: operator_facing` before
anything else runs. There is no word a degraded read could flip to turn a catch-up into a merge,
because the merge is in a different file.

Criterion by criterion:

- **A held publication with a resolvable class is pushed current and not merged.** The operator
  arm re-proves ownership (`gh api user` against the row's author) and an empty review list, then
  catches up through `catchup-main.sh --resolve-mechanical` — never a second merge engine —
  regenerates, validates and pushes. It also forces `NEEDS_CATCHUP=true` in operator mode, because
  a conflict-free merge is not proof the base is already included: a clean-but-behind publication
  must still be brought forward.
- **The report carries the catch-up outcome and `delivery: not_attempted: operator_facing`
  separately.** They are two fields and the delivery one is set before the first refusal can fire,
  so every path reports it.
- **Every refusal is by its own word, with nothing pushed and no worktree left behind.**
  `publication_not_owned`, `reviewed_or_reviews_unreadable`, `not_a_work_branch`,
  `has_claim_commit`, `content_conflict`, `scan_held:<tier>`, `validation_failed:<check>`,
  `push_failed`, and the teardown only keeps a worktree that holds an unpushed merge.
- **Gate — no merge call site anywhere in the act, and no second merge engine.** Both hold, and
  the base pins the first from the outside rather than by reading its own source: the suite's
  stub records every provider call and asserts the operator act made none containing `/merge`.

### Discovered Insights

- **Insight**: The reviews check runs **twice** — once before any work and once immediately
  before the push — because validation can take minutes and a branch can gain a review inside
  that window. A single up-front check would push over an approval that arrived while the suite
  was running.
  **Context**: This is the one bound where re-deriving at the moment of the act is not enough:
  the act itself is long, so the proof has to be re-taken at its end as well as at its start.
- **Insight**: Reading the ticket's `verification_handoff:` axis correctly here mattered more
  than it looks — all three of this mission's tickets declared nothing, so the unit took its
  ordinary route even though its work turned out to be already done. Nothing in the claim
  protocol could see that: `superseded` is derived from **archived tickets**, and these were
  never archived, so the survey went on offering the unit as `heartbeat_lapsed`.
  **Context**: The gap is real but the fix is not a *has this already been done* test — that is
  a reading about behaviour, which `CLAUDE.md`'s planning section refuses by name.
