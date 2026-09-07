---
type: Feedback
title: tick-progress.sh resolves the skills directory against the consuming repository
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-06T11:08:42+09:00
author: a@qmu.jp
supersedes: 
---

# tick-progress.sh resolves the skills directory against the consuming repository

Source: https://github.com/qmu/workaholic/issues/1005

`tick-progress.sh` sets `S="$ROOT/plugins/workaholic/skills"`, where `$ROOT` is the repository
the loop is running in (`git rev-parse --show-toplevel`). That path exists only in the plugin's
own repository. In any consuming project the two readers it calls —
`mission/scripts/progress.sh` and `mission/scripts/queue-size.sh` — are never found, each falls
back to `{}`, and every mission row comes out as
`{"slug": "...", "checked": null, "total": null, "todo": null, "archived": null, "draining": false}`.

Measured on a consuming project with four active missions and seventeen queued tickets.
Calling `progress.sh` directly on one of those mission files, by its real path, answers
`{"checked": 0, "total": 3, "unlinked": 0}` — so the readers are fine and only the path is wrong.

Two consequences, and the second is the one that matters. The failure is silent and is
rendered as a healthy answer: `gating` is incremented from `.todo`, which is null on every
row, so `gating_missions` comes out `0` and the tick prints `propose_gate: "open"` on a
project holding seventeen queued tickets — the input that should have answered `work_waiting`.
That is the shape the tick's own rules forbid by name: a degraded read must never be rendered
as a healthy one. Here it does not merely hide the reading, it flips the propose loop's
deferral to the opposite of the truth. And `draining` is derived the same way —
`((.[1].archive // 0) > 0)` over a null — so every mission reads `draining: false` whether or
not anything has landed against it, which is the one fact the field exists to carry.

The two things asked for:

1. Resolve the skills directory from the script's own location, the way the neighbouring loop
   scripts do, rather than from the caller's repository root.
2. When a reader answers `{}`, say so with its own word rather than letting `null` become `0`
   inside `gating` — a gate computed from a failed read is not a gate.

Note beside the record: this repository already carries `check-deps/scripts/plugin-src.sh`,
whose whole job is to resolve the plugin tree on the machine rather than from the caller's
repository root, which is the seam item 1 asks for.

This record is knowledge, not an ask the loop may act on: its `subject:` names an observer AI,
not a person, and its subject matter is the loop's own apparatus, so `/specificate` refused it
`self_authored` under `rules/workaholic.md`, *What May Originate a Mission*. The operator rules
on it.
