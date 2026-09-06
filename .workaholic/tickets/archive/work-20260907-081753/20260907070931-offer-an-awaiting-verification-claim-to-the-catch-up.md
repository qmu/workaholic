---
created_at: 2026-09-07T07:09:31+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260907070904-keep-a-handoff-branch-mergeable-while-it-waits-for-the-person.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260907-081753
---

# Offer an awaiting_verification claim to the catch-up

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from a
     proposal into queued work. -->

`list-catchable-claims.sh` offers only claims whose verdict is `report_undelivered` or
`queue_drained`. An `awaiting_verification` claim is excluded — so the one class of branch
that is **guaranteed** to sit open for a long time, by the handoff route's own design, is
the one class the catch-up never touches. The handoff route says the pull request opens and
stays open; it does not say the work on it should decay while it waits.

Measured on this repository: mission `report-each-tick-in-the-originating-codex-chat`, claim
`work-20260906-023953`, PR **#993**, open ~25 hours, acceptance 2/3, **six of seven tickets
already driven and archived** on that branch, the seventh holding a genuine prose
`verification_handoff:` for a live run in the operator's own Codex chat. The branch reads
`mergeability: content` against a `main` that has taken many merges since 2026-09-06T04:13+09:00.

The ask is **the catch-up only, never the delivery**.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements* and *When a
  bounded act may read a judgement*: the catch-up is the one enumerated consumer that may read a
  judgement, on four bounds it must keep (re-derive at the moment of the act, idempotent,
  reversible, refuse every bound by its own word). This widening must not touch any of them.

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` — the candidate reader.
  Its `jq` select at the `units=` assignment is the whole filter, and its header carries three
  pieces of reasoning this change must answer rather than delete: *why `clean` is deliberately
  not a candidate*, *the open-pull-request term is read off the row and costs no lookup*, and
  the live-row rule.
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — the act. Read it before
  changing anything: its **only** verdict gate is the delivery bound
  `[ "$VERDICT" = "queue_drained" ] || report caught_up ""`, near the end. There is no
  entry-side verdict gate to widen.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — where `awaiting_verification` is
  derived; read only, to confirm the verdict's own preconditions.
- `CLAUDE.md` (*Claim protocol* → *Catch-up*) and
  `plugins/workaholic/skills/drive/reference/claims.md` — both state which verdicts the
  catch-up offers, in one sentence each; both must move in this commit.
- `scripts/test-workflow-scripts.mjs` — the suite; add or extend the row that pins the
  candidate set.

## Implementation Steps

**This is a failure report, so it opens with measurement rather than with the proposed fix**
(`workaholic:discover`, *Diagnosis-First Rule*).

1. **Reproduce and localize on the live claim.** Run
   `bash plugins/workaholic/skills/drive/scripts/list-claims.sh` and confirm, for
   `work-20260906-023953`: the verdict is `awaiting_verification`, `mergeability` is
   `mechanical` or `content`, and the claim's author is this identity. Then run
   `bash plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` and confirm the
   unit is **absent** from `candidates`. If the live state has moved on since this ticket was
   written, say so and measure whatever `awaiting_verification` claim exists instead; if none
   exists, construct the state in a throwaway repository rather than changing the filter on
   the ticket's word alone.

2. **Establish that the act does not need widening, before touching it.** Read
   `catch-up-claim.sh` and confirm what this proposal's discovery found: the script has no
   entry-side verdict gate, and `VERDICT` is consulted exactly once, at the delivery bound.
   An `awaiting_verification` unit handed to it therefore already catches up, pushes, and
   falls through to `report caught_up ""` with the module-level `DELIVERY="not_attempted"`.
   Record what you found; if it disagrees with this paragraph, the design below is wrong and
   the measurement wins.

3. **Establish that the reader's own stated reasoning survives the widening.** The header
   argues that both admitted verdicts already *mean* "at an open pull request", which is why
   no REST call is needed per candidate. Confirm in `lib/claims.sh` that
   `awaiting_verification` is only reachable under `_cs_reported = true` — i.e. the unit
   reported and opened a pull request — so the third verdict carries the same term. **If it
   does not, stop and report**: adding a candidate that needs a lookup would turn a pure
   offline read into one needing a credential, which the header refuses by name.

4. **Widen the candidate set**, and only that: admit `awaiting_verification` beside
   `report_undelivered` and `queue_drained`, in **both** places the reader names a verdict —
   the `jq` select and the `case "$verdict"` re-check on the resolved live row. `clean` and
   `unanswerable` stay excluded for their own recorded reasons.

5. **Name the delivery reason** so the report says why the merge was not attempted rather
   than leaving a bare word: an `awaiting_verification` unit reports
   `delivery: not_attempted: awaiting_verification`. Keep the bound itself exactly where it
   is — the merge half stays `queue_drained`-only.

6. **Update the header comments** of both scripts in the same edit, in their own voice: the
   reader's *why this verdict joined* paragraph (with the measurement from step 1) and the
   act's delivery-bound paragraph (which now has three admitted verdicts and one delivering).

7. **Update the documentation in the same change** — `CLAUDE.md`'s *Catch-up* bullet and
   `drive/reference/claims.md` — each of which states the offered verdict set in a sentence.

8. **Pin it in `scripts/test-workflow-scripts.mjs`**: a hermetic row asserting that an
   `awaiting_verification` row with `mergeability: content` is offered, and — the half that
   matters more — that the delivery stays unattempted for it. A test that only proves the
   widening would let a later change merge a handoff pull request and stay green.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `list-catchable-claims.sh` offers this identity's own `awaiting_verification` claim whose
  `mergeability` is `mechanical` or `content`, carrying the class through verbatim.
- `clean` and `unanswerable` are still not offered; the live-row resolution is untouched; the
  reader still makes no network call of its own and still answers `count: null` with its
  reason on every degraded path.
- `catch-up-claim.sh`'s delivery half is still reached only by `queue_drained`, and an
  `awaiting_verification` unit reports `delivery: not_attempted: awaiting_verification`.
- Every existing refusal is unchanged and still writes nothing: `content_conflict`,
  `scan_held:<tier>`, `pull_request_reviewed`, `reviews_unreadable:<reason>`, `not_my_claim`,
  `foreign_identity`, `identity_unresolved`, `claim_active`, `dirty_worktree`,
  `not_a_work_branch`, `ambiguous_claim`, `mergeability_unanswerable:<reason>`,
  `catchup_<class>`, `validation_failed:<check>`, `push_failed`.
- No claim is cleared, released, resumed or retired; no handoff declaration is weakened,
  re-derived or read; no handoff pull request is merged.
- `CLAUDE.md` and `drive/reference/claims.md` name the widened set in this commit.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` now names the unit
  measured in step 1 (or the equivalent constructed state).
- `node scripts/test-workflow-scripts.mjs` — green, including the new row from step 8.
- `sh plugins/workaholic/hooks/posix-lint.sh` — green (both files are `*.sh`).
- `sh scripts/e2e/loop-drill.sh verify-all` — the classified drill set stays green.

**Gate** — what must pass before approval:

- All four commands above are green, and the run report states which verdict earned the
  candidate and that the delivery was not attempted.

## Considerations

- **The reporter's proposed shape is recorded here as the hypothesis it is**, per the
  diagnosis-first rule — steps 1-3 exist to test it before step 4 adopts it. This proposal's
  own discovery pass read both scripts and found it **supported on all three terms**: the
  filter is exactly the two `jq`/`case` verdict lists; `catch-up-claim.sh` has no entry-side
  verdict gate, so the act needs no widening at all; and `awaiting_verification` is reachable
  only under `_cs_reported = true`, so the "already at an open pull request" term the header
  relies on holds for the third verdict as it does for the other two. That is evidence, not a
  licence to skip the measurement: it was read on 2026-09-07 and the tree moves hourly.
- **The delivery bound is the load-bearing half of this ticket, and the widening will make it
  easy to lose.** Its reason is stated in `catch-up-claim.sh`'s own header for
  `report_undelivered` (one act owns one delivery) and is a *different* reason for
  `awaiting_verification` (a person is the next actor by construction). Write the second
  reason down; a reader who finds only the first will conclude the bound is about avoiding a
  double attempt and widen it.
- **`claimable-units.sh` composes this reader**, so widening it also raises the `catchable`
  term in the loop tick's claimable count — which is the intended effect and worth naming:
  under *claimable means work an `/implement` pass would act on*, a handoff branch needing
  catch-up **is** such work. Confirm the count moves and that the tick's §3 line names
  `catchable` as the term that earned the runner; do not add a bound to compensate.
- **`pull_request_reviewed` matters more for this class than for the other two.** A handoff
  pull request is open precisely so a person can look at it, so it is the class most likely
  to carry a submitted review — and a push resets an approval. The bound already exists and
  is three-valued; leave it exactly as it is and expect it to fire.
- **Nothing here touches `/moderate`'s `handoff-units` step**, which reads the same verdict for
  a different purpose (asking the claim holder, re-running the probe). Two readers of one
  verdict, two questions; do not merge them.
- **A `content` class is a prediction, not a verdict.** The reader computes with the
  repository's `.gitattributes` out of reach and is pessimistic by construction; the writer
  merges in a real checkout. So a `content` handoff branch may well catch up cleanly, and a
  hunk the merge itself cannot settle still refuses `content_conflict` with nothing pushed.
  That asymmetry is already recorded in `drive/reference/claims.md` and is not re-litigated here.
