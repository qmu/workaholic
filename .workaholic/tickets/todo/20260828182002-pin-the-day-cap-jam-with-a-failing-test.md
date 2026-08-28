---
created_at: 2026-08-28T18:20:02+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Pin the day-cap jam with a failing test

## Overview

PROPOSED. Reproduce the reported jam as a hermetic test before anything is changed, so the
repair is measured rather than asserted and a regression is caught by the suite rather than
by an operator noticing the channel has gone quiet.

The failure was reproduced against the live tree while this proposal was written:
`log-read.sh --step-prefix human-checkin-ask` answers `count: 12, days: 5` with no day
bound, `max_per_day` is 10, and a fresh key on a working weekday at 14:00 is refused
`day_cap` with `asked_today: 12` — while the same reader bounded to the current
`Asia/Tokyo` day answers `count: 0`. The value named `asked_today` is the all-time total.

This ticket writes the test only. The repair is the next ticket, so the test is proved to
fail on the current tree first.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testable-design.md` — gaps in reasoning made machine-checkable early

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the new case lands here, beside
  the existing `ask-question.sh` cases.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the subject: line 320,
  `asked_today=$(count_log_prefix human-checkin-ask "")`.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the reader the count goes
  through; it already accepts `--since <YYYY-MM-DD>`.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — how the fixture log is
  written, so the test builds its fixture through the sanctioned writer.

## Implementation Steps

1. **Reproduce it first, in a throwaway tree.** Build a fixture `.workaholic/moderations/`
   holding `human-checkin-ask-*` lines across several *earlier* day files and **none** on
   the day the test asks about, at a count at or above `max_per_day`. Write them through
   `log-append.sh` with explicit tick ids, never by hand, so the fixture is the shape the
   tick actually produces.
2. **Assert the jam.** `ask-question.sh --root <fixture> --tick <today>-HHMMSS --key <fresh>
   --hour 14 --weekday 3 --max-per-day 10` must currently answer `reason: "day_cap"`. Record
   in the test's own comment that this is the *pre-repair* expectation.
3. **Write the assertion the repair must satisfy**: with no `human-checkin-ask` line on the
   tick's own day, the answer is `ask: true`. Leave it failing, and name it in the case title
   as the behaviour being pinned.
4. **Pin what must not move beside it**, so the next ticket's change is bounded: a fixture
   with `max_per_day` lines **on the tick's own day** still answers `day_cap` with
   `hold: true`; a key already carrying a `human-checkin-ask-<slug>` line still answers
   `already_asked`; an `answered` key still answers `answered`; `tick_cap` still fires at
   `max_per_tick` within one tick.
5. Run `node scripts/test-workflow-scripts.mjs` and confirm the new case fails for the stated
   reason and every pinned case passes.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A hermetic case exists whose fixture carries `human-checkin-ask` lines only on days before
  the tick's own day, and which expects `ask: true`.
- That case **fails on the current tree**, with `reason: "day_cap"` in the failure output.
- The four pinned cases (same-day cap, `already_asked`, `answered`, `tick_cap`) pass.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new case reports a failure naming `day_cap`;
  the pinned cases pass.

**Gate** — what must pass before approval:

- The test creates its tree under the OS temp dir, never touches the working tree, and makes
  no network or `gh` call.

## Considerations

- The failing test is committed **before** the repair on purpose: a test written after a fix
  proves the fix's own shape rather than the reported failure. If the driving run prefers one
  commit, keep the two as separate commits in it.
- The same unbounded expression appears a second time, in the `outstanding` re-ask branch
  (`ask-question.sh:309-310`), where it fills **both** `asked_this_tick` and `asked_today`.
  The next ticket owns the repair; note it here so it is not missed.
- `log-read.sh` compares dates lexically against file names by deliberate design (`date -d`
  is GNU-only, `date -v` BSD-only). The fixture must use `YYYY-MM-DD.md` names accordingly.
