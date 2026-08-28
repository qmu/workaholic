---
type: Mission
title: Say what the direction could not see before calling it arrived
slug: say-what-the-direction-could-not-see-before-calling-it-arrived
status: active
merge_policy:
created_at: 2026-08-28T01:19:38+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260828011727-say-what-the-direction-could-not-see-before-calling-it-arrived.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260828-014111
---

# Say what the direction could not see before calling it arrived

## Goal

`quiescent` means *everything I could attribute has landed* and renders as *this direction
has arrived*. Measured 2026-08-28: this strategy read `quiescent: true` while four active
missions and ten queued tickets sat unattributed, three of them its own machinery. Make that
blind spot legible and repairable without making the walk guess.

## Experience

`/moderate` never invites the operator to close a direction over work nobody attributed.
An `arrived` question names every active mission and queued ticket belonging to no
direction. A residue we could not read claims no arrival. And an operator who rules that an
unattributed mission answers a direction announces it, and the loop carries that onto a
pull request instead of editing `main` by hand.

## Acceptance

- [x] The residue is readable by name through one pure reader and rides every survey row,
      eligible and refused alike, with no gate and no sort moved. (#20260828012042-read-what-no-direction-claims.md)
- [ ] No arrival is claimed over an unreadable residue, and the arrival question and the
      run report both name the residue by slug. (#20260828012044-refuse-an-arrival-over-a-tree-we-could-not-see.md)
- [ ] An operator's attribution ruling reaches a pull request through the loop, adding no
      field and reviving no `strategy:` relation. (#20260828012047-carry-an-operator-attribution-through-the-loop.md)

## Changelog


- 2026-08-28 — ticket archived — 20260828012026-reproduce-the-false-arrival-and-pin-it.md
- 2026-08-28 — ticket archived — 20260828012042-read-what-no-direction-claims.md
