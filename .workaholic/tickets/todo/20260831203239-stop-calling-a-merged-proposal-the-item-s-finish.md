---
created_at: 2026-08-31T20:32:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260831203218-thread-reconcile-calls-a-merged-proposal-the-item-s-finish.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260831-231823
---

# Stop calling a merged proposal the item's finish

## Overview

PROPOSED. `thread-reconcile` corrects a thread whose last status reply is `🔵 Proposed` or
`🟡 Handoff` once its pull request has merged or closed, and renders `🟢 Implemented` for both
merged cases. For `🟡 Handoff` that is right: the work is done and a run failed to say so.
For `🔵 Proposed` it asserts the opposite of what happened — merging a proposal lands a
feedback record and a ticket set, which is the moment the item becomes **queued**. Measured
on a consuming repository: an operator read the green circle as their ask being done while
the ticket was still in `todo/` and the thing they complained about was byte-identical.

The two cases are already distinguishable with no new state: the last status reply is read
already, and it is what tells them apart.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-thread-reconcile.sh` — the step that
  chooses the reply shape.
- `plugins/workaholic/skills/moderate/scripts/reconcile-candidates.sh` — the pure
  repository-derived candidate read; whether the narrowing belongs here or in the step is the
  first decision to make.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog, whose narrowing
  sentence ("only a thread whose last status reply is `🔵 Proposed` or `🟡 Handoff`") is what
  this ticket changes.
- `plugins/workaholic/commands/moderate.md` — the mirror copy; post formats are pinned
  byte-identical against the catalog by `scripts/test-workflow-scripts.mjs`.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's own spec.

## Implementation Steps

1. **Reproduce first.** Seed a thread whose last status reply is `🔵 Proposed` over a merged
   pull request and record that the step renders `🟢 Implemented` with the merged-outside-the-
   loop sentence. Do the same for `🟡 Handoff` so the control case is captured before anything
   changes.
2. Narrow the merged branch: a merged `🔵 Proposed` is **not** a reconcilable finish. Say
   nothing for it. The ask's own reasoning is the standard — saying nothing is strictly better
   than saying the opposite, the thread keeps its last true status, and the real
   `🟢 Implemented` still arrives when the work is driven.
3. Leave the other three transitions exactly as they are: `🟡 Handoff` → merged still renders
   `🟢 Implemented`; `🔵 Proposed` → closed without merging still renders `⚫ Closed`, which is
   correct because a refused proposal really is the item's end; `🟡 Handoff` → closed
   unchanged.
4. Count what is now skipped rather than dropping it silently, in the step's own report line,
   so a merged proposal reaching no reply is visible as a decision rather than as a step that
   found nothing.
5. Update the catalog's narrowing sentence, the `commands/moderate.md` mirror copy and the
   step's spec in `moderate/reference/workflow.md` **in the same commit**, and re-run the
   drift test that pins the copies byte-identical.
6. Add a hermetic row per transition to `scripts/test-workflow-scripts.mjs`, so the four cases
   are pinned by behaviour rather than by a return shape.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A merged `🔵 Proposed` thread receives no reply, and the step reports the skip.
- A merged `🟡 Handoff` thread still receives `🟢 Implemented`, byte-identical to today.
- A closed-without-merging `🔵 Proposed` thread still receives `⚫ Closed`.
- The catalog, the command mirror copy and the step spec agree, and the drift test passes.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the post-format drift rows.
- The four seeded transitions, each asserted on the rendered reply.

**Gate** — what must pass before approval:

- No fifth finish emoji is introduced by this ticket (see Considerations).
- The step still replies at most once per item and posts nothing addressed to nobody.

## Considerations

- **The ask offers two shapes and this ticket takes the second deliberately.** The first — a
  shape of its own saying the tickets are queued — is additive and can follow, but the catalog
  already reasons against growing the finish vocabulary ("a fifth finish emoji would make one
  event two vocabularies"), and the ask itself says saying nothing is strictly better than
  saying the opposite. Correcting the falsehood is the whole of the defect; adding a shape is
  a separate question for the operator, and nothing here forecloses it.
- A queued item whose ticket is never driven now has a thread that simply stops at
  `🔵 Proposed`. That is a true last word rather than a false one, but it is still a silence —
  worth saying in the step's spec so a later reader knows it was chosen, not overlooked.
- `[Consent]`'s retirement is untouched: this narrows what the reconcile step corrects and
  announces no human merge that it did not already announce.
