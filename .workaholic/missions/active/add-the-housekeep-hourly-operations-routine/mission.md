---
type: Mission
title: Add the /housekeep hourly operations routine
slug: add-the-housekeep-hourly-operations-routine
status: active
merge_policy:
created_at: 2026-08-17T11:36:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260817113647-add-housekeep-an-hourly-project-operation-routine.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260817-114453
---

# Add the /housekeep hourly operations routine

## Goal

Give the loop a maintenance tick. `[Propose]` turns asks into work and `[Implement]`
drives it; nothing keeps the space *around* them tidy — stale issues, GitHub↔`.workaholic/`
drift, pull requests stuck after a failed auto-merge, docs that no longer match the
concept. `/housekeep` is the hourly routine that finds those, files them through the
existing seams, and says what needs a human (issue #471).

## Experience

An operator returning to the repository finds it judgeable: nothing stale unexplained,
nothing silently stuck, no README describing a retired design, and a standing per-tick log
under `.workaholic/`. What the tick cannot decide reaches a human as a Slack question — at
most five a tick, never late at night — instead of a silent guess.

## Acceptance

<!-- PROPOSED — a sketch for discussion. Approval replans this to drive-ready. -->

- [x] The nine steps run end to end unattended, log to a registered `.workaholic/` area,
  and file findings through the existing seams. (#20260817113750-add-the-housekeep-command-and-skill.md)
- [ ] The template ships with a declared scope and cron, is converged by that scope's setup
  command, and posts only shapes its prompt names. (#20260817113755-ship-the-housekeep-routine-template.md)
- [x] Every step reversing a standing decision is ruled on by the operator or left unbuilt,
  never inferred. (#20260817113753-implement-the-strategy-proposal-step.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->

- 2026-08-17 — Proposed from issue #471.
- 2026-08-17 — ticket archived — 20260817113749-register-the-housekeep-log-area.md
- 2026-08-17 — ticket archived — 20260817113750-add-the-housekeep-command-and-skill.md
- 2026-08-17 — ticket archived — 20260817113751-implement-the-inbound-sweep-steps.md
- 2026-08-17 — ticket archived — 20260817113752-implement-the-repository-hygiene-steps.md
- 2026-08-17 — ticket archived — 20260817113753-implement-the-strategy-proposal-step.md
