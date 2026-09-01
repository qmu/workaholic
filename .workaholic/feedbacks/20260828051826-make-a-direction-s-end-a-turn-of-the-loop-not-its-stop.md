---
type: Feedback
title: Make a direction's end a turn of the loop, not its stop
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-28T05:18:26+00:00
author: a@qmu.jp
supersedes: 
---

# Make a direction's end a turn of the loop, not its stop

Source: https://github.com/qmu/workaholic/issues/678

The `[Propose]` routine asks for the end of a direction to become a turn of the loop
rather than its stop, without a machine ever authoring a direction.

Every reading in the direction layer is bounded to `status: active`, so the moment the
operator closes the last live direction the loop originates nothing: `/propose` refuses
`not_active`, `[Specificate]` reads an empty inbox, `[Implement]` has nothing to drive,
and the only signal is `direction-none`, addressed to nobody.

Two things must become true:

1. A closing direction states what it is leaving — what it never reached
   (`attributed-work.sh`'s waiting grains), what no direction claimed
   (`unattributed-work.sh`'s residue) and its own last lifecycle reading — composed in one
   reader over the readers that already exist, surfaced at the close and at the question.
2. A successor inherits its predecessor's visibility through the relation that already
   exists: an announced successor's `feedback:` line carries the predecessor's own refs,
   emitted through `ask-feedback-line.sh`, so `attributed-work.sh` reads the predecessor's
   landed work and residue as the successor's from its first hour.

The authorship premise does not move: no routine creates, closes or drafts a direction on
its own reading, identification stays explicit-slug-only, a strategy-touching publish never
auto-merges, and `close.sh` stays the only writer of an end state.
