---
type: Mission
title: Make the branch story concise by default
slug: make-the-branch-story-concise-by-default
status: active
merge_policy:
created_at: 2026-07-31T16:58:22+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours: 0.4
feedback: [20260731165727-make-the-branch-story-say-less-when-there-is-less-to-say.md, 20260731165740-filtering-low-concerns-out-of-the-story-deletes-them-from-the-stream.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260803-212338
---

# Make the branch story concise by default

## Goal

The story generator fills every section with as much as it can, so a small branch
gets a long, dense write-up. Issue #125 asks for four structural changes — fold
Historical Analysis into Motivation, list only concerns above `low`, leave
Successful Development Patterns empty unless a pattern was really found, and
flatten 8-1/8-2/8-3 into one list included only when there is something to say.

## Experience

A reader opening the PR for a small branch sees a short story. A section with
nothing to report is absent rather than filled with "None", past context reads
inside Motivation, and release preparation is one flat list that appears only
when something must be done.

## Acceptance

<!-- PROPOSED criteria - a sketch for discussion, not a plan. Approval replans
     this mission to drive-ready; only then may it be authorized. -->

- [ ] The four structural changes hold everywhere the template is mirrored:
      `report/SKILL.md`, `review-sections/SKILL.md` and its JSON contract, and
      the regenerated `outputs/` bundle
- [ ] The fate of low-severity concerns is decided and written down, given that
      `extract-deferred-concerns.sh` reads the story as its only source and
      records every severity
- [ ] A story written after the change is shorter than the same branch's story
      before it, with no section padded to look complete

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-03 — ticket archived — 20260801185701-decide-the-fate-of-low-severity-concerns.md
- 2026-08-03 — ticket archived — 20260801185702-make-the-story-short-by-default.md
- 2026-08-03 — story reported — work-20260803-212338.md
- 2026-08-03 — run recorded (+0.4h) — work-20260803-212338
- 2026-08-03 — concern deferred (stuck) — 20260803221121-section-numbers-are-now-unstable-and.md
- 2026-08-03 — concern deferred (stuck) — 20260803221121-a-mis-graded-severity-now-hides.md
- 2026-08-03 — concern deferred (stuck) — 20260803221121-the-motivation-fold-is-a-prose.md
