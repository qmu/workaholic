---
type: Mission
title: Tell a merged claim from a live one at both grains
slug: tell-a-merged-claim-from-a-live-one-at-both-grains
status: active
merge_policy:
created_at: 2026-08-26T11:31:32+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260826113034-tell-a-merged-claim-from-a-live-one-at-both-grains.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260826-122328
---

# Tell a merged claim from a live one at both grains

## Goal

`claims_superseded` returns `false` for any claim stamping a non-ticket path, so every
**mission** claim is out of scope by construction. A squash merge leaves no branch commit
on the base, so `base..ref` stays positive and such a claim is claimed forever. Measured
today: three of five claims head pull requests #521, #537 and #546, all merged, all
mission units — one offered `resumable: true` five days after its own PR merged.

## Experience

However a claim's work reached the base — merge commit, squash, rebase, or a recovery
onto another branch — the oracle says so, at the mission grain as well as the batch
grain. Such a claim is never resumed and never becomes a question, and the mission
behind it is re-surveyable. Nothing deletes a branch or closes a pull request.

## Acceptance

- [x] A claim whose work is on the base reads as finished whatever its grain; the three
      merged units measured today are no longer stale. (#20260826113204-answer-superseded-for-a-mission-claim.md)
- [x] No question and no resumption offer names a claim whose pull request is merged,
      and the mission behind one is re-surveyable. (#20260826113204-never-offer-a-merged-claim-for-resumption.md)
- [x] A reading that cannot be made names the claim and the reason, and that claim keeps
      exactly today's verdict. (#20260826113204-make-the-oracle-degrade-by-name-not-by-guess.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-26 — ticket archived — 20260826113204-pin-the-merged-claim-shape-with-a-fixture.md
- 2026-08-26 — ticket archived — 20260826113204-read-whether-a-claim-s-work-reached-the-base.md
- 2026-08-26 — ticket archived — 20260826113204-make-the-oracle-degrade-by-name-not-by-guess.md
- 2026-08-26 — ticket archived — 20260826113204-answer-superseded-for-a-mission-claim.md
- 2026-08-26 — ticket archived — 20260826113204-never-offer-a-merged-claim-for-resumption.md
