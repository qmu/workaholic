---
type: Mission
title: Let the tick's own findings become the loop's work
slug: let-the-tick-s-own-findings-become-the-loop-s-work
status: achieved
merge_policy:
created_at: 2026-08-29T04:20:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829041743-let-the-tick-s-own-findings-become-the-loop-s-work.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-044056
---

# Let the tick's own findings become the loop's work

## Goal

`/moderate` has two destinations for a finding — a question to a person, or a
feedback record. Neither becomes work, because `[Specificate]` reads **issues**.
Give a **repairable** finding the third destination, through the seam that
already exists (`file-inbound-ask.sh`), so the loop drives its own debt while a
finding needing a human **ruling** still asks, exactly as it does now.

## Experience

The tick's repairable findings arrive as issues the loop drives. A branch CI
could not delete, a diverged channel default, a conflicting pull request: each
becomes an `[FB]` issue at the tick, a plan at the next `:15` and a merged
repair at the next `:30` — with the person asked only about findings that need
their ruling, and the run report naming what was filed, held and left.

## Acceptance

- [x] A repairable finding becomes an issue and its question is suppressed; a
      `needs_ruling` finding still asks, unchanged. (#20260829042145-suppress-the-question-a-filing-answers.md)
- [x] The brake holds at one open finding issue, the dedup is structural on the
      step id, and an unreadable read files nothing. (#20260829042145-dedup-the-filing-structurally-on-the-step-id.md)
- [x] `verify-findings-to-work` drills it offline, with a breaker row. (#20260829042145-drill-the-findings-to-work-path-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-29 — ticket archived — 20260829042144-pin-the-gap-between-a-tick-finding-and-the-work-queue.md
- 2026-08-29 — ticket archived — 20260829042144-classify-a-finding-as-repairable-or-needing-a-ruling.md
- 2026-08-29 — ticket archived — 20260829042144-write-the-finding-filing-step.md
- 2026-08-29 — ticket archived — 20260829042144-brake-the-filing-to-one-open-finding-issue.md
- 2026-08-29 — ticket archived — 20260829042145-dedup-the-filing-structurally-on-the-step-id.md
- 2026-08-29 — ticket archived — 20260829042145-suppress-the-question-a-filing-answers.md
- 2026-08-29 — ticket archived — 20260829042145-report-what-was-filed-held-and-left.md
- 2026-08-29 — ticket archived — 20260829042145-drill-the-findings-to-work-path-offline.md
- 2026-08-29 — mission achieved — mission.md
- 2026-08-29 — story reported — work-20260829-044056.md
