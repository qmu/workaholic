---
type: Mission
title: Run the loop's own proofs on every turn
slug: run-the-loop-s-own-proofs-on-every-turn
status: active
merge_policy:
created_at: 2026-08-29T12:19:26+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829121658-run-the-loop-s-own-proofs-on-every-turn.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-124120
---

# Run the loop's own proofs on every turn

## Goal

`scripts/e2e/loop-drill.sh` holds 30 `verify-*` drills, one per mechanism this direction
built, most hermetic and many carrying a broken row asserted to fail. None run:
CI executes two and relates to eight by a regex proving a drill *exists*, never that it
*passes* — while the loop merges hourly and the archive gate closes a mission on
arithmetic.

## Experience

A merge breaking a mechanism an earlier turn proved is caught by the loop itself, on that
merge, and the failure names the drill and the mission that shipped it. A drill that has
stopped being able to fail is a failure, not a pass; one needing the server says so by
name. A person is told only when something fails.

## Acceptance

- [ ] One aggregate verb runs the measured hermetic set with no key, network, `gh` or
      `qfs`, emitting `pass`/`fail`/`skipped:<reason>` per drill and exiting non-zero
      only on a real failure, and CI runs it. (#20260829122104-give-the-drill-an-aggregate-verb-with-a-machine-verdict.md)
- [ ] A drill whose breaker no longer breaks is a failure of its own; one needing the
      server is named skipped, never counted green. (#20260829122104-exercise-the-breaker-rows-and-report-a-drill-that-cannot-fail.md)
- [ ] A failing drill names its shipping mission, `/moderate` asks once and is silent on
      green, and a hermetic test fails when an unreachable drill lands. (#20260829122105-pin-the-drill-verdict-path-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-29 — ticket archived — 20260829122104-measure-which-drills-are-hermetic-per-drill.md
