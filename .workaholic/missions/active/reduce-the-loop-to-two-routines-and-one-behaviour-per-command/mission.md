---
type: Mission
title: Reduce the loop to two routines and one behaviour per command
slug: reduce-the-loop-to-two-routines-and-one-behaviour-per-command
status: active
merge_policy:
created_at: 2026-08-06T18:36:08+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260806183556-two-routines-one-behaviour-per-command.md, 20260806184651-ownership-is-a-field-not-a-directory.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260806-185233
---

# Reduce the loop to two routines and one behaviour per command

## Goal

Every field a developer sets by hand multiplies by the number of projects, so the
loop's shape is set by what a person can maintain across a fleet, not by what the
plugin can express. Reduce it to **two routines per developer** with a four-line
instruction each, and make every command take arguments and do exactly one thing —
a command whose behaviour forks on a first word is two commands wearing one name.

## Experience

A developer wiring a new project creates **Propose** and **Implement**, pastes four
lines into each, sets one trigger, and is done. An assigned issue produces a
`[Proposal]` pull request whose body carries the Slack thread to reply in; merging it
starts the implementation, which replies in that same thread. No third routine, no
subcommands anywhere, and `/drive` is again the interactive command it used to be.

## Acceptance

<!-- PROPOSED criteria — replan sharpens them. -->

- [x] `/implement` is the unattended executor and `/drive` is interactive again;
      `[Consent]` is retired, leaving exactly two routine templates. (#20260806183638-split-drive-into-an-interactive-drive-and-an-unattended-implement.md)
- [ ] `/propose` and `/implement` are routine-shaped: `[Proposal]`-prefixed pull
      request titles, and the notification target carried in the pull request body. (#20260806183638-shape-propose-and-implement-for-the-routine-chain.md)
- [ ] No command in the plugin takes a subcommand; each takes arguments and has one
      behaviour, with the setup sheets and docs matching. (#20260806183638-abolish-subcommands-across-every-command.md)
- [x] "Who" rides the artifacts rather than each container's git config: ownership is a
      field, and a runner with no identity reads the queue instead of reporting it empty. (#20260806184521-carry-ownership-as-a-field-not-as-a-directory.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-06 — ticket archived — 20260806183638-split-drive-into-an-interactive-drive-and-an-unattended-implement.md
- 2026-08-06 — ticket archived — 20260806184521-carry-ownership-as-a-field-not-as-a-directory.md
