---
type: Mission
title: Correct the release note automation to its intended design
slug: correct-the-release-note-automation-to-its-intended-design
status: active
merge_policy:
created_at: 2026-08-17T11:45:09+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260817114457-release-note-automation-deviates-from-its-intended-per-target-design.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Correct the release note automation to its intended design

## Goal

An hourly release-note writer was asked for; a reader shipped instead. `[Release Status]`
posts a gated line and writes nothing, because `workaholic:ship` §7 refused all three
unit-less writer designs. Issue #472 calls that a deviation and restates the design — per
**target**, drafted from the base, held identically in GitHub Releases and `.workaholic`,
generated daily and updated as the release advances. This mission answers §7's refusals
with that design, or changes it where they still bind.

## Experience

An operator opens any target and finds a current draft: what would ship, how to release it,
what confirmation follows, and whether the AI has done it. Both copies read identically;
the fragmented notification is gone.

## Acceptance

<!-- PROPOSED — a sketch for discussion. Approval replans this to drive-ready. -->

- [ ] Every target has a derived environment mapping and a draft note computed from what is
  merged on the base. (#20260817114537-derive-the-deploy-target-environment-mapping.md)
- [ ] A note carries its confirmation procedure and the AI's completion record, and both
  copies are identical. (#20260817114540-sync-the-github-and-workaholic-note-copies.md)
- [ ] Daily generation replaces the fragmented notification, with each §7 refusal answered
  in writing. (#20260817114541-implement-the-daily-note-generation-cadence.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->

- 2026-08-17 — Proposed from issue #472.
