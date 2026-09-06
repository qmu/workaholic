---
created_at: 2026-09-06T10:22:21+09:00
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
