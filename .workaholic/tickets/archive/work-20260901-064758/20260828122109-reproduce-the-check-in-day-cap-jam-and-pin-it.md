---
created_at: 2026-08-28T12:21:09+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Reproduce the check-in day-cap jam and pin it

## Overview

The check-in gate refuses every question `day_cap`, and the loop cannot tell.
This ticket **reproduces and localizes** the failure before anything is changed,
and leaves behind the hermetic test that fails on the current tree — so the
repair that follows is measured against a red test rather than asserted.

The reporter's diagnosis is a hypothesis to confirm, not the design: it names
`ask-question.sh`'s `asked_today` and an unbounded `log-read.sh` walk. Confirm it
against the running tree first (measured on this repository at the time of
writing: `log-read.sh --step-prefix human-checkin-ask` counts 12 across 5 day
files, against a `max_per_day` of 10 — so the count is all-time and has been
past the ceiling since 2026-08-27).

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testability.md` — machine-checkable gaps caught early

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate; `count_log_prefix`
  and the `asked_today` derivation feeding the `day_cap` refusal
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the reader, and its existing
  `--since <YYYY-MM-DD>` day bound
- `scripts/test-workflow-scripts.mjs` — where the hermetic test lands

## Implementation Steps

1. **Reproduce.** Build a throwaway `.workaholic/moderations/` fixture carrying
   `human-checkin-ask-*` lines on several **earlier** day files and none on today's,
   and call `ask-question.sh` with a fresh key. Record the actual refusal.
2. **Localize.** Confirm which read produces the count — `count_log_prefix
   human-checkin-ask ""` calling `log-read.sh --step-prefix` with no day bound — and
   confirm `--since` is the bound already available rather than proposing a new one.
3. **Pin it.** Add the hermetic test to `scripts/test-workflow-scripts.mjs`: the
   fixture above must **not** refuse `day_cap`. Leave it failing; ticket 2 turns it green.
4. Confirm the neighbouring gates are untouched by the fixture — `already_asked`,
   `answered`, `tick_cap` and `hold: true` must answer exactly as they do today.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A hermetic test exists that fails on the current tree with the `day_cap` refusal.
- The reproduction is over a fixture directory, never the repository's own log.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new case fails, and only it.

**Gate** — what must pass before approval:

- The test creates its repositories under the OS temp dir, touches no working tree,
  and makes no `gh`/network call.

## Considerations

- The measured count (12 over 5 days) will keep growing; the test must construct its
  own fixture rather than depend on the live log, or it stops meaning anything.
- Do not fix the bug in this ticket. A red test that the next ticket turns green is
  the evidence the repair actually addresses the cause.

## Final Report

**The work is already on the base.** This ticket reached `todo/` on 2026-09-01, when the
tick that repaired the stranded-publication path merged proposal #688 — opened 2026-08-28
and stranded for four days. The repair it asks for landed in the meantime by another route.

Verified against the tree rather than by file existence:

- `scripts/test-workflow-scripts.mjs` carries the hermetic reproduction at lines 27093-27177.
  It pins the jam in the ticket's own terms: a log whose asks are all on **earlier** days no
  longer refuses (`fresh.asked_today` is `0`), while a cap genuinely spent on the tick's own
  day still refuses `day_cap` — which is the discrimination the ticket asked the red test to
  make.
- `ask-question.sh`'s header records the confirmed diagnosis verbatim, including the measured
  numbers (`count: 12, days: 5` against a cap of 10, the same reader bounded to the current
  day answering `count: 0`).

The reporter's hypothesis was confirmed rather than assumed, which is what this ticket asked
for; nothing here was re-implemented.
