---
created_at: 2026-08-29T20:05:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: follow-the-pull-requests-the-loop-opens-for-a-person
merge_policy:
verification_handoff:
feedback: [20260829191722-follow-the-pull-requests-the-loop-opens-for-a-person.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
---

# Carry the ruling's subject markers into its pull request body

## Overview

MINTED MID-RUN, from a measurement taken while building the operator-facing pull-request
reading. `draft-standing-rulings.sh` is documented as writing one
`ruling: <kind> / subject: <subject>` line per drafted subject into the pull-request body, and
`list-open-rulings.sh` reads exactly those lines back to answer *which subjects does this open
ruling hold*. **The lines are not in the body.**

Measured 2026-08-29 on live PR #694 (`[Ruling] Standing rulings for the operator`), the only
open ruling on this repository:

- `GET /repos/qmu/workaholic/pulls/694 --jq .body` returns `## Overview` / `## Artifacts` /
  `## Notes` and nothing else — the body `publish-tree-pr.sh` composes for **every**
  publication. No `ruling:` line appears anywhere in it.
- `ruling-suppression.sh` therefore answers `any_open: true` with
  `held: {"attribution": [], "identity_mapping": []}` — it holds **nothing**.

Two consequences, and they pull in opposite directions, which is why this is a ticket rather
than a one-line fix:

1. **The hold silently does nothing.** `undrivable-units` and `direction-health` believe they
   are suppressing questions about subjects an open ruling already names; in fact every subject
   still asks. That is the *safe* direction (an over-eager question beats a dropped one), so
   nothing is broken today — but the mechanism is dead code that reads as coverage.
2. **The reader cannot name what a ruling would unblock.** The `operator-pulls` step composes
   `ruling-suppression.sh` precisely so its question can say what merging the pull request
   would release; with an empty `held` it can only say *a ruling is waiting*.

The likely cause is the seam, not the drafter: `publish-tree-pr.sh` **composes the body itself**
from a fixed template (`## Overview` from its `why` argument, `## Artifacts` from the commit's
name-status, `## Notes`), so any marker line a caller means to publish has to arrive through
that `why` argument or through a seam that does not yet exist. Confirm before building on it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one derivation per fact
- `workaholic:operation` / `policies/observability.md` — a mechanism that does nothing must not read as coverage

## Key Files

- `plugins/workaholic/skills/moderate/scripts/draft-standing-rulings.sh` — the drafter; where
  the marker lines are supposed to be written, and what it actually passes to the seam.
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the seam that composes the
  body. Its template is fixed and shared by every publication, which is the constraint any fix
  has to work within.
- `plugins/workaholic/skills/moderate/scripts/list-open-rulings.sh` — the reader whose
  `^ruling: ` match finds nothing today. Its header states the marker is *visible text, never an
  HTML comment*, which the fix must preserve.
- `plugins/workaholic/skills/moderate/scripts/ruling-suppression.sh` — the one consumer of the
  subjects; its two steps and `operator-pulls` all read it.

## Implementation Steps

1. **Reproduce and localize first.** Confirm on #694 (or a fresh drafted ruling) that no
   `ruling:` line reaches the body, and establish **where** it is lost — whether the drafter
   never composes it, or composes it into an argument the seam does not render.
2. Decide the seam. Prefer passing the marker through an argument the body template **already**
   renders over adding a body-fragment parameter to `publish-tree-pr.sh`: a new parameter is a
   second body-composition path for every publication, and the seam's positionals are
   `commit.sh`'s and end in an open-ended `[files...]`.
3. Preserve, provably: the marker stays **visible text, never an HTML comment**; the seam's body
   is byte-identical for every publication that writes no marker; and `list-open-rulings.sh`
   keeps its title-keyed **membership** (only the subject parse is at issue here).
4. Hermetic coverage: a drafted ruling whose body carries one marker per judged subject, read
   back through `list-open-rulings.sh` into a non-empty `held`; and a publication carrying no
   marker leaving both readers exactly as they are.
5. If the conclusion is that the markers should **not** live in the body, say so and retire the
   parse rather than leaving a reader that matches nothing — a dead mechanism that reads as
   coverage is the defect this ticket names.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A drafted ruling's pull-request body carries one visible `ruling: <kind> / subject: <subject>`
  line per judged subject, or the parse that expects them is retired with its reason recorded.
- `ruling-suppression.sh` reports a non-empty `held` for such a ruling, and an unreadable read
  still suppresses nothing.
- A publication that writes no marker produces a byte-identical body to today's.
- `list-open-rulings.sh` still decides membership by title, unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the two cases in step 4)
- `sh scripts/e2e/loop-drill.sh verify-rulings --json`
- `sh scripts/e2e/loop-drill.sh verify-operator-pulls --json`

**Gate** — what must pass before approval:

- Both drills and the suite pass, and the step-1 localization is recorded in the branch story.

## Considerations

- The failure is **silent and safe**, which is exactly why it survived: every question the hold
  should have suppressed was asked instead, and an extra question looks like the mechanism
  working. Nothing in the tick reports a `held` set that is empty for the wrong reason.
- Do not widen `list-open-rulings.sh` into the shape derivation
  (`branching/scripts/lib/publication-refusal.sh`) to compensate: that rule answers *which pull
  requests are the operator's* and carries no subjects at all, and merging the two would put a
  brake and a reading on one derivation whose bounds differ.
