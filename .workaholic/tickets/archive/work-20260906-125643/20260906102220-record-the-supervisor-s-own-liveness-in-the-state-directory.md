---
created_at: 2026-09-06T10:22:20+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: reproduce-and-localize-the-empty-codex-state-directory
mission: finish-the-codex-external-process-and-make-its-state-inspectable
merge_policy:
verification_handoff: 
---

# Record the supervisor's own liveness in the state directory

## Overview

The first repair the diagnosis selects: `.codex-loop/` cannot distinguish **never started**
from **started and stopped**. `write_status` runs first inside `run_tick`, so a supervisor
killed during startup — or one whose `codex exec` never returned — leaves the directory exactly
as empty as one that was never launched, and `show_status` prints `absent` for both.

The repair is a supervisor record written **when the supervisor starts**, before its first
tick, and cleared or marked stopped when it exits: the ask's "internal state is inspectable"
applied to the process itself. It is the one reading that must not depend on a live lock probe,
because the question is asked precisely when nothing is running.

**Absent means never started**, and that stays true — a directory with no supervisor record is
byte-identical to one before this existed, so a repository that never runs the Codex path is
unaffected.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a degraded read is named by its reason, never rendered as healthy

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the supervisor lock (~line 395) and
  `LOOP_ANCHOR` (~line 405): where a start is known; `on_interrupt` (~line 282) and the loop
  exit: where a stop is known. `write_status` (~line 188) is the existing writer to compose
  with, not to duplicate.
- `plugins/workaholic/skills/work/reference/other-agents.md` — where the directory's readings
  are documented; this adds one and must say what absent means.
- `.codex-loop/` — the state directory (git-ignored).

## Implementation Steps

1. Take the enumeration ticket 1 produced and confirm which collapse this ticket closes; it
   closes exactly the never-started/started-and-stopped pair and no other.
2. Write a supervisor record at startup — after the lock is taken and **before** the first
   `run_tick` — carrying at minimum the pid, the start time, the interval and the anchor.
   Reuse the existing atomic `tmp`-then-`mv` shape `write_status` already uses.
3. Mark it stopped on every exit the script controls: normal `--once` return, the interrupt
   trap, and the readiness refusal at first tick. An exit the script does not control must be
   detectable as **stale** rather than reported as running.
4. Make the record answer staleness without a live probe: a pid that is no longer alive reads
   `stopped_unclean`, never `running`. Where the pid cannot be checked, the reading is named
   unreadable — never assumed healthy.
5. State in `other-agents.md` what each reading means and that an absent record means never
   started.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A supervisor that started and was killed leaves a record distinguishable from one that never
  started.
- The reading is derivable from the directory alone, with no live lock probe.
- A record whose process is gone reads as stopped or stale, never as running; an unreadable
  record is named as unreadable.
- An absent record means never started, and a repository that never runs the path is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- Start the supervisor, kill it during its first tick, and read the directory: the record must
  say it started and stopped.
- Read the directory on a machine where the supervisor was never launched: absent.
- A hermetic case in `scripts/test-workflow-scripts.mjs` covering the three readings.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- `sh scripts/codex-loop.sh --status` still returns without requiring the `codex` CLI.

## Considerations

- A pid is not a proof across a reboot; the record must carry enough to say so rather than
  claim liveness it cannot establish.
- This does not add a second liveness authority to the *claim* protocol — it concerns the Codex
  supervisor process only, and touches no branch tip and no claim.

## Final Report

Development completed as planned.

**The collapse this closes** is exactly the pair the diagnosis named — rows 1 ↔ 5/6/7/8 of its
table, *never started* against *started and stopped* — and no other. Rows 3 and 4 (a
`--dispatch` that creates the directory at L191 and returns without writing) are untouched here
and carried into ticket 3, as the diagnosis said they must be.

**What was added**: `.codex-loop/supervisor.json`, written by `write_supervisor` through the same
atomic `tmp`-then-`mv` shape `write_status` already uses — composed with it, not duplicating it.
It is written after the lock is taken and **before** the first `run_tick`, carrying the pid, the
boot id, the start time, the interval, the anchor, `once` and the log directory. It is closed at
every exit the script controls: `completed_once`, `interrupted`, `readiness_refused`.

**The interrupt write is placed before the tick guard.** `on_interrupt` began
`[ -n "$CURRENT_TICK" ] || exit 130`, so an interrupt taken outside a tick — the window between
the lock and `run_tick`'s first `write_status`, and the window after a tick cleared
`CURRENT_TICK` — wrote nothing at all. That window is collapse row 7, and it is now a stop the
directory can see.

**Staleness is answered without a live probe**, and a pid alone is not the answer:

| Reading | Established by |
| ------- | -------------- |
| `never_started` | no file |
| `stopped:<reason>` | the record's own `state`/`stopped_reason` |
| `running` | recorded pid alive **and** the boot id matches |
| `stopped_unclean` | the recorded pid is gone — sound whatever the boot id says |
| `stopped_unclean:reboot` | the pid is alive under a **different** boot id, so the number was recycled |
| `unreadable:boot_unverifiable` | the pid is alive and no boot id is readable on either side — a live process cannot be told from a recycled number |
| `unreadable:malformed` / `:unknown_state` / `:jq_missing` | the file is there and cannot be read |

The boot id is what answers the ticket's own caveat that *a pid is not a proof across a reboot*:
rather than claiming liveness it cannot establish, the reading names what it could not rule out.
A dead pid is still a proof the process is gone, so that rung is taken first and needs no boot id
at all.

**Absent means never started**, and a repository that never runs the Codex path is byte-identical
to one before this existed — nothing writes the record but the supervisor, and `--status` still
creates neither the file nor the directory (asserted).

### Verification

- `node scripts/test-workflow-scripts.mjs` — full suite, exit 0.
- `node scripts/test-workflow-scripts.mjs "supervisor record"` — 16 passed, 0 failed, covering:
  never-started; a completed run recording `stopped:completed_once` with pid/start/interval/anchor;
  the readiness refusal recording `stopped:readiness_refused`; a dead pid reading
  `stopped_unclean`; a live pid under a foreign boot id reading `stopped_unclean:reboot`; an
  unknown state word and a malformed file each named `unreadable:<reason>`; the atomic writer
  leaving no `supervisor.json.tmp.*` beside the record; and `--status` run under
  `PATH=/usr/bin:/bin` — no `codex` CLI — still returning 4 and writing nothing.
- `sh -n` on the launcher, and the four readings exercised by hand against throwaway `--log`
  directories before the suite cases were written.

### Discovered Insights

- **Insight**: a dead pid proves the process is gone regardless of the boot id, while a *live*
  pid proves nothing without one. Ordering the rungs that way — pid first, boot id only for a
  live pid — keeps the reading sound on a platform that exposes no boot id, where only the
  ambiguous case degrades to `unreadable`.
  **Context**: the naive shape (require the boot id, then check the pid) would report
  `unreadable` for every reading on such a platform, including the ones it can actually settle.

- **Insight**: `--dry-run --once` now leaves `supervisor.json` reading `stopped:completed_once`,
  which disambiguates the residue finding B recorded — a dry run's leftover `.supervisor.lock`
  used to be indistinguishable from a supervisor killed during startup. The stale lock itself is
  still left behind and is still not repaired by this mission.
  **Context**: the record turned a two-way ambiguity into a one-way one without touching the
  lock, which is worth knowing before anyone "fixes" the lock separately.
