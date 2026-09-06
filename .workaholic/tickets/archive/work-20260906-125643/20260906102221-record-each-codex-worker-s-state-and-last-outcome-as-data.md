---
created_at: 2026-09-06T10:22:21+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: reproduce-and-localize-the-empty-codex-state-directory
mission: finish-the-codex-external-process-and-make-its-state-inspectable
merge_policy:
verification_handoff: 
---

# Record each Codex worker's state and last outcome as data

## Overview

The second repair: a dispatched worker's state exists **only as a live lock probe**, and its
outcome exists only as an unindexed transcript. `role_state` answers `running`/`idle` by
testing `worker-<role>.lock` with `flock`, and `run_worker` writes `<stamp>-<role>.md` and
`.log` with nothing tying them to the role. `status.json` carries no worker field at all, so a
person — or a later tick, or `/moderate` — reading the directory learns nothing about the three
workers. `record_worker_finish` writes the finish into the **moderate tick log**
(`.workaholic/moderations/`, git-ignored, on another path entirely), not into `.codex-loop/`.

So *idle because it finished cleanly* and *idle because it failed forty minutes ago* are one
reading. The ask names the directory as the place the state is checked from, and this is the
half that is missing from it.

The lock stays the concurrency authority — it is what refuses a second worker — and this adds
a **record beside it**, never a second authority.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a running system names what it could not read

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `role_state` (~line 81),
  `run_worker` (~line 340) and `record_worker_finish` (~line 328): where a worker's state and
  outcome are known and currently not written to the directory.
- `plugins/workaholic/skills/work/reference/other-agents.md` — where the per-role readings are
  documented.
- `.codex-loop/` — where `worker-<role>.lock`, the dispatch log and the transcripts already sit.

## Implementation Steps

1. Write a per-role record in the state directory when a worker starts and again when it
   finishes, carrying the role, the tick stamp, the start and finish times, the exit status and
   the paths of its report and transcript.
2. Derive the worker's reported outcome from **its own report**, not from the exit status
   alone, and record both — a run exiting zero without executing is not a finished run. Where
   the report cannot be read, record that by name rather than inferring success.
3. Leave `record_worker_finish`'s tick-log write exactly as it is: the cadence readers depend on
   it and this adds a second surface, not a replacement.
4. Keep the lock as the only concurrency authority. The record is evidence; nothing may refuse,
   start or reap a worker by reading it.
5. Document each per-role reading in `other-agents.md`, including what an absent record means.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each role's last outcome is readable from the state directory with no live probe and no
  transcript parsing.
- A worker that finished cleanly and one that failed are distinguishable readings.
- A report that could not be read is named as unread, never rendered as success.
- The lock remains the sole concurrency authority; no code path refuses or starts a worker on
  the new record.
- `record_worker_finish`'s existing tick-log write is byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- Dispatch a worker that succeeds and one that fails; read the directory for both.
- Hermetic cases in `scripts/test-workflow-scripts.mjs` for the clean, failed and unreadable
  readings.
- A grep-level assertion that no dispatch or refusal path reads the record.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.

## Considerations

- Concurrent dispatches of different roles write different files; a single shared file would
  need locking this deliberately avoids.
- The records accumulate in a git-ignored directory. Whether they are pruned, and by what, is
  not decided here — it is named for the mission's reviewer.

## Final Report

Development completed as planned.

**What was added**: `.codex-loop/worker-<role>.json`, written by `write_worker_record` through
the same atomic `tmp`-then-`mv` shape the other two writers use. It is written when the worker
starts (`running`) and again when it finishes (`finished`), carrying the role, the tick stamp,
the start and finish times, the **process exit status** and the **reported outcome** as separate
fields, the report and transcript paths, and the pid and boot id that make staleness answerable.

**The outcome comes from the worker's own report.** `worker_outcome` — the existing
schema-constrained reader — supplies it, so `ok`, `blocked:<reason>`, `failed:<reason>`,
`not_executed:<reason>` and `unreadable:<reason>` are five distinct recordings, and a report that
could not be read is named rather than inferred as success. The exit status is kept **beside**
it, not folded into it: *the process terminated* and *the role did the work* are two facts.

**One derivation of liveness, not two.** `liveness_reading <pid> <boot-id>` answers
`alive | gone | reboot | unverifiable` and is read by the supervisor record and by every per-role
record. Ticket 2 introduced the rule; this ticket factored it out rather than writing a second
copy, which is how the two would have come to disagree about what a live pid proves. A `running`
record whose process is gone reads **`died_unrecorded`** — never a finish, and never `idle`.

**The lock is untouched as the concurrency authority.** `--dispatch` still refuses
`already_running` on `role_state`; the record is evidence beside it. The suite asserts this
structurally: the whole region from `if [ -n "$WORKER_ROLE" ]; then` to the end of the file
contains no call to `worker_reading`, so no dispatch, refusal or start path can read it.
`record_worker_finish` and its two `log-append.sh` writes are byte-identical, and the call site
in `run_worker` is asserted present — the cadence readers still read the tick log.

**`show_workers` now renders three sources kept visibly apart** —
`codex worker <role>: <lock> record=<reading> last_outcome=<tick log>` — because they answer
different questions, and the diagnosis found that `last_outcome` comes from another tree
entirely. Ticket 4 composes them; this ticket makes the middle one exist.

**Rows 3 and 4 of the diagnosis, carried here, are closed.** The state directory was created
inside the dispatch branch **before** the `codex` presence check *and* again on the main path,
so `--dispatch <role> --dry-run` and a dispatch with no `codex` CLI each left an **empty**
`.codex-loop/` — the exact state measured on the operator's machine at 09:31:48, and the first
of the two reproduces it byte-for-byte. The earlier `mkdir` is removed and the remaining one is
skipped for a dry-run dispatch, so a run that writes nothing now creates nothing. The
supervisor's own `--dry-run` still creates the directory and takes `.supervisor.lock`; that is
finding B and is deliberately **not** repaired here.

### Verification

- `node scripts/test-workflow-scripts.mjs "per-role record"` — 34 passed, 0 failed, covering:
  `never_dispatched`; a clean run, a reported `blocked`, a run that exited zero **without
  executing**, a process that died (`codex_exit_9`), an unparseable report and a report that
  never arrived — each asserting the recorded `state`, the separately kept `exit_status`, the
  tick/times/paths, and the reading rendered from the directory alone; a `running` record whose
  process is gone reading `died_unrecorded`; a malformed record named rather than rendered as a
  finish; a dry-run dispatch and a no-CLI dispatch each creating no state directory; and the
  three structural assertions that the lock refusal still reads `role_state`, that the
  dispatch/worker region reads no record, and that the tick-log write is untouched.
- Rows 3 and 4 also exercised by hand against throwaway `--log` directories.

### Discovered Insights

- **Insight**: the two `mkdir -p "$LOG_DIR"` calls were not redundant by accident — the first sat
  inside the dispatch branch **above** the `codex_cli_missing` check, so it was the only thing
  that ran on a machine without the CLI. Removing it is what makes `codex_cli_missing` a refusal
  that leaves no trace, rather than one that leaves a directory implying a loop once lived here.
  **Context**: the surviving `mkdir` is below the CLI check, so nothing regressed for the paths
  that genuinely need the directory.

- **Insight**: `worker_outcome` already distinguished five outcomes correctly; nothing was wrong
  with the derivation, only with where the answer went — into a printf and the moderate tick log,
  never into the directory the ask names. The repair is a second **destination** for an existing
  reading, not a new reading.
  **Context**: worth knowing before anyone adds a second outcome derivation for the directory.
