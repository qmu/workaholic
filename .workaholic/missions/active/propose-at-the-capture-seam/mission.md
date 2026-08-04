---
type: Mission
title: Propose at the capture seam
slug: propose-at-the-capture-seam
status: active
merge_policy: 
created_at: 2026-08-04T22:13:41+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
feedback: [20260804221328-propose-at-the-capture-seam-not-from-a-merged-main-window.md]
claim: work-20260804-221713
---

# Propose at the capture seam

## Goal

The developer's 2026-08-04 ruling: proposing is not fixed to any single output, and
it happens **where the ask arrives**. `/propose` was built to read only feedback
already merged to `main`, which made the record just written invisible to it by
design — the reason a separate 15-minute sweeper ([Propose Batch]) had to exist at
all. That window model is the defect; the batch compensated for it. Fold the
judgment into the capture session, and the sweeper, the shared cursor ref, and the
merged-main window all become unnecessary.

## Experience

A developer reports an ask in Slack. The [Propose] routine's one session records
the feedback and judges it there and then, emitting in **one PR**: the record plus
a mission with its ticket set, or the record plus one loose ticket, or the record
alone when no work is warranted — feedback-only is a judged outcome, never the
routine's definition. Merging that PR approves the record and its proposal in one
act, and nothing anywhere waits on a cron tick to notice feedback.

## Acceptance

- [x] One capture session can emit, in one PR, the feedback record together with its proposed mission/tickets or loose ticket, with record-only as the judged fallback (#20260804221347-judge-and-propose-inside-the-capture-session.md)
- [ ] The [Propose Batch] template, the pushed cursor ref machinery, and the merged-main window are gone, and every document tells the new truth (#20260804221347-retire-the-batch-seat-and-the-merged-main-window.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
- 2026-08-04 — ticket archived — 20260804221347-judge-and-propose-inside-the-capture-session.md
