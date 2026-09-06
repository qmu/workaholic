---
created_at: 2026-09-06T21:05:56+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
merge_policy:
verification_handoff: 
feedback: 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
claim: work-20260906-214424
---

# Stop the dispatch-lock drill from racing its own worker

## Overview

`scripts/test-workflow-scripts.mjs`'s Codex-clock section asserts *a role already running is
refused rather than started twice*: it runs `codex-loop.sh --dispatch implement`, then runs the
same command again and expects `already_running`. The second dispatch instead reported
`started pid=…`, so the assertion failed and the suite reported `1 failed`.

**Measured twice on 2026-09-06, both times on a loaded machine.** Once at loadavg 8.04 with three
`implement` runners live, and again later with other runners active. Between them the same suite
passed cleanly twice on the same tree — so this is **not** a defect the tree carries at rest, and
it is not caused by the change either run was making: the first observation predates any edit in
that session's branch, and `scripts/codex-loop.sh` was not touched by either.

**The likely mechanism is in the drill, not the lock.** `--dispatch` returns *at once*, by design
— the worker is a detached process, and the run that started it does not wait. So the first
dispatch can return before its worker has reached the `flock`, and a second dispatch issued in the
next millisecond finds no lock held and legitimately starts. That is a race between the test's two
calls, not evidence that the lock fails to exclude; whether the lock ALSO has a window is the
thing to establish rather than assume.

**Why it matters more than a flaky row.** This suite is a merge gate: `branch-checks.sh` refuses a
merge on `checks_red`, so a race here parks a green unit for a tick at a time, and — worse — it
trains a reader to discount a red suite. A gate that fails for reasons unrelated to the change is
a gate people stop reading.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a gate that cannot be trusted is not a gate

## Key Files

- `scripts/test-workflow-scripts.mjs` — the Codex-clock section, the two `--dispatch` calls and
  the `already_running` assertion
- `scripts/codex-loop.sh` — `--dispatch`, the per-role `flock`, and the point at which the lock
  is actually taken relative to the parent returning
- `plugins/workaholic/skills/work/reference/other-agents.md` — where the per-role lock is
  recorded as the concurrency authority that replaces `ListAgents`/`TaskStop`

## Implementation Steps

1. **Establish which side the window is on** before changing either. Reproduce under load, and
   determine whether the lock is taken by the parent before it returns or by the detached child
   after it. Report which it was; the two have different repairs and only one of them is a real
   defect in the loop.
2. If the parent returns before the lock is held, **take the lock in the parent** — the dispatch
   is what claims the role, so the claim should not depend on how fast the child starts. The
   drill then asserts a property the code actually has.
3. If the lock is already parent-held, the drill must **wait for the observable the lock
   publishes** rather than for nothing, and the fix is in the test alone.
4. **Do not weaken the assertion into a retry or a sleep that hides the window.** A drill that
   passes because it waited long enough proves nothing about exclusion; the repository's standing
   rule is that a breaker must fail on the behaviour.
5. Keep `--status` a pure read: it starts nothing, writes nothing and takes no lock, and this
   change must not give it a reason to.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Which side held the window is stated in the change, with the evidence.
- Two dispatches of one role in immediate succession start one worker, with no sleep or retry
  standing in for the exclusion.
- `--status` still starts nothing, writes nothing and takes no lock.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, run on a loaded machine, repeatedly
- `sh scripts/e2e/loop-drill.sh verify-codex-clock`

**Gate** — what must pass before approval:

- The above pass, and the assertion still fails when the exclusion is removed.

## Considerations

- **This was minted mid-run, from a failure in another unit's verification.** It is recorded as a
  ticket rather than left in a run report because it fires on a merge gate and had already been
  seen once and lost — the first observation was truncated out of a `| tail -25` and could not be
  named until it recurred.
- **Do not fold this into the frozen-runner mission.** That mission is about a runner that stops
  advancing and the fan-out slot it holds; this is the supervisor's own dispatch lock under a
  concurrent test, and attaching it would leave that mission carrying queued work after its
  acceptance completed.

## Final Report

Development completed as planned. **The window was on the LOCK's side, not the drill's** — step 2
of the Implementation Steps applied, not step 3 — so the repair is in `codex-loop.sh` and the
drill was strengthened to assert the property the code now actually has.

### 1. Which side held the window, with the evidence

`--dispatch` only **read** `role_state` and then forked; the `flock` was taken by the detached
child in the `--worker` branch. So the claim did not exist yet when the run that made it
returned. Probed in-process, with no fork between the dispatch returning and the read:

```
round 1: at parent return -> no-lock-file
round 2: at parent return -> no-lock-file
round 3: at parent return -> no-lock-file
round 4: at parent return -> held
round 5: at parent return -> no-lock-file
round 6: at parent return -> no-lock-file
```

In **5 of 6** rounds the lock file did not even exist at the moment the parent returned, so any
reader in that window is answered `idle`. The consequence, two dispatches issued concurrently:

```
round 1: concurrent workers started = 1
round 2: concurrent workers started = 2
```

Two workers for one role. The drill was not racing itself — it was reporting a real gap, and the
sequential pair in the suite was only usually saved by the first dispatch's own return latency.

### 2. The repair: the dispatch claims the role

`dispatch_claim_role` is the one seam, taken **before** the fork:

- **With `flock`**, the parent opens fd 8 and locks it; the child inherits the open file
  description across the fork, so the lock is held **continuously** from before the parent
  returns until the worker exits. The child is passed `--claimed` and does not retake it — a
  second open file description on one file is a conflicting holder under `flock(2)`, and the
  worker would otherwise refuse itself.
- **Without `flock`**, the pid file is the claim and was the same window one layer down.
  Measured on a `PATH` with `flock` removed: **4 of 4** concurrent pairs started two workers.
  It is now an atomic `set -C` (`O_EXCL`) create; a file naming a **dead** pid is a crashed
  worker's residue, cleared once and the create retried once. The parent claims under its own
  pid and then hands the file to the pid it forked, so the role never reads `idle` in between.

A lost race is `already_running` on exit 0, exactly as the cheap `role_state` answer above it is.

### 3. Acceptance

| Condition | Evidence |
| --------- | -------- |
| Which side held the window is stated with the evidence | §1 above, and the header comment on `role_state`/`dispatch_claim_role` |
| Two dispatches start one worker, no sleep or retry standing in | 5 suite rounds and the drill's own row issue the pair **concurrently**; 8/8 flock and 6/6 no-flock rounds measured `started=1 refused=1` |
| `--status` still starts nothing, writes nothing, takes no lock | `--status` and `--status --json` on an empty consumer: `exit=4`, `state dir: none`. Unchanged — it returns before the claim and before the `mkdir` |
| The assertion still fails when the exclusion is removed | Neutering `dispatch_claim_role` to `return 0`: **10 of 10** new suite assertions FAIL (`6779 passed, 12 failed`), and the drill's `dispatch_claim_breaker` row requires it |

### 4. Verification

- `node scripts/test-workflow-scripts.mjs` — **6791 passed, 0 failed**, three consecutive runs on
  a loaded machine (loadavg 2.26 / 3.32 / 2.13), plus two earlier runs.
- `sh scripts/e2e/loop-drill.sh verify-codex-clock` — `pass`, 5 load-bearing rows, 2 breakers.
- `build.mjs` / `verify.mjs` / `validate-metadata.mjs` / `layout-doctor.sh` all clean; the
  generated `outputs/` are unchanged (the work skill is not in that bundle).

### 5. Scope

`--status` was not given a reason to take a lock. `conflict-class.sh`, the cadence readers,
`record_worker_finish` and the tick log are untouched. The no-`flock` fallback was repaired
because the acceptance criterion is stated unconditionally and that path is a supported one; it
was racy before this change and is not a regression introduced by it.
