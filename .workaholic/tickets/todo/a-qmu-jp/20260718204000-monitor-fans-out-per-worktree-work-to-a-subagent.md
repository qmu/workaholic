---
type: enhancement
layer: [Domain]
effort:
created_at: 2026-07-18T20:40:00+09:00
author: a@qmu.jp
depends_on: []
mission:
---

# /monitor fans out per-worktree work to a subagent per worktree, not the main agent serially

## Overview

Filed from a downstream project after a live `/monitor` run. The command's own contract
(`skills/monitor/SKILL.md` §2 Fan-out) says to spawn **one `general-purpose` leaf per confirmed
mission**, each working inside its own `.worktrees/<slug>/` — the main agent staying a
**non-blocking dispatcher** that "never implements inline, never edits inside a mission worktree".

In practice, when the pre-flight leaves missions that first need a **replan** to become
drive-ready (unauthorized missions, thin `0/0` missions, missions whose plan grew), all of that
replan-and-bookkeeping work ran **in the main agent, one worktree at a time**:

- reading each mission and its tickets,
- emitting the delta ticket set,
- writing the `## Experience`/`## Goal`/`## Scope` sections, linking acceptance items,
- appending changelog lines, stamping `drive_authorized`,
- committing inside each worktree.

Each of those is per-worktree work with no cross-worktree dependency, yet it was serialized in the
one main agent instead of fanned out. Two costs: (1) independent worktrees that could progress in
parallel wait behind each other, and (2) file edits and commits land **in the main agent inside a
mission worktree** — exactly what §2 says the dispatcher must not do (the "never edits inside a
mission worktree" rule is written for the *drive* phase, but the replan phase violates its spirit).

The result is a `/monitor` that behaves like a serial driver with a fan-out step bolted on, rather
than a dispatcher whose per-worktree work — replan included — is owned by that worktree's own leaf.

## Desired behavior

`/monitor` fans out **one subagent per worktree for the whole of that worktree's work**, replan
included — not only the final drive:

- When a mission needs a replan to become drive-ready, the per-worktree leaf owns emitting its
  tickets, writing its body sections, stamping authorization, and committing — inside its own
  worktree. The main agent does not perform those edits or commits itself.
- The main agent keeps exactly the two things a leaf cannot do: **all `AskUserQuestion`
  interaction** (pre-flight confirmation, replan design rulings, escalation prompts — one-level
  fan-out means leaves cannot prompt) and the **non-blocking dispatch/loop/report** role.
- The division is clean: decisions the developer must make stay in the main agent as prompts;
  every file edit, ticket write, and commit for a worktree happens in that worktree's leaf.

Concretely, the boundary the command already draws for the drive phase ("interpret, lightly
investigate, and direct — never implement inline, never edit inside a mission worktree") should
extend to the **replan phase** too: the main agent gathers the developer's rulings via prompts,
then hands each worktree's replan-and-drive to a leaf, rather than doing the replan bookkeeping in
the main agent and only fanning out the drive.

## Policies

- `workaholic:implementation` / one-level fan-out — subagents cannot nest `Task` and cannot call
  `AskUserQuestion`; the main agent owns interaction, leaves own the per-worktree work. The split
  should hold for the replan phase, not just the drive phase.
- `workaholic:operation` — a monitor run is a long, parallel, mostly-unattended operation; keeping
  the main agent non-blocking (never freezing on the slowest worktree) is the whole point of the
  dispatcher role, and serial in-main-agent replan defeats it.

## Quality Gate

1. `skills/monitor/SKILL.md` §2 (or a new pre-drive section) states that a mission needing a
   replan is handled by a **per-worktree leaf**, with the main agent restricted to the developer
   prompts the leaf cannot issue.
2. The "never edits inside a mission worktree / never implements inline" boundary is stated to
   cover the replan phase as well as the drive phase — the main agent performs no ticket writes,
   body-section edits, or commits inside a mission worktree.
3. The pre-flight then prompt then fan-out ordering is written so the main agent collects every
   developer ruling first (still in the main agent), then dispatches; a leaf never blocks waiting
   for a prompt.

## Considerations

- The main agent must still own `AskUserQuestion` end to end — the replan interrogation's design
  rulings are developer decisions and cannot move into a leaf. The change is that once the rulings
  are collected, the *application* of them (tickets, edits, commit) moves into the worktree's leaf.
- A leaf that performs a replan needs the ruling inputs passed to it explicitly (the leaf cannot
  re-prompt), so the main agent's prompt results become part of the leaf's dispatch payload.
- Filed from a downstream consumer of the plugin; the reporter has no write access to this repo
  and defers the exact shape of the fix (new section vs amended §2) to the maintainer.
