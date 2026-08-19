---
type: Mission
title: Rename the routine pair and add a per-user updater
slug: rename-the-routine-pair-and-add-a-per-user-updater
status: active
merge_policy:
created_at: 2026-08-19T05:26:06+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260819052547-routine-registration-should-be-three-per-repository-routines-plus-one-per-user-updater.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Rename the routine pair and add a per-user updater

## Goal

Issue #526 asks for a routine set of three per-repository routines plus one
per-user one: `[Propose]` becomes `[Specificate]`, `[Housekeep]` becomes
`[Propose]` — a swap, not two independent renames — `[Implement]` is untouched,
and a new per-user `[Workaholic]` checks this repository hourly for routine
definition changes and converges that user's routines across their repositories.

## Experience

An operator setting up a repository gets the renamed pair without a duplicate
routine firing beside the old one, and one `[Workaholic]` routine for the account
rather than one per repository. Where the API cannot carry an act, the run says so
by name instead of reporting success.

## Acceptance

- [ ] The routine formerly named `[Propose]` is `[Specificate]`, carrying the
  `renamed_from:` cutover instruction into both the report and the setup sheet. (#20260819052637-rename-the-propose-routine-to-specificate.md)
- [ ] The routine formerly named `[Housekeep]` is `[Propose]`, landing only after
  the first rename has freed that name. (#20260819052637-rename-the-housekeep-routine-to-propose.md)
- [ ] A per-user `[Workaholic]` routine exists with a scope of its own, or the run
  reports by name what the transport could not do. (#20260819052637-add-the-per-user-workaholic-updater-routine.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
