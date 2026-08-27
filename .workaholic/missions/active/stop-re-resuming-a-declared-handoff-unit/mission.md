---
type: Mission
title: Stop re-resuming a declared handoff unit
slug: stop-re-resuming-a-declared-handoff-unit
status: active
merge_policy:
created_at: 2026-08-27T08:22:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260827081849-a-declared-handoff-unit-is-re-resumed-every-tick.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260827-084115
---

# Stop re-resuming a declared handoff unit

## Goal

`verification_handoff:` exists so a unit nothing unattended can finish costs no tick. The
route honours it; the claim oracle never consults it again, so once `/story` opens the pull
request the claim reads `parked_with_pr`, `resumable: true`, and the survey re-offers it
hourly. Measured on PR #647: routed at 02:14 UTC, taken over again at 06:43 for nothing.

## Experience

A claim whose remaining queued work declares `verification_handoff:` gets its own verdict,
`resumable: false`, and appears in no survey's `resumable[]` — and comes back on its own,
nothing stored anywhere, once that declaration no longer holds.

## Acceptance

- [ ] The claim scan reads the declaration, answers its own verdict with `resumable: false`,
      refuses `resume` under that name, and reverts once the declared ticket is driven —
      proved over a hermetic fixture. (#20260827082244-give-a-declared-handoff-its-own-claim-verdict.md)
- [ ] The survey excludes it by name and offers it in no takeover list, and `ok` stays
      reachable while it waits, since a person is what it waits for. (#20260827082244-exclude-a-declared-handoff-from-the-survey-offer.md)
- [ ] The new word is classified in `claims.md`'s *Proofs and judgements* table and named in
      `drive/SKILL.md` §6 and `CLAUDE.md`, with the suite failing on a disagreement. (#20260827082245-classify-the-verdict-and-update-the-documents.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-27 — ticket archived — 20260827082244-reproduce-the-handoff-re-resume-and-pin-it.md
- 2026-08-27 — ticket archived — 20260827082244-read-the-declared-handoff-in-the-claim-scan.md
