---
type: Mission
title: Make a verification handoff a probe re-run at claim time
slug: make-a-verification-handoff-a-probe-re-run-at-claim-time
status: active
merge_policy:
created_at: 2026-09-03T13:38:13+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260903133636-a-verification-handoff-must-name-a-probe-that-runs-at-claim-time-not-a-sentence-written-once.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-135930
---

# Make a verification handoff a probe re-run at claim time

## Goal

A `verification_handoff` is written once and never measured again, so a blocker true at creation
stays true forever and the work behind it stops being attempted. Measured in one session: four
pull requests parked, three declarations false when probed — a key already on disk, a secret-put
CI already ran, an entrance whose tokens were held. Make it a probe whose exit status decides,
run at claim time.

## Experience

A handoff is a command, not a sentence. The run probes it when it claims the unit: a clean probe
is not a handoff and the work proceeds; a blocking one hands the unit over with its own output as
the reason. A declaration nobody can re-probe is named, and no run carries another unit's
declaration forward as a premise.

## Acceptance

- [ ] A declared handoff carries a probe read by one reader, and a prose-only one reads as unmeasured. (#20260903133932-name-a-declaration-nobody-can-re-probe-as-unmeasured.md)
- [ ] The probe runs at claim time: clean drops the handoff, blocking hands the unit over quoting its output. (#20260903133932-make-a-failing-probe-s-own-output-the-handoff-reason.md)
- [ ] Standing declarations are re-probed each tick, and no run inherits a handoff it did not derive. (#20260903133932-stop-a-handoff-sentence-spreading-beyond-its-own-unit.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-03 — ticket archived — 20260903133932-declare-a-verification-handoff-as-a-probe-command.md
- 2026-09-03 — ticket archived — 20260903133932-read-a-declared-probe-through-one-reader.md
- 2026-09-03 — ticket archived — 20260903133932-run-the-declared-probe-when-the-unit-is-claimed.md
- 2026-09-03 — ticket archived — 20260903133932-drop-a-handoff-whose-probe-comes-back-clean.md
