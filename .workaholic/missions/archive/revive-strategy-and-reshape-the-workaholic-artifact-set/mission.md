---
type: Mission
title: Revive Strategy and reshape the .workaholic artifact set
slug: revive-strategy-and-reshape-the-workaholic-artifact-set
status: achieved
merge_policy:
created_at: 2026-08-13T11:25:09+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 1.5
feedback: [20260813112458-revive-the-strategy-artifact-and-reshape-the-workaholic-artifact-set.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260813-113709
---

# Revive Strategy and reshape the .workaholic artifact set

## Goal

Issue #436 asks for six changes to the `.workaholic/` artifact set: a revived `Strategy` (Aim, Schedule, Assignee), a feedback record naming the subject that formed the opinion, the removal of `policies/`, `guides/` and `specs/`, a defined and maintained `deployments/` and `terms/`, a two-state ticket tree, and every migration applied through `/workaholify`.

## Experience

An operator reads direction from a `Strategy` and sees who formed each piece of feedback; only areas with a writer survive; `tickets/` holds `todo/` and `archive/` alone. A consuming repo converges on the same shape by running `/workaholify`.

## Acceptance

Proposed sketch — interrogate before driving.

- [x] `Strategy` is a registered artifact carrying Aim/Schedule/Assignee, and a new feedback record names the subject that formed it (#20260813112616-record-the-subject-that-formed-each-feedback.md)
- [x] `.workaholic/` carries no `policies/`, `guides/` or `specs/`; `deployments/` and `terms/` have a stated definition and an upkeep seam (#20260813112618-redefine-the-deployments-and-terms-areas.md)
- [x] `tickets/` holds only `todo/` and `archive/`, former abandoned and icebox tickets carrying their state in frontmatter, and `/workaholify` applies each migration (#20260813112620-apply-the-layout-migrations-through-workaholify.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-13 — ticket archived — 20260813112615-revive-the-strategy-artifact-with-aim-schedule-and-assignee.md
- 2026-08-13 — ticket archived — 20260813112616-record-the-subject-that-formed-each-feedback.md
- 2026-08-13 — ticket archived — 20260813112617-retire-the-policies-guides-and-specs-areas.md
- 2026-08-13 — ticket archived — 20260813112618-redefine-the-deployments-and-terms-areas.md
- 2026-08-13 — ticket archived — 20260813112619-fold-abandoned-and-icebox-tickets-into-the-archive.md
- 2026-08-13 — ticket archived — 20260813112620-apply-the-layout-migrations-through-workaholify.md
- 2026-08-13 — story reported — work-20260813-113709.md
- 2026-08-13 — run recorded (+1.0h) — implement-20260813-113709
- 2026-08-13 — run recorded (+0.5h) — 20260813-1400-catchup
- 2026-08-13 — ticket archived — 20260813125500-re-read-the-stale-terms-glossary-content.md
- 2026-08-14 — mission achieved — mission.md
