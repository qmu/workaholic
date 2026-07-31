---
type: Mission
title: Make the branch story say less when there is less to say
slug: make-the-branch-story-say-less-when-there-is-less-to-say
status: draft
merge_policy:
created_at: 2026-07-31T17:04:02+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260731170201-update-the-pull-request-story-format-to-say-less-when-there-is-less-to-say.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Make the branch story say less when there is less to say

## Goal

The story template offers a section for everything and the generator fills every one, so a small
change still produces a long, dense story. Requested: fold Historical Analysis into Motivation,
list only concerns above `low`, leave Successful Development Patterns empty unless a real pattern
was found, and flatten `8-1/8-2/8-3` into one list included only when there is something to say.
Measured across the eight most recent stories: 20 of 35 concerns are `low`, and section 7 is
populated in all eight though "None" is already permitted.

## Experience

A story reports what the branch actually produced and stops: no Historical Analysis heading, no
low-severity concerns, no invented patterns, no empty release sub-sections. A branch with little to
say produces a short story rather than a padded one — while `/ship`'s concern extraction still
receives every concern, including the low-severity ones the story no longer prints.

## Acceptance

<!-- PROPOSED criteria - a sketch for discussion, not a plan. -->

- [ ] The story template in `report/SKILL.md` and `review-sections/SKILL.md` carries the four
      changes: §5 folded into §2, concerns filtered above `low`, §7 empty by default, §8 one flat
      list emitted only when non-empty
- [ ] `ship`'s `extract-deferred-concerns.sh` still records every concern the branch found at every
      severity — the decision on where it reads them from is made and written down
- [ ] The next story generated after the change is measurably shorter than the recent 84-179 line
      band without losing any concern from the feedback stream

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->

- 2026-07-31: Proposed from issue #125 via
  `20260731170201-update-the-pull-request-story-format-to-say-less-when-there-is-less-to-say.md`
