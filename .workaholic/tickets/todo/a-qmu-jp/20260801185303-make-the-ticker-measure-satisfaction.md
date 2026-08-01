---
created_at: 2026-08-01T18:53:03+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on: [20260801185302-establish-the-link-when-tickets-are-emitted.md]
mission: make-acceptance-ticking-measure-satisfaction-not-marker-shape
merge_policy: auto
---

# Make the ticker measure satisfaction, and repair the stranded boards

## Overview

The two remaining halves, which must land together because the second is only reachable
through the first.

**The ticker.** `tick-acceptance.sh`'s `no_unchecked_match` currently means two different
things — "this criterion is not satisfied" and "this criterion is not addressable by me" —
and a caller cannot tell them apart. After the decided contract, it must mean only the
first: not-addressable becomes either impossible to author or its own distinct result.

**The stranded boards.** The active missions carry markerless items written before this
fix, and a mechanism that only works for newly-emitted missions leaves every existing
board pinned. There must be a **sanctioned path** that brings them to the truth — nobody
hand-edits a checkbox. Note that the count moves as missions are fleshed out and driven,
so re-measure rather than working from the mission's stated 24.

## Policies

- `workaholic:development` / `policies/qa-engineering.md` — the gate must report satisfaction; a result that conflates "not done" with "not measurable" is not a gate.
- `workaholic:implementation` / `policies/observability.md` — an unaddressable item must be distinguishable from an unsatisfied one in the script's own output.
- `workaholic:implementation` / `policies/error-handling.md` — a markerless item is a foreseeable input, not an exceptional one.

## Key Files

- `plugins/workaholic/skills/mission/scripts/tick-acceptance.sh` - the ticker
- `plugins/workaholic/skills/mission/scripts/progress.sh` - derives `checked/total` from the same lines
- `plugins/workaholic/skills/drive/scripts/archive.sh` - a caller: ticks on ticket archive
- `plugins/workaholic/skills/ship/scripts/` - the other calling seams
- `scripts/test-workflow-scripts.mjs` - hermetic coverage

## Implementation Steps

1. Implement the decided contract in `tick-acceptance.sh`.
2. Split the result vocabulary so `no_unchecked_match` means "not satisfied" and an
   unaddressable item, if the contract still permits one, reports separately.
3. Provide the repair path for existing missions and run it. It must be a script, and
   running it must be idempotent and reversible in review — a diff a human can read.
4. Re-measure the stranded count before and after, and record both.
5. Make the recurrence impossible to hide: whatever the contract chose, a markerless item
   must be either unwritable or provably tickable. Assert that, so a 0-of-N split cannot
   reappear silently.
6. Update the calling seams if the result vocabulary changed, and rebuild `outputs/`.

## Quality Gate

**Acceptance criteria**

- `tick-acceptance.sh` implements the decided contract, and `no_unchecked_match` means "not satisfied" rather than "not addressable".
- Every stranded item across the active missions is reachable by a sanctioned script, with no checkbox hand-edited.
- A markerless acceptance item is either impossible to author or provably tickable — asserted, not asserted-in-prose.
- `progress.sh` still derives the same `checked/total` from the changed lines.
- The stranded count is re-measured before and after, and both are recorded.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, including a mission whose acceptance items carry no marker, and a case pinning the distinction between "not satisfied" and "not addressable".
- Run the repair path against the live missions and read the diff.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

**Gate**

- The hermetic case for a markerless mission passes, and no checkbox in the repository was edited by hand. The second is checkable from the diff.

Decided: the ticker fix and the repair land in one ticket — the repair is only reachable through the new contract, and shipping the contract without it leaves every existing board pinned, which is the visible symptom the mission exists to remove (developer may override at /drive).

## Considerations

- The repair rewrites lines in live `mission.md` files. Run it through the shared mutators so the write goes through one seam, and keep the diff small enough to read — a bulk rewrite nobody checks is how a wrong tick gets in.
