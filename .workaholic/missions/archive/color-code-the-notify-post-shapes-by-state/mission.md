---
type: Mission
title: Color-code the notify post shapes by state
slug: color-code-the-notify-post-shapes-by-state
status: achieved
merge_policy:
created_at: 2026-08-10T06:30:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.37
feedback: [.workaholic/feedbacks/20260810062845-color-code-the-notify-post-shapes-by-state.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260810-083550
---

# Color-code the notify post shapes by state

## Goal

`workaholic:notify`'s post shapes currently reuse one glyph across two states each —
📐 covers both Designing and Proposed, 🛠️ covers both Implementing and Implemented — so a
developer scanning a `dev-` Slack thread cannot tell a phase's start from its finish by
emoji alone. Color-code every shape by state instead, one color per exactly one state:
🔵 Proposed, 🟠 Implementing, 🟡 Handoff, 🟢 Implemented, 🔴 Blocked, keeping 🚀 Auto Merge
outside the color set (the auto/human merge distinction must stay visually distinct).
Whether the retired 🟣 human-merge shape (erased per #317) has a place in this scheme is
an open question for the design ticket, not foreclosed here — developer note during
proposing: purple circle should not be excluded from this direction. Supersedes the
un-implemented ruling in FB `20260807190939` (issue qmu/workaholic#330).

## Experience

A developer reading a `dev-<repo>` thread identifies a unit's current state from its
latest emoji alone, with no two states sharing a color. The design decides where the
design-start post's own color lands (state-color-of-what-it-opens, i.e. the 🔵 family, or
an alternative the design ticket judges) and produces the exact shape catalog; the
implementation applies it across `workaholic:notify`'s `SKILL.md` and
`reference/notifications.md`, both routine prompt templates in
`skills/workaholify/routines/`, and the prompt-is-the-ceiling rule's example text, then
rebuilds `outputs/workflows`.

## Acceptance

- [x] A design ticket resolves the exact color-per-state shape catalog, including where
      the design-start (📐 Designing) post's color lands (#20260810063036-resolve-the-color-per-state-notify-shape-catalog.md)
- [x] An implementation ticket applies the resolved catalog across
      `workaholic:notify`'s `SKILL.md`/`reference/notifications.md`, both routine
      templates in `skills/workaholify/routines/`, and the prompt-is-the-ceiling
      example text, and rebuilds `outputs/workflows` (#20260810063039-apply-the-color-per-state-notify-shape-catalog.md)
- [x] The `/propose` design-start post reads "Proposing" (not "Designing") and every
      post's attribution reads "the [routine](...)" (not "[Claude Code on the Web](...)"),
      matching the developer's dictated template in issue #333 (#20260810083127-align-propose-start-wording-and-attribution-link-text.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-10 — ticket archived — 20260810063036-resolve-the-color-per-state-notify-shape-catalog.md
- 2026-08-10 — ticket archived — 20260810063039-apply-the-color-per-state-notify-shape-catalog.md
- 2026-08-10 — story reported — claude-lucid-tesla-4yz3ob.md
- 2026-08-10 — ticket added — 20260810083127-align-propose-start-wording-and-attribution-link-text.md
- 2026-08-10 — mission replanned (issue #333 wording fix: Designing to Proposing, Claude Code on the Web to the routine) — mission.md
- 2026-08-10 — ticket archived — 20260810083127-align-propose-start-wording-and-attribution-link-text.md
- 2026-08-10 — story reported — work-20260810-083550.md
- 2026-08-10 — run recorded (+0.37h) — session-01UqamDaSDrTMQCZo8bqsfd1-wording-fix
- 2026-08-12 — mission achieved — mission.md
