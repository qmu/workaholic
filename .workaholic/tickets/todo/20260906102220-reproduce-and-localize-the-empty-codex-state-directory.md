---
created_at: 2026-09-06T10:22:20+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-the-codex-external-process-and-make-its-state-inspectable
merge_policy:
verification_handoff: 
---

# Reproduce and localize the empty Codex state directory

## Overview

The ask reports a failure and this ticket diagnoses it before anything is designed
(`workaholic:discover`, *Diagnosis-First Rule*). **Measured 2026-09-06 on the operator's own
machine**: `.codex-loop/` exists, was created at 09:31, and is **empty** — no `status.json`, no
`.supervisor.lock`, no transcript, no worker record — while the operator believed the loop was
turning. `codex` is on PATH (`codex-cli 0.153.4`), so an absent CLI is not the explanation.

The reading to localize is that `.codex-loop/` is written by `codex-loop.sh` and by nothing
else, and `show_status` prints `absent` for every way of not having a `status.json`. So
**"never started", "started and died before its first tick" and "another agent is driving the
loop" are one indistinguishable reading**, which is the shape the ask is against. This ticket
establishes which of them actually happened here and where the reading collapses; the repairs
are the three tickets after it.

It implements no repair. Anything it finds that the later tickets do not cover is reported.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a running system's state is read in the environment it runs in; a
  degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `show_status` (~line 98), the
  `absent`/`unreadable` split, `write_status` (~line 188) and the supervisor lock (~line 395):
  where the four states collapse into one.
- `scripts/codex-loop.sh` — the repository shim; confirm the start path a person actually uses.
- `.codex-loop/` — the state directory under measurement (git-ignored).
- `plugins/workaholic/skills/work/reference/other-agents.md` — where the current reading is
  documented (`status.json` distinguishes `ready`, …); the record to correct if it overstates.

## Implementation Steps

1. **Reproduce the reported state.** Record `ls -la .codex-loop/` and
   `sh scripts/codex-loop.sh --status` verbatim, with their exit statuses, before changing
   anything. Note that `--status` returns before the `codex` presence check, so it is readable
   with no CLI.
2. **Localize where the readings collapse.** Enumerate, from the script, every path that leaves
   `status.json` absent or stale: never started; started and killed before `run_tick`'s first
   `write_status`; interrupted (`on_interrupt`); a worker dispatched with no supervisor tick;
   and a different agent's loop driving the repository. Name which produce identical output.
3. **Establish which one happened here.** Use evidence already on the machine — directory mtime,
   the absent `.supervisor.lock`, the tick log — and say so plainly. State it as a finding, not
   a guess; if the evidence cannot settle it, say that instead.
4. **Confirm the start path.** Run `sh scripts/codex-loop.sh --dry-run --once` and record
   whether the shim, the plugin launcher and the prompt resolve; note that `--dry-run` runs
   *after* the `codex` check, unlike `--status`.
5. **Record the findings** in the branch story: the four-way collapse, which case this was, and
   any reading the three following tickets do not repair.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reported empty-directory state is reproduced verbatim, with commands, output and exit
  statuses recorded.
- Every code path leaving `status.json` absent or stale is enumerated from the script, and
  those producing identical output are named as such.
- Which case occurred on the operator's machine is stated from evidence, or the evidence is
  named as insufficient — never guessed.

**Verification method** — the commands/tests/probes that prove them:

- `ls -la .codex-loop/` and `sh scripts/codex-loop.sh --status`, output and exit status recorded.
- `sh scripts/codex-loop.sh --dry-run --once`, output recorded.
- A written walk of `show_status`, `write_status`, `on_interrupt` and the supervisor lock.

**Gate** — what must pass before approval:

- The findings are recorded in the branch story, and each of the three following tickets is
  confirmed to address a named collapse or is reported as not covering one.

## Considerations

- The reporter's own framing — that the directory should hold more state — is a **hypothesis**
  here, not this ticket's design. It is carried into the following tickets only if the
  diagnosis supports it.
- The loop turning on this machine is currently the Claude Code `/work` loop, not the Codex
  supervisor. An empty `.codex-loop/` may be *correct* for that; the defect is that the
  directory cannot say so.
