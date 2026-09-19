---
created_at: 2026-09-19T09:47:01+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-a-feedback-item-only-on-evidence-from-the-surface-the-person-reviews
merge_policy:
verification_handoff:
---

# Close a source issue only on a verified reconciliation

## Overview

Operator's ask: **issue #1104**, items 3-5 — *reconcile every source feedback item as `implemented
and verified`, `still queued`, or `not implemented` with a concrete reason; generate final
summaries from that reconciliation; reject closure when only the wrong sibling surface changed.*

**Most of the reading already exists, and this ticket is about where its verdict is spent.**
`work/scripts/feedback-outcome.sh` already answers exactly those states per item —
`still_queued`, `not_implemented`, `not_verified`, `surface_unresolved`, `surface_mismatch`,
`implemented_and_verified` — and already holds the notification (`notification: "held"`) for
anything short of the last. What no seam does is **act on that verdict with the issue**: the
issue's closure is decided at ingest by a `Closes #<N>` keyword (removed by this mission's
previous ticket) and by nothing else afterwards. So after that removal the issue is closed by
nobody, and this ticket supplies the one act that may close it.

**The verdict is a reading over inputs, so what may be *acted on* is bounded.**
`drive/reference/claims.md` states the rule this ticket inherits: an act may proceed on a
judgement only when it re-derives it at the moment of the act, is idempotent, is reversible, and
refuses every bound by its own word. Closing a GitHub issue is idempotent and reversible (a person
reopens it), so the act is admissible — provided the reading is re-derived immediately before it
and every non-`implemented_and_verified` state refuses by its own name.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/observability.md` — an item that did not close names the
  state that held it; a silent non-closure is the same invisibility this mission is repairing
- `workaholic:implementation` / `policies/test.md` — every refusal is pinned hermetically, offline

## Key Files

- `plugins/workaholic/skills/work/scripts/feedback-outcome.sh` — the one reader of the verdict.
  It must stay the only derivation; this ticket adds an actor, never a second reading.
- `plugins/workaholic/skills/work/scripts/delivery-ledger.sh` — the same verdict folded over
  several pull requests; an item answered by more than one must reconcile through this reader.
- `plugins/workaholic/skills/propose/scripts/list-unannounced-closed-asks.sh` — today's
  after-the-fact announcer of closed asks. Read its header in full: it assumes the issue closes on
  its own, and that assumption is what this mission changes.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport. A close is a
  REST `PATCH`; `gh issue close` is GraphQL-backed and forbidden (`rules/shell.md`).
- `plugins/workaholic/commands/infinite-development.md` (*Announce landed asks*) — where the
  per-item facts are already passed through the reader before a finish line is composed; the close
  belongs at that same seam or is explicitly placed elsewhere with a reason.
- `plugins/workaholic/skills/branching/scripts/lib/base-ref-gate.sh` — every unattended write
  reads it; a REST issue close is not a git write, and the story should say so explicitly.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Re-read the two readers in full before writing the act**, including `delivery-ledger.sh`'s
   fold, so the act consumes one verdict rather than re-deriving a second.
2. **Write the act as its own script** — one item, one close, reported by name. It re-derives the
   verdict immediately before the call, closes only on `implemented_and_verified`, and refuses
   every other state **by that state's own word**: `still_queued`, `not_implemented`,
   `not_verified`, `surface_unresolved`, `surface_mismatch`, `unreadable`.
3. **Refuse on an unreadable reading**, never close. An absence of a reading is never a proof —
   the rule this repository applies to `unanswerable` everywhere else.
4. **Close over REST only**, through `gather/scripts/gh-rest.sh`. Report the outcome from the
   response, not from the exit status; an already-closed issue is a success word of its own
   (`already_closed`), not a failure.
5. **Compose the summary from the reconciliation, not from a title** (the ask's item 4). The
   channel finish line names each item's state; an item that did not close appears with its state
   word. A pull-request title or a merged proposal is never evidence that an item landed.
6. **The sibling-surface case needs no new rule** (the ask's item 5): it is `surface_mismatch`
   once the previous ticket persists the expected surface, and the act refuses on it. State that
   in the script header so a later reader does not add a second, drifting test for it.
7. **Wire it at one seam only**, and name which. `/implement`'s per-unit route and the tick's
   *Announce landed asks* step both see finished work; pick one, state why, and do not let both
   close.
8. **Hermetic rows** with a stubbed transport: each non-verified state refuses with its own word
   and issues no request; `implemented_and_verified` issues exactly one close; a second run over
   the same item answers `already_closed` and issues no second close; an unreadable reading
   refuses; and the composed summary names every item's state.
9. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An issue is closed **only** when a reconciliation re-derived at the moment of the act reads
  `implemented_and_verified`.
- Every other state refuses by its **own** word, writes nothing and issues no request.
- An unreadable reading refuses and is reported as unreadable, never as not-implemented.
- The close goes through `gh-rest.sh`; no `gh issue` subcommand appears anywhere in the change.
- A repeat run is idempotent: `already_closed`, with no second request.
- The channel summary names each item's state and never infers completion from a title or a merge.
- `feedback-outcome.sh` remains the only derivation of the verdict; no second reading is added.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and each refusal row fails when reverted.
- `node scripts/test-workflow-scripts.mjs`'s existing `gh issue|pr|repo` walk stays green (its
  allowlist is empty on purpose).
- The stubbed-transport fixture records exactly one request for the verified case and zero for
  every refusal.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The seam that closes is named in exactly one place and no second seam can close.
- The act's four bounds — re-derived, idempotent, reversible, refuses by its own word — are stated
  in the script header, citing `drive/reference/claims.md` rather than restating it.
- The suite is green and the bundle rebuild is diff-clean.

## Considerations

- **Depends on this mission's other two tickets.** Without the persisted surface, `surface_mismatch`
  compares an asserted value; without the ingest-close removal, the issue is already closed before
  this act can run. Drive them in the mission's order.
- **A person reopening a closed issue must not be fought.** The act closes once and never re-closes
  an issue a person reopened; that reading is future work and not smuggled in here.
- **Do not let this become an issue-management routine.** It closes an item on a proof and does
  nothing else — no labels, no comments beyond the finish line the tick already composes, no
  reassignment.

## Final Report

Development completed as planned. Both readers were read in full before the act was written
(step 1), and the act consumes one verdict rather than deriving a second.

**The act.** `plugins/workaholic/skills/work/scripts/close-source-issue.sh` — one item, one
close, `{issue, item}` in and `{outcome, state, reason, requested}` out. It hands the caller's
facts to `feedback-outcome.sh` **in the same invocation as the close**, closes only on
`implemented_and_verified`, and refuses every other state by that state's own word with no
request of any kind. `requested` is on the output precisely so *it did nothing* is provable
rather than asserted, and the hermetic rows assert on it.

**The four bounds are cited, not restated**, in the script's own header
(`drive/reference/claims.md`, *When a bounded act may read a judgement*): re-derived at the
moment of the act, idempotent (`already_closed`, no second request), reversible (a person
reopens an issue), and refusing every bound by its own word. The header also states, rather than
leaving to be re-asked, that the **base-ref gate does not apply** — it governs commits and
pushes, and this act writes no ref, no file and no commit.

**An unreadable reading refuses** (step 3) and is reported `unreadable` with its own reason —
`reader_unreadable` when the reader produced no state, `issue_unreadable` when the issue's
current state could not be read, `close_unconfirmed` when the PATCH's response did not confirm.
None of the three is `not_implemented`; an absence of a reading is never a verdict about the
work.

**REST only** (step 4). `PATCH repos/<slug>/issues/<N>` through `gather/scripts/gh-rest.sh`,
with the outcome read from the **response** rather than the exit status. No `gh issue`
subcommand appears in the change, and the suite's existing `gh issue|pr|repo` walk stays green.

**The sibling-surface case got no new rule** (step 6), and the script's header says so: it is
`surface_mismatch` now that the mission's first ticket persists the expected surface, and the
act refuses on it like any other state. A second test for one question is how two tests drift.

**The seam, chosen and named** (step 7): **`/implement`'s per-item reconciliation**
(`commands/implement.md`). Two candidates were weighed. That command already reconciles at the
**item** grain — the grain the verdict is keyed on — and it runs at the moment the work is
finished, which is what the verdict is about. The tick's *Announce landed asks* step was
rejected because its candidate reader, `list-unannounced-closed-asks.sh`, lists issues that are
**already closed**: it sees an item only after something else ended it, so it could never be the
thing that ends one, and giving it the act would make two seams race over an act that needs no
race. `infinite-development.md` and that reader's own header now say so explicitly, so the next
reader does not re-open the question.

**The stated gap.** An ask whose work lands through a session that never runs `/implement`
reaches no closer. That gap is not new — it is the same one `list-unannounced-closed-asks.sh`
exists to report for the *announcement* — and it is left rather than filled, because filling it
means a sweep that hunts for work to declare finished, which is the issue-management routine
this ticket's Considerations forbid. A person closes such an issue by hand exactly as before.

### Discovered Insights

- **Insight**: `list-unannounced-closed-asks.sh` is built on the premise that *when the work
  lands the issue closes*, and that premise was supplied entirely by the ingest `Closes #<N>`
  keyword this mission removed.
  **Context**: the reader's subject survives the change — it still answers *which closed asks
  nobody told their own thread about* — but what populates it moved from *a proposal merged* to
  *a verified reconciliation closed it, or a person did*. One visible consequence: an ask still
  being worked on no longer appears in its output at all, which is correct and was not true
  before. A reader whose candidate set is defined by another seam's side effect needs its
  premise written in its own header, or a later change to that seam silently redefines it.

- **Insight**: `gh-rest.sh slug` resolves the repository from the local git remote, not from the
  network, so a hermetic fixture needs `git remote add origin` and nothing more — the stubbed
  `gh` is never asked for the slug.
  **Context**: worth knowing when writing any fixture for a script that reaches GitHub; the stub
  only has to answer the calls the act itself makes, which keeps the stub small enough to read.
