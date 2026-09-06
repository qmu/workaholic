---
created_at: 2026-09-06T10:22:20+09:00
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
