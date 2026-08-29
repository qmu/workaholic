---
created_at: 2026-08-29T06:20:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# Read whether a claim branch still merges

## Overview

PROPOSED. One reader answering `clean | mechanical | content | unanswerable` per claim,
derived locally over refs the claim oracle already fetches — `lib/claims.sh` deepens a
shallow clone before anything reads ancestry, so the merge base is present and no network
call the protocol does not already make is added. Reported, never acted on by this ticket.

**The vocabulary already exists and must not be forked.** `ship/scripts/catchup-main.sh`
classifies `mechanical` vs `content` today, and `/drive`'s routing table already reads
those words. This reader answers in the same two words from a different mechanism —
`git merge-tree`, which does not touch a worktree — so the one real risk is a second
classifier that can disagree with the writer's. The reader must derive its classification
from the same rule the writer applies (version/lockstep manifests and `outputs/` are
mechanical; the append-only `.workaholic/` shape is resolved rather than classified;
anything else is content), extracted into one place both read.

`unanswerable` is its own value and never collapses into `content`, on the merged-lookup
precedent: a wrong `clean` pushes a broken merge, a wrong `content` only delays a unit.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the scan whose refs this
  reads; it fetches and unshallows already, so the reader is offline by construction after it.
- `plugins/workaholic/skills/ship/scripts/catchup-main.sh` — the existing classifier whose
  rule this must share rather than restate; read its header before touching anything.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — where the per-claim reading is
  rendered.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the reading's standing is stated.

## Implementation Steps

1. Read `catchup-main.sh`'s header in full and lift its path/shape rule into one place
   both it and the new reader consult — never a second copy of the rule.
2. Add the reader: `git merge-tree` the claim tip against the base tip, classify the
   result through that shared rule, answer `clean | mechanical | content | unanswerable`.
3. Render it per claim in `list-claims.sh` beside the existing verdict, and name the
   reason on `unanswerable` (no merge base, shallow history, unreadable ref).
4. Classify it in `drive/reference/claims.md` — **every one of the four is a judgement**,
   never a proof: a base that moves is exactly a reading that becomes false by looking
   again, which is the property a proof must not have.
5. Prove the two classifications agree over the ticket-1 fixture: for a branch the reader
   calls `mechanical`, a real `catchup-main.sh` run resolves it, and for one it calls
   `content`, `catchup-main.sh` refuses.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Four values, `unanswerable` never collapsing into `content`, each with its own reason.
- One classification rule, read by both the reader and `catchup-main.sh`; no second copy.
- The reader makes no network call the claim scan does not already make, and writes nothing.
- All four values are classified as judgements in `claims.md`, and the suite fails on a fifth
  word or on any row called a proof.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The ticket-1 fixture, extended to assert reader/writer agreement on both classes.

**Gate** — what must pass before approval:

- The reader and `catchup-main.sh` agree on every fixture branch, proved rather than asserted.

## Considerations

Whether `merge-tree` and a real merge can ever disagree on the append-only `.workaholic/`
shape is the thing to check: `catchup-main.sh` *resolves* those files rather than
classifying them, so the reader must apply the same shape test or it will call `content`
what the writer would have resolved. Getting that wrong makes the whole mission a no-op
on exactly the concurrent pairs it exists for.

## Final Report

Development completed as planned. `drive/scripts/claim-mergeability.sh` answers
`clean | mechanical | content | unanswerable` per branch from `git merge-tree --write-tree`,
which computes the merge into the object store and touches no worktree, index or ref.
`list-claims.sh` renders it per claim as `mergeability` / `mergeability_reason`, and
`drive/reference/claims.md` classifies all four as judgements.

**The classification rule was lifted into one place rather than restated**:
`ship/scripts/lib/conflict-class.sh`, sourced by both `catchup-main.sh` (the writer) and the
new reader. The reader carries no allowlist of its own, which the suite asserts.

The ticket's Considerations named the one thing to check, and checking it changed the rule.
The append-only shape test does **not** cover the OKF indexes and correctly refuses them:
`refresh-index.sh` emits a *sorted* list derived from the tree, so archiving a mission MOVES
a line from `## active` to `## archive` — nothing about that is an append. Measured live on
this repository the same day: all seven claim branches read `content`, and on the four that
were otherwise mechanical the only content paths were `.workaholic/missions/index.md` and
`.workaholic/stories/index.md`. A rule that stopped at the append-only test would have left
the mission a no-op on exactly the concurrent pairs it exists for — the ticket's own warning,
realised. So the shared rule gained two more members, each with its own justification: three
**wholly generated** index paths (a copy of `refresh-index.sh`'s own unconditional writes),
and a **proof** for a flat area's half-generated index — it is only mechanical when neither
side changed anything outside the `okf:generated` markers, so nothing a person wrote can be
lost. After that the same four branches read `mechanical`, `clean`, `content`, `content`.

Reader/writer agreement is **proved rather than asserted**, twice: hermetically, by running
the real `catchup-main.sh` in each fixture branch's own worktree and comparing; and live, on
the real stranded branch `work-20260826-134108`, where the reader said `mechanical` and the
writer resolved all six conflicts.

### Discovered Insights

- **Insight**: `.workaholic/*/index.md` is generated, not appended — and it is the file that
  conflicts on essentially every concurrent pair of units in this repository.
  **Context**: The append-only resolution was written for `## Changelog` tails and reads as
  though it covers the whole `.workaholic/` log. It does not cover the OKF indexes at all, and
  those are what actually collide, because every landed unit rewrites the same sorted list.
- **Insight**: `git merge-tree --write-tree` (git ≥ 2.38) reports each conflicted path's three
  stage object ids, so a predictive classifier can read the same three blobs the writer reads
  without checking anything out.
  **Context**: That is what makes one shared rule possible rather than two approximations.
