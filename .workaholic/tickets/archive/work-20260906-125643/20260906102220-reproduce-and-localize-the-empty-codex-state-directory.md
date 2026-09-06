---
created_at: 2026-09-06T10:22:20+09:00
status: done
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

## Final Report

Development completed as planned. This ticket implements no repair; it establishes the
diagnosis the three following tickets act on.

### 1. The reported state, reproduced verbatim

```
$ ls -la .codex-loop/
drwxrwxr-x 2 tamurayoshiya tamurayoshiya 4096  9月 6 09:31 .
drwxrwxr-x 14 tamurayoshiya tamurayoshiya 4096  9月 6 12:53 ..
exit=0

$ stat .codex-loop
Modify: 2026-09-06 09:31:48.296528122 +0900
 Birth: 2026-09-06 09:31:48.296528122 +0900

$ sh scripts/codex-loop.sh --status
codex loop status: absent (/home/tamurayoshiya/projects/workaholic/.codex-loop/status.json)
codex worker implement: idle last_outcome=unrecorded
codex worker propose: idle last_outcome=unrecorded
codex worker moderate: idle last_outcome=unrecorded
codex loop reports: dir=/home/tamurayoshiya/projects/workaholic/.codex-loop chat_return=none
exit=4

$ command -v codex; codex --version
/home/tamurayoshiya/.local/bin/codex
codex-cli 0.153.4
```

**`mtime == Birth`** is the load-bearing measurement: no file was ever created inside that
directory. It rules out every path that leaves a residue.

`sh scripts/codex-loop.sh --dry-run --once` resolved the shim, the plugin launcher and the
prompt, printed the `codex exec` line and `codex loop: ready interval=300s once=true
env=settings log=…/.codex-loop` — and **created `.supervisor.lock`** (see finding B).

### 2. Where the readings collapse — enumerated from the script

Every path that leaves `status.json` absent, with the directory residue each leaves. Line
numbers are `plugins/workaholic/skills/work/scripts/codex-loop.sh`.

| # | Path | Residue in the directory | `--status` |
| - | ---- | ------------------------ | ---------- |
| 1 | Never started | directory absent | `absent`, exit 4 |
| 2 | `--status` itself — early-exits at L176, **before** the L214 `mkdir -p` | creates nothing | `absent`, exit 4 |
| 3 | `--dispatch <known role> --dry-run` — L191 `mkdir`, L573 `exit 0` | **empty directory** | `absent`, exit 4 |
| 4 | `--dispatch`/`--worker`, known role, no `codex` on PATH — L191 `mkdir`, L194 `exit 2` | **empty directory** | `absent`, exit 4 |
| 5 | `--dry-run --once`, supervisor path — `run_tick` returns at L358, **before** `write_status` (L360) | `.supervisor.lock` | `absent`, exit 4 |
| 6 | Supervisor killed between L214 and L360 | `.supervisor.lock` | `absent`, exit 4 |
| 7 | `on_interrupt` with `CURRENT_TICK` empty — before L351 or after L385 — `exit 130`, writing nothing | `.supervisor.lock` | `absent`, exit 4 |
| 8 | A second supervisor refused at L595 (`flock -n 9`, exit 3); `exec 9>` created the file first | `.supervisor.lock` | `absent`, exit 4 |
| 9 | A worker dispatched with no supervisor tick | `worker-*.lock`, `dispatch-*.log`, transcripts | `absent`, exit 4 |

**All nine produce identical output.** `show_status` (L103) has exactly two words for the whole
space: `absent` when the file is missing and `unreadable` when it is present and not JSON. So
*never started*, *started and died*, *interrupted*, *another agent holds the lock*, *dry-run
only* and *workers ran but no supervisor tick* are one reading, exit status included.

Probes, run against throwaway `--log` directories, confirming rows 2, 3 and 5:

- `--status --log <never>` → `absent`, exit 4, **directory not created**.
- `--dispatch nosuch --log <d>` → `bad_role`, exit 2, **directory not created** (L185 precedes the L191 `mkdir`).
- `--dispatch implement --dry-run --log <d>` → exit 0, **directory created and completely empty**.
- `--dry-run --once --log <d>` → exit 0, directory created holding **`.supervisor.lock` only**.

The worker half collapses separately. `show_workers` (L145) prints `role_state`, which asks only
whether a lock is held **at this instant** — so *idle because it finished cleanly* and *idle
because it failed forty minutes ago* are one word. `last_outcome` does not come from the state
directory at all: `last_worker_outcome` (L127) reads `.workaholic/moderations/` through
`log-read.sh`, a different tree on a different path, git-ignored, written by whichever loop last
ran. On this machine it printed `unrecorded` for all three roles while today's log carries six
`loop-finish-*` lines — because the reader keys on `loop-attempt-<role>`, which nothing in that
log has written. The directory the ask names is not the source of either half.

### 3. Which case occurred here — stated from evidence

**A Codex supervisor is running, and it is not driving this repository.**

```
$ ps -o pid,lstart,cmd -p 559347
559347 日 9月 6 06:40:08 2026 sh /home/tamurayoshiya/.codex/plugins/cache/workaholic/workaholic/1.0.316/skills/work/scripts/codex-loop.sh --interval 300
$ ls -l /proc/559347/cwd
… -> /home/tamurayoshiya/projects/coop-planner
$ ls -l /proc/559347/fd/9
… -> /home/tamurayoshiya/projects/coop-planner/.codex-loop/.supervisor.lock
```

That supervisor's own `.codex-loop/` is fully populated — `status.json` reading `state:
sleeping, outcome: ready, next_due: 2026-09-06T04:00:08Z`, tick reports, transcripts, worker
locks and `dispatch-implement.log`. So the machinery works; **no supervisor has ever ticked
against `projects/workaholic`.**

Given `mtime == Birth`, rows 5-9 (each leaves a file) and rows 1-2 (each leaves no directory)
are all excluded. What remains is **row 3 or row 4** — a `--dispatch <known-role>` invocation
that created the directory at L191 and returned without writing, either through `--dry-run` or
through the `codex_cli_missing` exit. Row 3 reproduces the operator's state byte-for-byte in
probe D. **The evidence does not separate the two**: `codex` is on PATH now, but nothing on the
machine records whether it was on PATH at 09:31:48, so the pair is stated rather than picked
between.

**The finding the ask turns on**: for this repository the empty directory is *correct* — the
Codex loop is not driving it; the Claude Code `/work` loop is. The defect is precisely that the
directory cannot say so, and that a person reading it cannot tell this from a supervisor that
died. That is the ticket's own Considerations note, now established rather than supposed.

### 4. Coverage of the three following tickets

- Ticket 2 (supervisor record) closes rows 1 ↔ 5/6/7/8 — never-started vs started-and-stopped.
- Ticket 3 (per-worker records) closes row 9 and the `idle`-means-two-things collapse.
- Ticket 4 (composed reading) closes the two-half-answers split and the off-directory source of `last_outcome`.
- **Not covered by any of the three**: rows 3 and 4 — the `--dispatch` paths that `mkdir` the
  directory at L191 and return without writing. The supervisor record ticket 2 adds is written
  by the *supervisor*, and a dispatch writes none. Carried into ticket 3, where `--dispatch` is
  the subject.

### Discovered Insights

- **Insight**: `mkdir -p "$LOG_DIR"` runs twice on two different paths — L191 inside the
  dispatch/worker branch and L214 on the main path — and the L191 one precedes the
  `codex_cli_missing` check at L194. So a dispatch creates the state directory before the
  script knows it can run at all.
  **Context**: this is the mechanism that produces an empty `.codex-loop/`, and it is why
  "the directory exists" carries no information about whether a loop was ever started here.

- **Insight**: `--status` is genuinely side-effect-free — it returns at L176, before the L214
  `mkdir` — and needs no `codex` CLI, exactly as documented. `--dry-run` is **not**: it runs
  after the L194 CLI check and, on the supervisor path, after the L594 `exec 9>` that creates
  `.supervisor.lock`.
  **Context**: ticket 4 must preserve the first property; finding B below is the second.

- **Insight**: `last_worker_outcome` reads the moderate tick log, so `--status` reports the
  worker outcomes of whichever loop last wrote `.workaholic/moderations/` — on a machine
  running the Claude `/work` loop, that is the Claude loop's workers, rendered under
  `codex worker <role>`.
  **Context**: this is a cross-loop confusion, not only a missing record, and ticket 3's
  per-role record in the directory is what makes the Codex reading its own.

- **Finding A (not repaired by this mission)**: the running supervisor executes a **deleted**
  script — fd 10 resolves to
  `~/.codex/plugins/cache/workaholic/plugin-backup-UYC3Gd/workaholic/1.0.316/.../codex-loop.sh
  (deleted)`, while the cache now holds only `1.0.319`. A plugin update replaced the tree under
  a supervisor that has been running since 06:40:08.
  **Context**: a long-lived supervisor keeps whatever version it started with, indefinitely and
  invisibly. Reported, not fixed: it concerns `coop-planner`, not this repository.

- **Finding B (not repaired by this mission)**: `--dry-run --once` acquires the supervisor lock
  (L594) and leaves `.supervisor.lock` behind, despite `--dry-run` being documented as printing
  the command without executing it. Measured in probe C and on this repository at 12:58.
  **Context**: it makes a dry run indistinguishable, in the directory, from row 6 — a
  supervisor that started and was killed. Reported for the mission's reviewer.
