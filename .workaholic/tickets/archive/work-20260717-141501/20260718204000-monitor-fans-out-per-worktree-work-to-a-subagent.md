---
type: enhancement
layer: [Domain]
effort: 2h
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

## Final Report

Amended `skills/monitor/SKILL.md` §1/§2 and `commands/monitor.md` (no renumbering, to keep
cross-references stable) so the whole of a worktree's work — **replan application included** —
is leaf work:

- **QG1** — §1 now splits a `not_authorized`/`no_plan` mission across the fan-out boundary:
  *"the interrogation is main-agent work, the application is leaf work"*. The interrogation
  (every `AskUserQuestion`) runs in the main agent at pre-flight; a §2 leaf-prompt clause has the
  mission's own leaf apply the collected rulings **inside its worktree** (delta tickets, body
  sections, `drive_authorized`, commit) through the mission skill's own mutators, then drive.
- **QG2** — the §2 dispatcher boundary was strengthened: the main agent *"never performs a
  replan's bookkeeping … inside a worktree"*, and the boundary *"covers the replan phase exactly
  as it covers the drive phase"*.
- **QG3** — a new §1 ordering paragraph: *"collect every ruling first, then dispatch"*; a leaf is
  *"never spawned to wait on an answer it cannot ask for"*.
- **Governing principle 2** (developer directive) — a new §2 paragraph makes the dispatcher
  *"Actively control the degree of concurrency"*: the *"wave size is a dial the main agent tunes
  down"* for cross-worktree Key-File interference and for booted-dev-env resource load, revised
  between waves.

Regression test `testMonitorReplanIsLeafWork` added and registered (12 assertions over the skill
and command). Docs updated in the same change: `CLAUDE.md` (executor bullet + command table +
dispatcher line) and `README.md`.

**Divergence from ticket text:** none of substance. The ticket deferred "new section vs amended
§2" to the maintainer; per governing principle 1 (thin dispatcher) I amended §1/§2 in place rather
than renumbering, and added governing principle 2's concurrency-control prose, which the ticket
did not itself request.

**Note (out of scope):** this worktree branch was 28 commits behind `main` and lacked the
`/monitor` files entirely, so `main` was merged in first. That merge surfaced two pre-existing
semantic conflicts between this branch's stale ahead-work and `main`, both reconciled toward the
merged tree's dominant design and committed separately from the ticket: (1) `create-or-update.sh`
was a broken hybrid — mktemp per-run body file everywhere except the `shrink-pr-body.sh` call,
which still passed `/tmp/pr-body.md`; (2) `validate-ticket.sh` (main's newly-added mission-relation
check) called the 1-arg `mission_resolve`, but this branch's refactor made every other caller and
`resolve.sh` 2-arg (`<root> <arg>`). Both fixed; full suite green (1113 → with the merge fixes).

Verification: `build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh` (conforming),
`test-workflow-scripts.mjs` — all pass; `/monitor` stays excluded from `outputs/workflows`.
