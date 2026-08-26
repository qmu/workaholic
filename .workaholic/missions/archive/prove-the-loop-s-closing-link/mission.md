---
type: Mission
title: Prove the loop's closing link
slug: prove-the-loop-s-closing-link
status: achieved
merge_policy:
created_at: 2026-08-26T02:17:55+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.62
feedback: [20260826021619-prove-the-loop-s-closing-link-make-the-feedback-carry-forward-mechanical-and-reported.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260826-023535
---

# Prove the loop's closing link

## Goal

The loop's fourth link — work `/specificate` emits staying attributable to the direction
that asked for it — is carried by a paragraph. `reference/workflow.md` step 3b tells the run
to read the ask's `feedback:` line by eye; no script parses it, nothing checks the emitted
artifacts carry it, and no report names what was carried. Its failure is invisible: a
forgotten carry leaves `strategy.feedback[] ∩ artifact.feedback[]` empty and
`attributed-work.sh` answers `no_citing_artifacts` — byte-identical to a direction nothing
has answered yet. Make the carry mechanical, reported, and floored.

## Experience

A run that carries refs says which, per emitted artifact; a run that drops one says which
and why. A mission or ticket published from an ask whose refs resolved carries those refs or
the publish seam refuses, exactly as the two-ticket floor already refuses. After that,
`no_citing_artifacts` can only mean *nothing has answered this direction yet* — and that
guarantee is pinned by a test rather than asserted in prose.

## Acceptance

- [x] One script parses an ask's `feedback:` line and returns carried and dropped with a
      reason per drop; step 3b invokes it instead of reading by eye (#20260826021825-read-the-ask-s-feedback-line-through-one-script.md)
- [x] The run report and the pull-request body name each carried and each dropped ref, and
      the publish seam refuses a proposal whose resolved refs are missing from what it emitted (#20260826021825-report-every-carried-and-dropped-feedback-ref.md)
- [x] `no_citing_artifacts` is a provable reading, pinned by a hermetic test and stated in
      the documents that describe the loop (#20260826021825-make-no-citing-artifacts-a-provable-reading.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-26 — ticket archived — 20260826021825-read-the-ask-s-feedback-line-through-one-script.md
- 2026-08-26 — ticket archived — 20260826021825-floor-the-carry-at-the-publish-seam.md
- 2026-08-26 — ticket archived — 20260826021825-report-every-carried-and-dropped-feedback-ref.md
- 2026-08-26 — ticket archived — 20260826021825-make-no-citing-artifacts-a-provable-reading.md
- 2026-08-26 — mission achieved — mission.md
- 2026-08-26 — story reported — work-20260826-023535.md
- 2026-08-26 — run recorded (+0.62h) — cse_01CXYzWiNLZMLNGoaN1K9vAG
