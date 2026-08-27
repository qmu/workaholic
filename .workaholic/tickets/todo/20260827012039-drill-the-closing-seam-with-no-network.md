---
created_at: 2026-08-27T01:20:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Drill the closing seam with no network

## Overview

The closing seam is the one the loop cannot prove by running: a real refusal needs a real session
class, and waiting for a tick to reproduce it is what let four undelivered pull requests
accumulate unnoticed. Add `loop-drill.sh verify-close`, drilling all four outcomes over a fixture
with the transport stubbed and **no network at all**:

1. **merged** — the REST merge succeeds and the unit closes.
2. **session-type-refused-then-retried** — REST answers `session_type_cannot_merge`, the connector
   retry runs and lands.
3. **refused-and-unretryable** — any other `merge-reason.sh` word: no retry, refusal reported, the
   unit is undelivered.
4. **scan-held** — a `hard` or `confirm` finding held the pull request; no merge was attempted and
   `ok` is unaffected.

And **one row that deliberately proves the drill can fail** — the property `verify-identity-handoff`
and `verify-merged-claim` both carry, because a drill that passes over a broken seam is worse than
no drill.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a proof that cannot fail proves nothing

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill harness. **Read `verify-merged-claim` and
  `verify-identity-handoff` in full first**: both drill a network-shaped question with the
  transport stubbed, and both carry the deliberately-failing row. They are the pattern.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file blame tables;
  the new drill needs its rows there.
- `plugins/workaholic/skills/branching/scripts/merge-reason.sh` — the four outcomes' vocabulary.
- `plugins/workaholic/skills/release-scan/scripts/gate-decision.sh` — the tier reading that decides
  the scan-held row.
- `CLAUDE.md` — the drill list in the Routines section names every verify target.

## Implementation Steps

1. Read the two existing network-stubbed drills end to end and reuse their stubbing approach
   rather than inventing a third.
2. Build the fixture: a claim, a drained queue, a story, a pull request, and a stubbed merge
   response per row.
3. Add `verify-close` covering the four outcomes plus the deliberately-failing row, asserting the
   run report's merge outcome, the retry's outcome, the exclusion reason and the terminal token in
   each.
4. Assert it makes no network call — the drill must pass with the transport absent.
5. Add its rows to `docs/loop-drill-runbook.md` and its name to `CLAUDE.md`'s drill list, in the
   same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-close` passes over the fixture with no network.
- All four outcomes are asserted, each on its own row.
- The deliberately-failing row fails, and the drill reports it as the proof it is.
- The runbook and `CLAUDE.md` name the new target.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-close`
- Run it with the network unavailable and confirm identical output.

**Gate** — what must pass before approval:

- The drill passes offline; breaking any seam this mission touched makes it fail.

## Considerations

- `loop-drill.sh` is operator tooling outside the plugin and assumes the server's full `gh` and
  `qfs`. Keep this target inside that assumption but independent of it: the stub is what makes the
  drill runnable, and a target that needs a live session class is the thing this ticket exists to
  avoid.
- Drive this last. It is the mission's proof, and a drill written against a seam that has not
  settled is rewritten with every ticket above it.
