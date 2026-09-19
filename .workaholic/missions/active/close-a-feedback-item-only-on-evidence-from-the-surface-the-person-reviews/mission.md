---
type: Mission
title: Close a feedback item only on evidence from the surface the person reviews
slug: close-a-feedback-item-only-on-evidence-from-the-surface-the-person-reviews
status: active
merge_policy:
created_at: 2026-09-19T09:46:12+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260919094536-verify-a-feedback-item-on-its-own-review-surface-before-closing-it.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Close a feedback item only on evidence from the surface the person reviews

## Goal

A feedback issue is closed by `Closes #<N>` on the **ingest** pull request, so it ends when the
proposal merges — before any implementation exists and before anyone looks at the surface the
person reviews. `feedback-outcome.sh` reconciles per item, but its `expected_surface` is supplied
by whoever composes the facts and written on no artifact.

## Experience

A person's item is closed when evidence from **their** review surface says it landed, and stays
open with a named reason when it did not. The surface the ask named is carried on the artifact,
not asserted at report time. A run that cannot read the evidence says so and closes nothing.

## Acceptance

<!-- PROPOSED - a sketch the reviewer replans drive-ready. -->

- [ ] The review surface an ask names is persisted on the artifact and read back, not asserted (#20260919094701-carry-the-ask-s-review-surface-onto-the-artifact-it-emits.md)
- [ ] Merging the ingest pull request no longer closes the source feedback issue (#20260919094701-stop-the-ingest-pull-request-closing-the-source-feedback-issue.md)
- [ ] A source issue is closed only on a reconciliation reading `implemented_and_verified`, and
      an unclosed item names which state held it (#20260919094701-close-a-source-issue-only-on-a-verified-reconciliation.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
