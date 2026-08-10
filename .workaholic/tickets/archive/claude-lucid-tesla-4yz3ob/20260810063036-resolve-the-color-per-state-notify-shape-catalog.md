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
distinction must stay visually distinct on its own). This design-only ticket resolves the
exact catalog — including where the design-start (currently 📐 Designing) post's color
lands: the issue suggests it should adopt the state color of what it opens (the 🔵
family), or the design may judge otherwise. It supersedes the un-implemented six-color
ruling in FB `20260807190939`. **Whether the retired 🟣 human-merge shape (erased per
qmu/workaholic#317) has a place in this scheme is an open question for this ticket, not
foreclosed** — developer note received while this was being proposed: purple circle
should not be excluded from this direction, so re-evaluate whether a human-merge shape
belongs in the resolved catalog rather than treating its removal as settled. Line wording
is unchanged (issue #300's two-line format) — only the leading emoji and state words
change. The companion implementation ticket applies whatever this one resolves.

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
  already picked (🔵/🟠/🟡/🟢/🟣/🔴) — do not assume the 🟣 slot is moot; that is exactly
  what this ticket must re-decide
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
- The prior FB `20260807190939` ruling already chose 🔵/🟠/🟡/🟢/🟣/🔴. Issue #330's own
  text argues the 🟣 human-merge shape stays erased (qmu/workaholic#317) and out of scope,
  but a developer note received while this proposal was being drafted says the opposite —
  purple circle should not be excluded from this direction. Treat that as live, current
  guidance and resolve the 🟣 question deliberately rather than defaulting to either
  position; record the reasoning either way.

## Resolved Catalog

One color per exactly one state, applied mechanically by the companion ticket:

| State | Old shape | New shape | Change |
| --- | --- | --- | --- |
| Designing (`/propose` start) | `📐 Designing` | `📐 Designing` | **unchanged** |
| Proposed (`/propose` finish) | `📐 Proposed` | `🔵 Proposed` | recolored |
| Implementing (`/implement` start) | `🛠️ Implementing` | `🟠 Implementing` | recolored |
| Implemented (`/implement` ordinary finish) | `🛠️ Implemented` | `🟢 Implemented` | recolored |
| Handoff | `🟡 Handoff` | `🟡 Handoff` | unchanged |
| Blocked | `🔴 drive blocked` | `🔴 Blocked` | label aligned to state name; color unchanged |
| Auto Merge | `🚀 Auto Merge` | `🚀 Auto Merge` | unchanged — deliberately outside the color set |

Line wording (issue #300's two-line format) is otherwise untouched; only the leading emoji
and, for Blocked, the state word change.

**Design-start (`📐 Designing`) color — resolved to leave it unchanged, not the suggested
🔵 family.** The double-duty this mission exists to fix was two glyphs each covering two
states (`📐` for Designing *and* Proposed; `🛠️` for Implementing *and* Implemented). Moving
Proposed off `📐` onto its own `🔵` already makes `📐` unique to Designing — no state now
shares it. Recoloring Designing into the `🔵` family as the issue's fallback suggested
would put two states (Designing, Proposed) back in the same color family, which is exactly
what the Experience section's "no two states sharing a color" bar forbids in spirit even if
the two used distinguishable icons within the family. `📐` is not a member of the colored-
circle set (`🔴`/`🟠`/`🟡`/`🟢`/`🔵`) at all, so leaving it as-is costs nothing and keeps
every state's signal unambiguous — the simpler alternative the issue explicitly allowed for
("or an alternative the design ticket judges"), and the one `workaholic:design` /
`interaction-design-standard`'s consistency bar favors: don't introduce a new distinction
(diamond vs. circle blue) when removing the actual collision (the shared `📐`) already
resolves the ambiguity.

**The 🟣 human-merge question — resolved as reserved, not reinstated.** The developer's
live note ("purple circle should not be excluded from this direction") is honored by *not*
assigning `🟣` to any state in this catalog and *not* reintroducing the automated
human-merge announcement `[Consent]`'s retirement removed (qmu/workaholic#317) — restoring
that posting behavior is a functional decision (detecting a human merge, avoiding a
duplicate of `[Consent]`'s own retired announcement, deciding which thread and whose
mention) well beyond this mission's scope of recoloring existing shapes, and the mission's
own Acceptance only asks for the catalog above to be applied. `🟣` stays unused and
unassigned in this catalog precisely so a later, dedicated ticket can revisit a human-merge
shape without inheriting a color conflict from this one. This is a deliberate reservation,
not exclusion.

**Locations the companion ticket must touch** (grep confirms these are the only
current, non-historical occurrences of the old shapes):

- `plugins/workaholic/skills/notify/SKILL.md`
- `plugins/workaholic/skills/notify/reference/notifications.md`
- `plugins/workaholic/skills/workaholify/routines/fb.md`
- `plugins/workaholic/skills/workaholify/routines/implement.md`
- `outputs/workflows/` — confirmed to carry no copy of these shapes (the `notify` and
  `workaholify` skills are Claude-Code-only and are not part of that bundle); rebuild
  anyway as the standard verification step.
- `CLAUDE.md` — confirmed to carry no occurrence of the current double-duty shapes; its one
  emoji-shape passage (§ *Under `/implement`, a unit announces...*) already describes an
  earlier, pre-P10 wording (`🟠 start`, `🟢 merge requested`) and is tracked by the
  separate, already-backlogged ticket `20260809085953-reconcile-stale-notification-shape-
  references-post-p10.md` — out of scope here, left untouched.

Historical/retired-shape mentions (e.g. `🟢 Merge Requested`, `🟠 drive started`, `🟣
Merged by`) describing what a past shape *was* stay as written — only the current, live
shape tokens change.

## Final Report

Development completed as planned: resolved the color-per-state catalog above, including
the Designing-color and 🟣 open questions the mission left for this ticket.
