---
type: Mission
title: Put the loop's standing rulings on one pull request
slug: put-the-loop-s-standing-rulings-on-one-pull-request
status: active
merge_policy:
created_at: 2026-08-28T21:19:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260828211740-put-the-loop-s-standing-rulings-on-one-pull-request.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260828-214118
---

# Put the loop's standing rulings on one pull request

## Goal

Hand the operator a ruling the loop cannot make itself as a pull request carrying
the proposed answer and its evidence, instead of an hourly question. Two stand
today: which direction an unattributed mission answers, and which account an
unmapped address belongs to.

## Experience

The operator opens one pull request and merges it, and the standing rulings are
settled. Each arrives as a proposed diff with its evidence beside it, not as an
hourly question naming a repair to perform by hand on `main`. Merging is the
ruling; closing is the refusal; a ruling the loop could not judge is still a
question and says why. Nothing is proposed twice while one is open, and a degraded
read proposes nothing.

## Acceptance

- [x] The standing rulings are readable in one place, the run supplies the judgement
      per candidate, and an unjudged candidate is never written. (#20260828212022-name-the-standing-rulings-in-one-place.md)
- [x] A judged ruling lands as a diff through the writer that already owns it, on
      one pull request the seam itself refuses to auto-merge. (#20260828212022-draft-the-attribution-rulings-through-their-writer.md)
- [x] The tick drafts at most one ruling pull request at a time, suppresses only the
      question its own diff carries, and the whole path is drilled with no network. (#20260828212022-give-the-tick-the-standing-rulings-step.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-28 — ticket archived — 20260828212022-name-the-standing-rulings-in-one-place.md
- 2026-08-28 — ticket archived — 20260828212022-let-the-run-supply-the-judgement-per-candidate.md
- 2026-08-28 — ticket archived — 20260828212022-refuse-to-auto-merge-a-ruling-at-the-seam.md
- 2026-08-28 — ticket archived — 20260828212022-draft-the-attribution-rulings-through-their-writer.md
- 2026-08-29 — ticket archived — 20260828212022-draft-the-mapping-ruling-beside-them.md
- 2026-08-29 — ticket archived — 20260828212022-give-the-tick-the-standing-rulings-step.md
