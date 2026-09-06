---
created_at: 2026-09-06T10:22:21+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: record-each-codex-worker-s-state-and-last-outcome-as-data
mission: finish-the-codex-external-process-and-make-its-state-inspectable
merge_policy:
verification_handoff: 
---

# Answer the whole Codex loop status from the directory alone

## Overview

The reading the ask actually wants: **one question, one answer, from the state directory**.
Today `--status` gives two half-answers from two sources — `show_status` reads `status.json`
and returns 0/4/5, then `show_workers` probes each role's lock live — so the coordinator's
state and the workers' states are neither composed nor readable by anything that is not this
script. A later tick, `/moderate`, or a person with a shell and no `codex` CLI cannot ask "is
the Codex loop turning, and what is it doing" and get one answer.

With the supervisor record (ticket 2) and the per-role records (ticket 3) in the directory,
this composes them into a single reading — supervisor, every worker, and the last tick — that
is derivable from files alone. **Composed, never re-derived**: this ticket adds no new state
and no second derivation of a reading either previous ticket owns.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — one reading, named where it is degraded

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `show_status` (~line 98) and
  `show_workers` (~line 115), the two half-answers, and the `--status` branch (~line 140) that
  returns before the `codex` presence check.
- `scripts/codex-loop.sh` — the shim a person invokes.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the documented `--status`
  surface and the command list, which this changes.
- `plugins/workaholic/commands/work.md` — names the read-only `--status` surface.

## Implementation Steps

1. Compose one reading over the supervisor record, the per-role records and `status.json`.
   Read each through whatever ticket 2 and ticket 3 established; derive nothing a second time.
2. Emit it in a form a machine can consume as well as a person — the existing human lines stay,
   with a JSON form beside them, so a later tick can read it without parsing prose.
3. Name every part that could not be read, by its own reason, in place. A missing supervisor
   record, an unreadable role record and a malformed `status.json` are three distinct
   readings, and none of them may render as healthy or be silently omitted.
4. Keep `--status` free of the `codex` CLI requirement and free of side effects: it starts
   nothing, writes nothing, and takes no lock.
5. Update `other-agents.md` and `commands/work.md` to state the composed surface and what each
   degraded reading means.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One invocation answers supervisor state, every worker's state and last outcome, and the last
  tick, from the directory alone.
- Each unreadable part is named by its reason; none renders as healthy and none is omitted.
- `--status` requires no `codex` CLI, starts nothing, writes nothing and takes no lock.
- The reading is consumable by a machine without parsing the human lines.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/codex-loop.sh --status` against: a never-started directory, a running supervisor,
  a stopped one, and one with a failed worker — output recorded for each.
- The same with the `codex` CLI removed from PATH.
- Hermetic cases in `scripts/test-workflow-scripts.mjs` covering the degraded readings.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- The four readings above are recorded in the branch story as evidence, which is the ask's own
  standard of proof: observable state rather than a live chat.

## Considerations

- The JSON form is a surface other things will read; it is worth naming its shape in
  `other-agents.md` at the same time rather than leaving it to be inferred.
- This ticket completes the mission's acceptance but does not itself prove the loop turns —
  what it proves is that the question is answerable from the directory.

## Final Report

Development completed as planned.

**What was added**: `--status --json`, one invocation answering the supervisor's state, every
worker's state and last outcome, and the last tick — from the state directory alone. The human
lines are unchanged and gained the supervisor and per-role readings from tickets 2 and 3.

**Composed, never re-derived.** Every value in the JSON belongs to a reader that already exists:
`supervisor_reading` (ticket 2), `worker_reading` and `role_state` (ticket 3),
`last_worker_outcome`, and `tick_reading` — the one new function, and it is a **factoring** of
the absent/unreadable branches already inside `show_status` rather than a second derivation.
`show_status` now reads it too, so the human and machine surfaces cannot disagree about whether
`status.json` is readable. No new state was added.

**Every part names its own degradation in place.** A missing supervisor record, an unreadable
role record and a malformed `status.json` are three distinct readings, and an unreadable part
carries its reason with **null** details rather than a value that looks healthy. No part is
omitted: all three roles are always rendered, and `supervisor` and `tick` always carry a
`reading`. The exit status is the tick's own on both surfaces — `0` readable, `4` absent, `5`
unreadable — so no caller has to change.

**`--status` stays free of the CLI, of side effects and of any lock.** It returns before the
`codex` presence check and before the `mkdir`, which is now asserted rather than assumed: the
never-started case runs under `PATH=/usr/bin:/bin` and is checked not to create the directory it
is reporting on, and the completed case asserts the directory listing is byte-identical before
and after the read.

**The JSON shape**, named here and in `other-agents.md` rather than left to be inferred:
`log_dir`; `supervisor{reading, pid, started_at, interval}`; `tick{reading, tick_id, state,
outcome, blocked_reason, finished_at, next_due, report_path}`; `workers[]{role, lock, record,
last_outcome}`; `reports{dir, chat_return}`.

### Verification — the four readings, recorded as the gate requires

All four taken under `PATH=/usr/bin:/bin`, with **no `codex` CLI on the path**.

```
### never started
codex supervisor: never_started (…/never/supervisor.json)
codex loop status: absent (…/never/status.json)
codex worker implement: idle record=never_dispatched last_outcome=unreadable:log_unreadable
codex worker propose: idle record=never_dispatched last_outcome=unreadable:log_unreadable
codex worker moderate: idle record=never_dispatched last_outcome=unreadable:log_unreadable
exit=4

### a running supervisor
codex supervisor: running pid=646313 started_at=2026-09-06T04:30:00Z interval=300
codex loop status: absent (…/running/status.json)
exit=4

### a supervisor that stopped
codex supervisor: stopped:completed_once pid=… started_at=… interval=60
codex loop status: state=sleeping outcome=ready next_due=… report=…
exit=0

### a failed worker
codex supervisor: running pid=646313 started_at=2026-09-06T04:30:00Z interval=300
codex worker implement: idle record=finished:failed:codex_exit_9 last_outcome=…
codex worker propose: idle record=never_dispatched last_outcome=…
exit=4
```

The same four directories through `--status --json`, and a fifth carrying three simultaneous
degradations (malformed `status.json`, a supervisor record whose process is gone, an unreadable
role record) rendering `unreadable:malformed` / `stopped_unclean` / `unreadable:malformed` with
the failed worker's outcome and the never-run role still distinct.

- `node scripts/test-workflow-scripts.mjs "composed Codex status"` — 23 passed, 0 failed.
- `node scripts/test-workflow-scripts.mjs` — **6742 passed, 0 failed**.
- `node scripts/build-plugins/build.mjs` — no `outputs/` diff (the `work` skill is deliberately
  outside the portable bundle); `verify.mjs`, `validate-metadata.mjs` and `layout-doctor.sh` all
  clean.

### Discovered Insights

- **Insight**: `show_status`'s absent/unreadable/readable split was already a three-valued
  reading — it was just spelled inline as control flow and returned as an exit status, so
  nothing but the terminal could consume it. Naming it `tick_reading` made the machine surface a
  composition instead of a second parse of the same file.
  **Context**: the same shape is worth looking for wherever a reader "returns 0/4/5 and prints" —
  the reading exists, it simply has no name.

- **Insight**: the JSON form is what makes `last_outcome`'s provenance visible. Rendered beside
  `lock` and `record` under one role, it is obvious that three sources are being consulted and
  that only two of them are the Codex loop's own — the moderate tick log belongs to whichever
  loop last wrote it.
  **Context**: a later consumer should read `record`, not `last_outcome`, when it wants the
  Codex worker's own result.
