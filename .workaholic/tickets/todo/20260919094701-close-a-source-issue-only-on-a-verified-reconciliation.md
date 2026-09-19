---
created_at: 2026-09-19T09:47:01+09:00
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
