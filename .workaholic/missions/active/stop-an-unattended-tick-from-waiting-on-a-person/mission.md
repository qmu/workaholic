---
type: Mission
title: Stop an unattended tick from waiting on a person
slug: stop-an-unattended-tick-from-waiting-on-a-person
status: active
merge_policy:
created_at: 2026-08-31T11:35:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831113507-an-unattended-tick-can-be-stopped-forever-by-a-permission-prompt.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260831-140035
---

# Stop an unattended tick from waiting on a person

## Goal

Three consecutive ticks sat at `requires_action`, each waiting on a permission prompt
raised by a **read** of a plugin script — `sed -n …p` and `grep -n`, neither of which
writes. A routine has nobody to answer one, so the run waits forever and never reaches
`persist-log`: the record that would show it stopped is the one the stop prevents.

## Scope

How the tick reads its own scripts, when the log reaches the base, and what notices a
tick that opened and never closed. Not the steps, keys, caps or holds.

## Experience

An hourly tick never stops waiting for a person, because it never reaches for a tool that
can ask one; and a tick that stops for another reason leaves a record on the base that
the next tick reads, so a blocked hour and a quiet hour are never one absence.

## Acceptance

- [x] The tick reads a plugin script with a read tool, never through a Bash text
      pipeline, and the rule is stated where the shell rules live. (#20260831113558-read-a-plugin-script-without-a-bash-text-pipeline.md)
- [ ] A tick that dies mid-run leaves its opening on the base, and the next tick names
      it — a tick that opened and never closed is a finding, not a silence. (#20260831113559-notice-a-tick-that-opened-and-never-closed.md)
- [ ] Proved offline by a drill with a breaker row, in the register. (#20260831113559-drill-the-blocked-tick-reading-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-31 — ticket archived — 20260831113558-read-a-plugin-script-without-a-bash-text-pipeline.md
- 2026-08-31 — ticket archived — 20260831113900-state-that-a-run-with-no-human-never-blocks-on-a-prompt.md
- 2026-08-31 — ticket archived — 20260831113900-establish-where-the-no-prompt-policy-is-configured.md
