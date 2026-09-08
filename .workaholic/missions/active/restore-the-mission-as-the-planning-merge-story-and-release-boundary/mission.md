---
type: Mission
title: Restore the mission as the planning, merge, story, and release boundary
slug: restore-the-mission-as-the-planning-merge-story-and-release-boundary
status: active
merge_policy:
created_at: 2026-09-08T12:47:04+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260908124644-restore-mission-sized-batching-as-the-release-boundary.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260908-130859
---

# Restore the mission as the planning, merge, story, and release boundary

## Goal

Restore one coherent unit across planning and delivery: related feedback forms or extends a real mission, its tickets are driven as one PR-unit, one story explains the outcome, and versioning and delivery occur at that completed mission boundary.

## Experience

A burst of related small asks no longer creates one proposal merge, implementation merge, version, release, and notification per item. The operator sees one mission plan and one delivered change set, while every source feedback remains traceable.

## Acceptance

- [x] Capture, specification, and dedup have one owner and cannot suppress an ask by recording it at the wrong seam. (#20260908124710-define-one-ownership-model-from-feedback-capture-to-mission-formation.md)
- [x] Related asks accumulate in one bounded mission whose whole ticket set is claimed, reviewed, and narrated as one PR-unit and story. (#20260908124710-batch-related-asks-into-one-standing-mission-plan.md)
- [ ] Version bump, release note, merge, delivery, and human notification occur once at the completed mission boundary. (#20260908124710-version-and-deliver-only-at-the-completed-mission-boundary.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-08 — ticket archived — 20260908124710-define-one-ownership-model-from-feedback-capture-to-mission-formation.md
- 2026-09-08 — ticket archived — 20260908124710-batch-related-asks-into-one-standing-mission-plan.md
