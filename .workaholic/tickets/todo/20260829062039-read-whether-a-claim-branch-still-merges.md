---
created_at: 2026-08-29T06:20:39+00:00
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
