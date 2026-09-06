---
created_at: 2026-09-06T21:05:56+09:00
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
