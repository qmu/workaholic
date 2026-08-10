---
created_at: 2026-08-10T06:30:36+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: color-code-the-notify-post-shapes-by-state
merge_policy:
---

# Resolve the color-per-state notify shape catalog

## Overview

`workaholic:notify`'s post shapes currently reuse one glyph across two states each: 📐
covers both Designing and Proposed, 🛠️ covers both Implementing and Implemented, so a
developer scanning a `dev-` thread cannot tell a phase's start from its finish by emoji
alone. Issue qmu/workaholic#330 (FB `20260810062845`) asks for one color mapping to
exactly one state instead: 🔵 Proposed, 🟠 Implementing, 🟡 Handoff, 🟢 Implemented, 🔴
Blocked, with 🚀 Auto Merge deliberately kept outside the color set (the auto/human merge
distinction must stay visually distinct on its own; the retired 🟣 human-merge shape from
qmu/workaholic#317 is **not** to be reintroduced). This design-only ticket resolves the
exact catalog — including where the design-start (currently 📐 Designing) post's color
lands: the issue suggests it should adopt the state color of what it opens (the 🔵
family), or the design may judge otherwise. It supersedes the un-implemented six-color
ruling in FB `20260807190939`, whose 🟣 half is moot since #317's erasure. Line wording is
unchanged (issue #300's two-line format) — only the leading emoji and state words change.
The companion implementation ticket applies whatever this one resolves.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` — the shape catalog is a small piece of interaction design (what a
  developer reads at a glance), so the resolved mapping should be judged against clarity,
  not just convenience

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the sole-sanctioned shape
  catalog (P10); every current shape (`📐 Designing`, `📐 Proposed`, `🛠️ Implementing`,
  `🛠️ Implemented`, `🚀 Auto Merge`, `🟡 Handoff`, `🔴 drive blocked`) lives here
- `plugins/workaholic/skills/notify/SKILL.md` — the standing rules referencing the shapes
  (*Post shapes, mentions, and the red-alert dedup*)
- `.workaholic/feedbacks/20260807190939-adopt-the-six-color-notify-state-emoji-set-keeping-the-rocket-for-auto-merge.md`
  — the prior, un-implemented six-color ruling this supersedes; read for the color set it
  already picked (🔵/🟠/🟡/🟢/🟣/🔴) minus the now-moot 🟣 slot
- `.workaholic/feedbacks/20260810062845-color-code-the-notify-post-shapes-by-state.md` —
  this mission's own source record

## Implementation Steps

1. Read the current shape catalog in `reference/notifications.md` and the standing rules
   in `SKILL.md` end to end.
2. Decide the exact color-per-state mapping: 🔵 Proposed, 🟠 Implementing, 🟡 Handoff, 🟢
   Implemented, 🔴 Blocked, 🚀 Auto Merge (unchanged, outside the color set) — one color to
   exactly one state, no double duty.
3. Decide where the design-start post's color lands: adopt the 🔵 family (the state it
   opens), or record a different judgment with its reason.
4. Write the resolved catalog as a short, literal-line table or list (old shape → new
   shape) that the implementation ticket can apply mechanically, without re-deciding
   anything.
5. Note every location the implementation ticket must touch, so its scope is bounded by
   this ticket rather than rediscovered: `workaholic:notify`'s `SKILL.md` and
   `reference/notifications.md`, both routine prompt templates in
   `skills/workaholify/routines/`, and the prompt-is-the-ceiling rule's example text.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The resolved catalog assigns exactly one color to each of Proposed / Implementing /
  Handoff / Implemented / Blocked, with 🚀 Auto Merge named as the deliberate exception
  outside the color set
- The design-start post's color is explicitly decided (state-color-of-what-it-opens or an
  alternative), with its reasoning recorded
- Every location the catalog must be applied to is enumerated for the companion
  implementation ticket

**Verification method** — the commands/tests/probes that prove them:

- A human review of this ticket's written catalog against the six required states plus
  the 🚀 exception

**Gate** — what must pass before approval:

- The catalog and the design-start color decision are both written before the companion
  implementation ticket is driven

## Considerations

- This is a design decision, not a mechanical rename — resolve the catalog here, and let
  the implementation ticket be a pure find-and-replace against what this one decides.
- The prior FB `20260807190939` ruling already chose 🔵/🟠/🟡/🟢/🟣/🔴; this ticket's job is
  mostly to confirm that set still holds minus the retired 🟣 slot, and to make the one
  call #330 leaves open (the design-start post's color).
