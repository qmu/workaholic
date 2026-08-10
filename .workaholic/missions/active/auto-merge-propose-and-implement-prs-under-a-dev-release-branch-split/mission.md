---
type: Mission
title: Auto-merge propose and implement PRs under a dev/release branch split
slug: auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split
status: active
merge_policy:
created_at: 2026-08-10T09:01:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [.workaholic/feedbacks/20260810090035-auto-merge-propose-and-implement-prs-without-confirmation-under-a-dev-release-branch-split.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260811-005414
---

# Auto-merge propose and implement PRs under a dev/release branch split

## Goal

Stop requiring human confirmation before `/propose`'s and `/implement`'s own
pull requests merge — merge them immediately once created — trusting three
new complementary loops (QA, release-planning, post-release quality-check)
and the existing `release/*` QA-window tier, rather than per-PR review, as
the safety net. `main` becomes the continuously auto-merged development
branch; `release/*` stays the pre-production boundary.

## Experience

A developer no longer reviews/approves each `/propose`- or `/implement`-
produced pull request before it merges: both merge their own PR right after
opening it and post one simplified notification (`🔵 Proposed` /
`🟢 Implemented`) with no separate "started" line. Risk from an unreviewed
merge is caught downstream — by later development work, by the QA loop, or
by whichever agent plans the release — not blocked at merge time.

## Acceptance

- [x] `/propose` and `/implement` (and their routine templates) merge their
      own pull request immediately after creating it, with no
      human-confirmation step, and post the simplified `🔵 Proposed` /
      `🟢 Implemented` notifications, dropping the separate "started" post. (#20260810090145-merge-propose-and-implement-prs-immediately-no-confirmation.md)
- [x] The branch model explicitly documents `main` as the continuously
      auto-merged development branch, with `release/*` (existing tier) as
      the pre-production QA/release boundary. (#20260810090145-document-main-as-the-dev-branch-with-release-as-the-qa-boundary.md)
- [x] The QA loop, release-planning loop, and post-release quality-check
      loop this policy depends on are each captured as a named, scoped
      follow-on mission — not fully designed here, but traceable rather
      than assumed. (#20260810090145-scope-qa-release-planning-and-post-release-quality-check-loops.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-11 — ticket archived — 20260810090145-merge-propose-and-implement-prs-immediately-no-confirmation.md
- 2026-08-11 — ticket archived — 20260810090145-document-main-as-the-dev-branch-with-release-as-the-qa-boundary.md
- 2026-08-11 — ticket archived — 20260810090145-scope-qa-release-planning-and-post-release-quality-check-loops.md
