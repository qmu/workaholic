---
type: Mission
title: Keep the closing link readable as the corpus grows
slug: keep-the-closing-link-readable-as-the-corpus-grows
status: active
merge_policy:
created_at: 2026-08-29T07:20:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829071715-keep-the-closing-link-readable-as-the-corpus-grows.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-074143
---

# Keep the closing link readable as the corpus grows

## Goal

`attributed-work.sh`'s `xargs grep` prefilter discards what earlier batches found when
one batch matches nothing, so the link goes silent once the corpus passes a command
buffer. Measured 2026-08-29: 25 citations dropped, `no_citing_artifacts` for a
direction with 25 citing missions. Repair the walk; name one that did not complete.

## Experience

The attribution reader answers the same for a corpus of 100 artifacts and one of 10,000.
A direction whose work is landing reads as answered; `no_citing_artifacts` means
*nothing has answered this direction yet* and nothing else; and a walk the reader could
not complete is named as degraded at every consumer rather than rendered as an honest
zero.

## Acceptance

- [ ] A corpus past the batching boundary attributes every citing artifact, pinned by a
      hermetic test that fails against today's script. (#20260829072045-stop-the-prefilter-discarding-what-it-found.md)
- [ ] A walk that could not read the corpus reports its own reason and null counts, and
      `no_citing_artifacts` is emitted only when the walk completed. (#20260829072045-say-no-citing-artifacts-only-when-the-walk-completed.md)
- [ ] Every reading composed on the walk — survey rows, residue, digest, run reports —
      carries the degradation instead of deriving a verdict from it. (#20260829072045-name-a-degraded-direction-reading-in-the-run-reports.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
