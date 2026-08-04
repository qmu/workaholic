---
type: Mission
title: Make the branch story measurably shorter
slug: make-the-branch-story-measurably-shorter
status: active
merge_policy: 
created_at: 2026-08-04T17:00:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
tickets: []
stories: []
gate_type: 
gate_target: 
gate_assert: 
carried_from: make-the-branch-story-concise-by-default
---

# Make the branch story measurably shorter

## Goal

The predecessor made the four structural changes it set out to make — Historical
Analysis folded into Motivation, `low` concerns dropped from the PR body, Patterns
left empty unless one was found, 8-1/8-2/8-3 flattened — and stories got **longer**
anyway: mean 127 lines before (2026-08-01, eight stories) against 164 after
(2026-08-03〜04, ten stories), a 29% increase measured 2026-08-04. Structural edits
to the template were the wrong lever, or were outweighed by something else the
generator does. This mission finds the actual cause and fixes it.

## Experience

A story for a small branch reads short. The writer stops when it has said what
happened rather than filling each heading to the length the template implies, so
length tracks the size of the change instead of the number of sections.

Concretely, and checkably: the mean line count of stories written after this
mission is below the 127-line pre-change baseline, and no section is padded to
look complete — an empty Concerns section is one line, not a paragraph explaining
that there were no concerns.

The cause is named before it is fixed. The predecessor's four edits are on `main`
and did not produce the outcome, so this mission's first act is to measure which
sections actually carry the added lines, not to make a fifth structural edit on
the same assumption.

## Acceptance

- [ ] The sections that carry the growth are measured and named, against the same before/after story sets (#20260804201653-measure-which-story-sections-carry-the-growth.md)
- [ ] A story written after the change is shorter than the same branch's story (#20260804201653-fix-the-measured-cause-and-verify-a-shorter-story.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
