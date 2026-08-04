---
created_at: 2026-08-04T18:49:49+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission: make-a-mission-impossible-to-create-without-its-ticket-set
merge_policy: review
---

# A carry into an existing mission silently drops the remainder it exists to transfer

## Overview

`close.sh <slug> carried --successor <existing-slug>` **inherits nothing**. It resolves the successor's path, checks the file exists, sets `SUCCESSOR`, and falls through. The unmet-acceptance inheritance — the `unchecked()` extraction and everything built on it — lives entirely inside the `--successor-title` mint branch.

So the documented promise is false. `mission/SKILL.md` and `CLAUDE.md` both describe `--successor <slug>` as a merge into an existing mission that carries the remainder; what actually happens is that the predecessor is archived `carried`, a successor is named in the changelog, and every unmet acceptance item is **dropped on the floor**.

Verified by reading `close.sh` at `work-20260804-084744`: lines 153-159 are the whole `--successor <slug>` path; the inheritance begins at line 177 inside the `else`.

This is data loss, not a record defect. The predecessor is archived, so the items are no longer on the active board; the successor never received them; and nothing reports the gap.

## Why this blocks the ticket floor

The decided rule refuses `--successor-title` (a minted successor arrives with zero tickets and violates the floor by construction). That refusal is **correct and cannot be applied yet**: it would leave `--successor <slug>` as the only carry route, and that route transfers nothing — trading a record defect for a data-loss one.

The sequencing is therefore fixed and not optional: **fix the inheritance first, refuse the title second.** `20260804173625` records the floor's `close.sh` step as blocked on this ticket.

## The design question this ticket must answer

Relocating the block is not a move — the two cases need different logic:

- **Mint** builds a whole file from the template plus the predecessor's Goal, gate fields, `carried_from`, and unchecked items. It owns the file.
- **Existing successor** already has its own Goal, its own `## Acceptance`, possibly its own tickets and progress. Inheriting must **append** the predecessor's unmet items to that list without disturbing what is there, and must not import the Goal or the gate fields.

Three sub-questions, each needing a recorded answer:

1. **Where do appended items land, and do they keep their `(#…)` markers?** An unmet item may already carry a link to a ticket that was never driven. Keeping the marker preserves addressability; dropping it makes the item unlinked and the successor's board unaddressable — the failure `progress.sh`'s `unlinked` count exists to surface.
2. **What happens to `carried_from` when a mission is carried into more than once?** It is currently a scalar. Either it becomes a list, or the lineage moves to the changelog (which is already append-only and already records `mission carried into <slug>` on the predecessor's side).
3. **Is a re-run idempotent?** The mint path guards this by not rebuilding an existing successor. The append path needs its own guard, or a second `close.sh` invocation duplicates every inherited item.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a silent drop is the masked failure this policy names: the operation reports success and the loss is invisible until someone looks for items that are no longer anywhere
- `workaholic:design` / `policies/history-structures.md` — the carry exists to move a remainder between records; a carry that moves nothing breaks the history structure it is part of
- `workaholic:implementation` / `policies/objective-documentation.md` — two documents describe behavior the code does not have

## Key Files

- `plugins/workaholic/skills/mission/scripts/close.sh` — lines 152-230: the branch split and the inheritance block
- `plugins/workaholic/skills/mission/SKILL.md` — describes `--successor <slug>` as carrying the unmet items
- `CLAUDE.md` — the `/mission` row makes the same claim
- `plugins/workaholic/skills/mission/scripts/progress.sh` — the `unlinked` count that sub-question 1 affects
- `scripts/test-workflow-scripts.mjs` — has carry coverage for the mint path; none asserts the existing-successor path inherits anything

## Related History

Found while driving `20260804173624` (the ticket floor decision) on 2026-08-04. That ticket recorded the finding and the sequencing in a `close.sh` comment referencing a ticket id — **but the ticket was never written**, so the obligation existed only as prose in a code comment for the length of one run. This ticket is that obligation, made real; the comment's reference is corrected to this filename in the same change.

That is exactly the failure `drive/SKILL.md` names: *"An observation is not an obligation. Only a ticket is."* It is worth noting that the run which dropped it was the run that discovered the bug — the discovery was good work and the record of it was one step short.

## Implementation Steps

1. Answer the three sub-questions above and record the answers where the carry is documented, not only in the commit.
2. Extract the unmet-item extraction so both routes call it, keeping the mint path's behavior byte-identical (its tests must not change).
3. Implement the append path for an existing successor: unmet items appended to `## Acceptance`, no Goal or gate import, per the recorded answers on markers and lineage.
4. Make the append idempotent — a re-run must not duplicate items.
5. Fix `mission/SKILL.md` and `CLAUDE.md` to describe what the code does.
6. Add hermetic tests: a carry into an existing successor appends the unmet items and leaves the successor's own items intact; a re-run adds nothing; the mint path is unchanged.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `close.sh <slug> carried --successor <existing-slug>` leaves every unmet predecessor item present on the successor's `## Acceptance`.
- The successor's pre-existing acceptance items, Goal and gate fields are untouched.
- Running the same carry twice produces the same successor file.
- The mint path (`--successor-title`) behaves exactly as before.
- The three sub-questions have recorded answers.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with the new cases above and the existing carry cases unchanged.
- A manual carry into an existing mission, then `progress.sh` on the successor showing the inherited items counted.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with `outputs/` committed.

**Gate** — what must pass before approval:

- Suite green including the unchanged mint cases, `outputs/` fresh, and the docs matching the code.

## Considerations

- **Do not fix this by refusing `--successor <slug>` too.** That would leave `carried` with no route at all, and `carried` is the encouraged answer when a mission's direction changes mid-flight.
- **The mint path's tests are the regression guard.** If they need editing to accommodate the extraction, the extraction changed behavior — that is the signal to stop, not to update the test.
- Sub-question 1 has a real trap: an inherited item whose linked ticket was archived under the *predecessor's* branch is linked to an artifact the successor never drove. Decide whether that link is kept, and say why.
- Once this lands, `20260804173625` can apply the `--successor-title` refusal. Do not reverse the order.

## Final Report

Development completed as planned. The three sub-questions were answered before any code was written, and the answers are in `reference/schema.md` rather than only in this ticket:

1. **Markers travel verbatim** — both routes must produce the same board from the same predecessor, and an item linked to a known artifact beats an unlinked one, which `progress.sh` counts as *unaddressable*. The named trap (an inherited link pointing at a ticket the predecessor archived, which can never tick again) is real and is left to the successor's replan, where `link-acceptance.sh` refuses `linked_to_other` so re-pointing stays deliberate.
2. **`carried_from` is many-valued** — a second carry rewrites the scalar to `[first, second]`, matching the `mission:` relation convention so nothing predating it is orphaned. The successor also gains a `remainder carried from <slug>` changelog line.
3. **Idempotent by item text** — the item line including its marker is the identity, the same key `link-acceptance.sh` and `tick-acceptance.sh` address items by.

The extraction is `lib/acceptance.sh`'s `mission_unchecked_items`, called by both routes. The mint route's awk lost its private `unchecked()` and reads the pre-computed list instead; its behavior is unchanged and **no existing test was edited**, which is the regression guard the ticket asked for.

### Discovered Insights

- **Insight**: The append path had to hold back the blank line that separates `## Acceptance` from the next heading and re-emit it *after* the inherited items. Appending at the section boundary instead put the new items below the separator, leaving the next heading butted against the last item.
  **Context**: Any future "append into a markdown section" seam in this repo has the same shape — the section's *last item* and the section's *end* are different positions, and only the first one is where content belongs.

- **Insight**: Adding the second branch to `close.sh` broke the shell structure silently at first — the new `else` attached to an `if` that already had one, and `sh -n` was what caught it. The carry block is three levels of nested `if`/`else` around two routes that must not share state.
  **Context**: `sh -n` before running anything is cheap and catches exactly this. The nesting is also why the fix reads as `if [ -n "$SUCCESSOR_SLUG" ]` twice rather than as one `if/else`: the append must run *after* the resolution block completes, not inside its first arm.

- **Insight**: The dedup guard keys on the item line, so it also deduplicates across *different* predecessors — two missions carried into the same successor that shared a criterion contribute one copy.
  **Context**: That falls out of the identity choice rather than being designed, and it is the behavior you want; it is asserted in the test so it cannot regress into a duplicate-per-predecessor.
