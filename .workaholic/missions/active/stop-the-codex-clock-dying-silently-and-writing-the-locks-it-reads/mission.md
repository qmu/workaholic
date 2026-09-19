---
type: Mission
title: Stop the Codex clock dying silently and writing the locks it reads
slug: stop-the-codex-clock-dying-silently-and-writing-the-locks-it-reads
status: active
merge_policy:
created_at: 2026-09-19T11:53:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260919114700-the-codex-loop-pins-its-own-skill-path-and-its-status-surface-writes-the-locks-it-reads.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260919-192006
---

# Stop the Codex clock dying silently and writing the locks it reads

## Goal

A Codex clock that has stopped must be visible as stopped, and the surface a person asks with
must not be the thing that makes a dead loop look alive. Measured in another repository: a
supervisor pinned to a retired plugin version died on 2026-09-07 and nobody saw it for twelve
days, while three `worker-*.lock` files read one minute old because the reader's own `--status`
call had written them.

## Experience

A supervisor launched against a plugin tree that moved either recovers it, as the running loop
already does, or records the stop where the status surface can read it. Asking whether the loop
is alive leaves every lock file byte-identical and takes no lock a dispatch could lose. A clock
that stopped, or that keeps ticking without executing anything, reaches a person instead of
stderr and a file nobody opens.

## Acceptance

- [ ] Reading worker liveness writes nothing and takes no lock, and the drill proves it. (#20260919115510-read-worker-liveness-without-writing-or-locking.md)
- [ ] A startup that cannot read its own instructions recovers the tree or leaves a record. (#20260919115510-recover-or-record-a-retired-plugin-tree-at-startup.md)
- [ ] A stopped or non-executing clock is announced where a person already looks. (#20260919115511-announce-a-codex-clock-that-stopped-or-executed-nothing.md)

## Changelog

- 2026-09-19 — Proposed from issue #1218 (`[FB]`, subject `person:tamurayoshiya`).
