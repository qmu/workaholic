---
created_at: 2026-09-19T10:01:42+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: hold-the-completion-mention-until-the-whole-human-request-set-is-in
merge_policy:
verification_handoff:
---

# Fold the accepted request set at the thread grain

## Overview

Operator's ask: **issue #1146** — *reconcile every accepted request with implementation,
appropriate verification and any required delivery evidence … if any accepted request remains
queued, active, blocked or unverifiable, withhold the completion mention.* Measured: a mention
went out when one assistant-UI unit merged while sorting, pagination, forms and identifiers from
the same continuing thread were still queued.

**Most of the reconciliation exists, and the gap is the grain.** `work/scripts/feedback-outcome.sh`
answers one state per **feedback item** and holds the notification for anything short of
`implemented_and_verified`. `work/scripts/delivery-ledger.sh` already folds an item's **pull
requests** with `every`, so *one merged part and two open ones* can no longer read as finished —
its own header says exactly that. Both fold **within one item**. Nothing folds **across the items
of one human thread**, which is the unit the person means by *done*.

**The thread key already exists and needs no new relation.** Every captured ask carries its source
coordinate: `propose/scripts/file-inbound-ask.sh` stamps the `slack-ref:` marker and the
permalink, and `propose/scripts/list-unannounced-closed-asks.sh` returns `slack_ref` on every
candidate row. `drive/scripts/unit-feedback-stems.sh` already resolves a unit's stems for the
thread lookup. So the fold is over rows these readers already produce.

**The bound that must be written with it.** `#1132` records that thread discovery can be
incomplete, and this repository's own rule is that an absence of a reading is never a proof — so a
set that could not be read whole **withholds** the mention rather than completing it. That
direction is not symmetric and must be stated: incomplete discovery is never evidence of
completeness.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/observability.md` — a withheld mention names which member
  held it; a held completion that says nothing is the same silence being repaired
- `workaholic:implementation` / `policies/test.md` — the fold, its `every` semantics and its
  unreadable path are pinned hermetically

## Key Files

- `plugins/workaholic/skills/work/scripts/delivery-ledger.sh` (header lines ~30-48, and the fold) —
  the model: it already folds with `every` and already refuses to turn an unreadable list into an
  empty one. Read it whole before writing a second fold.
- `plugins/workaholic/skills/work/scripts/feedback-outcome.sh` — the one derivation of an item's
  state. It must stay the only one; this ticket adds a fold **over** it, never a second reading.
- `plugins/workaholic/skills/propose/scripts/list-unannounced-closed-asks.sh` — supplies
  `slack_ref`, `stem`, `number` and the landed pull requests per item; the grouping key comes from
  here.
- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` — where `slack-ref:` is stamped,
  so the key's shape is fixed and documented.
- `plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` — the existing stem resolution.
- `plugins/workaholic/commands/infinite-development.md` (*Announce landed asks*) — the consumer;
  the fold's verdict decides whether a completion mention may be composed at all.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Read both existing readers in full** and record what each folds over. The new reader must
   compose them, not re-derive an item's state.
2. **Define the accepted set**, in the script's own header: the requests captured from one human
   thread and its explicitly linked continuations, each with its own feedback item. Say what is
   **not** in it — an ask on another thread, an ask a person explicitly deferred or cancelled — so
   the boundary is arguable rather than implied.
3. **Write the fold** as one script taking the per-item states the existing reader produced and
   answering, per thread: `complete` only when **every** member reads `implemented_and_verified`,
   otherwise `incomplete` naming each member and the state that held it.
4. **Unreadable withholds, always.** A set whose membership could not be established, or any member
   whose state is unreadable, answers its own word with **null** counts and never `complete`. State
   the asymmetry in the header and cite `#1132`: incomplete discovery is not evidence of
   completeness.
5. **Group by the key that already exists** — the thread coordinate on each captured ask — and
   never by similarity, recency or title. The repository's standing prohibition on fuzzy matching
   in a notification path applies here in full.
6. **An item with no thread key is its own answer**, not a silent drop:
   `list-unannounced-closed-asks.sh` already reports `stems_unresolvable` for the mirror case, and
   this reader names its equivalent rather than folding such an item into some other thread.
7. **Wire the verdict at one seam**: *Announce landed asks* composes a completion mention only on
   `complete`; every other verdict takes the scoped-progress path that this mission's third ticket
   defines. Do not add a second call site.
8. **Hermetic rows**: a thread whose members are all verified folds `complete`; one member queued
   folds `incomplete` naming that member; an unreadable member withholds; an item with no thread
   key is named, not folded; and `feedback-outcome.sh` is byte-identical.
9. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The fold is at the thread grain, keyed on the source coordinate already stamped on each captured
  ask; no new relation and no new field on any artifact.
- `complete` requires **every** member verified; one member short answers `incomplete` and names it.
- An unreadable membership or member answers its own word with null counts and never `complete`.
- `feedback-outcome.sh` remains the only derivation of an item's state and is byte-identical.
- No similarity, recency or title matching anywhere in the grouping.
- Exactly one seam consumes the verdict.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and each new row fails when reverted.
- `git diff origin/main -- plugins/workaholic/skills/work/scripts/feedback-outcome.sh` is empty.
- A fixture thread with one queued member produces `incomplete` naming that member and no
  completion mention.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The header states what is in the accepted set and what is not.
- The unreadable asymmetry is stated and cited, not implied.
- The suite is green, the bundle rebuild is diff-clean; POSIX `sh` throughout.

## Considerations

- **The failure mode this introduces is a mention that never goes out** — one stale member holds a
  thread forever. That is the ask's stated preference (*withhold*), and the repair is the scoped
  progress message, which is why the third ticket is part of the same mission rather than later.
- **Only an explicit human defer or cancel narrows the set.** A worker's judgement that a request
  is obsolete does not; that rule is stated in the third ticket and cited here, never restated.
- **Do not let the fold reach into another repository's thread.** The key is a coordinate, and a
  coordinate from elsewhere is not this repository's set.
