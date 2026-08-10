---
type: Story
branch: claude/lucid-tesla-4yz3ob
tickets_completed: 2
mission: [color-code-the-notify-post-shapes-by-state]
tickets: [20260810063036-resolve-the-color-per-state-notify-shape-catalog.md, 20260810063039-apply-the-color-per-state-notify-shape-catalog.md]
---

## 1. Overview

Resolved and applied a color-per-state catalog for `workaholic:notify`'s Slack post
shapes, ending the double duty where 📐 and 🛠️ each covered two states. A developer
scanning a `dev-<repo>` thread now identifies a unit's state from its emoji alone.

**Highlights:**

1. Catalog: 🔵 Proposed, 🟠 Implementing, 🟢 Implemented, 🟡 Handoff, 🔴 Blocked, 🚀 Auto
   Merge kept outside the color set
2. 📐 Designing stays unchanged — moving Proposed off it already removes the collision
3. 🟣 reserved, not reinstated, so a later human-merge ticket inherits no conflict

## 2. Motivation

Issue qmu/workaholic#330 reported that the catalog reused one glyph per two states, so a
developer could not tell a phase's start from its finish by emoji alone — the exact
signal the threaded posts exist to carry for an absent operator. The mission split the
work: a design ticket picked the mapping and resolved two open questions (the
design-start color, and whether the retired 🟣 human-merge shape has a place), so the
mechanical ticket could be a pure find-and-replace. This supersedes the un-implemented
six-color ruling in FB `20260807190939` and completes the P10 (2026-08-07) reconciliation
that settled the post wording while leaving the glyphs sharing duty.

## 3. Changes

### 3-1. Resolve the color-per-state notify shape catalog ([b87d562](https://github.com/qmu/workaholic/commit/b87d562))

Resolved the mapping and the two open questions: Designing keeps 📐 rather than the
suggested 🔵 family, and 🟣 stays reserved and unassigned.

### 3-2. Apply the color-per-state notify shape catalog ([551b52d](https://github.com/qmu/workaholic/commit/551b52d))

Applied the catalog across `notify/SKILL.md`, `reference/notifications.md`, and both
routine templates; renamed `🔴 drive blocked` to `🔴 Blocked`; fixed two shape assertions
in `scripts/test-workflow-scripts.mjs` the recolor broke.

## 4. Outcome

- Every shape maps one color to exactly one state, 🚀 Auto Merge named as the exception
- Repo-wide grep for the retired shapes returns zero hits; test suite green (2467/0)
- Mission `color-code-the-notify-post-shapes-by-state` reached 2/2 acceptance

## 5. Concerns

### CLAUDE.md still names a retired shape for the finish post

- **Severity:** low
- **Description:** CLAUDE.md's `/implement` passage still says `🟢 merge requested` (a
  pre-P10 name), now coincidentally the right color (see [551b52d](https://github.com/qmu/workaholic/commit/551b52d))
- **How to Fix:** Already scoped to backlogged ticket `20260809085953-reconcile-stale-notification-shape-references-post-p10.md`

## 6. Successful Development Patterns

- A design ticket ending with a grep-verified list of every location to touch bounded the
  mechanical ticket's scope instead of letting it rediscover targets mid-edit
- Recording a *negative* location (confirmed absent) saves the next reader re-proving it

## 7. Notes

A third commit, `515fdd9`, is untied to either ticket: it records a feedback item
capturing the developer's live correction of an `/implement` run that hard-stopped on
`unbound_in_claude_session` instead of continuing directly.
