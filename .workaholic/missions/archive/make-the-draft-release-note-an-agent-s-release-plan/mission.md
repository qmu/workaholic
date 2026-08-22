---
type: Mission
title: Make the draft release note an agent's release plan
slug: make-the-draft-release-note-an-agent-s-release-plan
status: achieved
merge_policy:
created_at: 2026-08-18T20:20:13+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 1.5
feedback: [20260818201731-the-draft-release-note-must-be-an-agent-s-arranged-release-plan-not-a-rendered-commit-list.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260818-205051
---

# Make the draft release note an agent's release plan

## Goal

A deterministic renderer ships where an agent's planning judgment was asked for.
`draft-release-note.sh` lists one clamped line per merge since the latest tag, and
its own header names byte-identical output as the property the cadence rests on.
Nothing decides what ships together, in what order, or at what risk. The 2026-08-18
move of the writer to CI stands — this changes who decides the content.

## Experience

<!-- PROPOSED — a sketch for discussion. Approval replans this to drive-ready. -->

An operator opens a target's draft and reads a release plan an agent keeps
re-arranging as merges land: what ships together, in what order, what is risky
beside what — with every merge's substance present, not just the story-bearing
ones. After the release, the confirmation and report append to that same note, so
one document carries plan → release → verification.

## Acceptance

<!-- PROPOSED criteria — a sketch for discussion. Approval replans this. -->

- [x] A target's draft note is an agent-authored release plan, not a byte-identical
  render of the merge range. (#20260818202056-run-the-release-planning-judgment-and-reach-ci.md)
- [x] Every merge contributes its substance, including the story-less proposal
  merges that are this repository's most frequent kind. (#20260818202056-recover-the-substance-of-story-less-merges.md)
- [x] The post-release confirmation and report append to the note that planned the
  release. (#20260818202056-append-the-release-confirmation-to-its-own-plan.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-18 — ticket archived — 20260818202056-give-the-release-note-a-plan-seam-over-the-renderer.md
- 2026-08-18 — ticket archived — 20260818202056-recover-the-substance-of-story-less-merges.md
- 2026-08-18 — ticket archived — 20260818202056-run-the-release-planning-judgment-and-reach-ci.md
- 2026-08-18 — ticket archived — 20260818202056-append-the-release-confirmation-to-its-own-plan.md
- 2026-08-18 — run recorded (+1.5h) — implement-20260818-2050
- 2026-08-22 — mission achieved — mission.md
