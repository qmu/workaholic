---
type: Mission
title: See a frozen runner and give back its slot
slug: see-a-frozen-runner-and-give-back-its-slot
status: active
merge_policy:
created_at: 2026-09-06T18:51:16+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260906184737-a-frozen-subagent-reports-running-forever-and-holds-a-fan-out-slot.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260906-190443
---

# See a frozen runner and give back its slot

## Goal

A subagent blocked on a permission dialog it cannot answer reports `running` for as long as
nobody looks. Measured 2026-09-06: `implement-10` frozen 38m29s, nine `ListAgents` calls
reporting it healthy. The tick's reaping stops only `idle`, so it is never stopped, never
records `loop-finish-<name>`, and is still counted by the fan-out — a 3-runner loop becomes a
2-runner one. The harness's own two repairs are out of scope; the third and the trigger are ours.

## Experience

The tick tells a `running` runner that is advancing from one that stopped, off evidence this
repository already owns; a non-advancing runner stops holding a fan-out slot and is named in the
tick report; and the loop never composes the plugin-cache path that froze this one. A reading
that cannot be made is named by its own reason and holds nothing.

## Acceptance

- [x] A reader answers, per running loop subagent, whether it is still advancing, refusing by
      name rather than guessing. (#20260906185501-read-whether-a-running-loop-subagent-is-still-advancing.md)
- [x] A non-advancing runner no longer consumes a fan-out slot, and the tick report says so. (#20260906185501-stop-counting-a-non-advancing-runner-toward-the-fan-out.md)
- [x] The loop's own script calls reach the checkout, never the plugin cache path. (#20260906185501-keep-the-loop-s-own-script-calls-off-the-plugin-cache-path.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-06 — ticket archived — 20260906185501-read-whether-a-running-loop-subagent-is-still-advancing.md
- 2026-09-06 — ticket archived — 20260906185501-stop-counting-a-non-advancing-runner-toward-the-fan-out.md
- 2026-09-06 — ticket archived — 20260906185501-keep-the-loop-s-own-script-calls-off-the-plugin-cache-path.md
