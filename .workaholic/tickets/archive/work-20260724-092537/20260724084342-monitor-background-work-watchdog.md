---
created_at: 2026-07-24T08:43:42+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
---

# Monitor must watchdog long/background leaf work — treat leaf silence as suspected failure, never as "still running"

## Overview

During an unattended overnight parallel mission run (the `monitor` command fanning out one `drive` leaf per mission), the orchestrator handed a leaf a long-running live end-to-end verification, told the leaf to run it as a detached background job and "report back when done," and then **passively waited on a leaf→main completion notification as its only signal.** The background job failed **12 seconds** after launch (it wrote a result artifact recording the failure), but the leaf did not send a completion message — it only emitted an idle/available ping. The orchestrator interpreted the absence of a completion notification as "the long job is still running" and **hung for roughly six and a half hours**, until the operator intervened and asked what was taking so long. The failure evidence — a result JSON and a run log — had been sitting on disk the entire time; a single active check would have caught it within minutes.

Two compounding orchestration defects:

1. **No watchdog / fallback heartbeat.** The dispatcher relied entirely on a success-path notification. A leaf that fails fast without reporting, dies, or simply goes quiet produces **no** signal — and "no signal" was silently equated with "progress." There was no scheduled wake-up sized to the job's expected duration, and no active liveness check on wake.
2. **The orchestrator disabled its own oversight.** Having told the leaf "I will not nudge you again — finish at your own pace," it removed the only remaining way it would have looked, converting a monitorable long task into a fire-and-forget with no owner watching.

This is the mirror of a sibling problem already raised (attempt-before-defer): there, leaves gave up too early; here, the dispatcher waited forever. Both come from the same root — **the run's terminal/liveness signals are trusted without verification.** The fix is guidance so the dispatcher actively bounds and inspects long/background work instead of inferring progress from silence.

### The rule the guidance must state

When the dispatcher hands a leaf a long-running or backgrounded task and stops actively driving it:

- **Set a bounded fallback wake-up** sized to the job's longest expected step (not a tight poll — a single fallback that fires if the completion signal has not arrived by then).
- **On wake, verify liveness actively** rather than assuming: inspect the leaf's declared output artifact / run log / the relevant process or container state. A result file that says "failed," an exited process, or a torn-down environment is a **terminal failure to surface**, not a reason to keep waiting.
- **Treat prolonged silence as a suspected fault, never as "still running."** If neither a completion signal nor evidence of progress is present past the bound, investigate — read the artifacts — and classify honestly.
- **A completion signal must cover failure, not only success.** A leaf that launches a background job owns surfacing its *outcome either way*; "I'll report when done" must fire on failure too. The dispatcher should not depend on the leaf being well-behaved — the watchdog is what makes the run robust to a leaf that isn't.

A short operational note belongs alongside this: **a detached/background script does not inherit an interactive shell's PATH or environment.** In this incident the background job also could not find a core CLI (`docker`) because the detached environment lacked the interactive PATH entry — the same class of trap already documented for scheduled jobs. Long background jobs the dispatcher spawns should be given an explicit, self-contained environment, and their early exit is exactly the kind of failure the watchdog must catch.

## Policies

The standard engineering policies — synced from the corporate site into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing and keep every change defensible against that policy's Goal, Responsibility, and Practices.

- `workaholic:development` / `policies/overnight-ai.md` — an unattended overnight run must remain accountable end-to-end; a silent stall that burns the whole window is the exact failure this policy exists to prevent
- `workaholic:operation` / `policies/recovery-and-runtime.md` — liveness must be *observed*, not assumed; the run recovers only if it actively detects a dead/failed leaf and reads the evidence, rather than trusting the absence of a message
- `workaholic:implementation` / `policies/objective-documentation.md` — phrase the watchdog rule and the "silence ≠ progress" classification verifiably in the sections leaves and the dispatcher follow

## Key Files

- `plugins/workaholic/skills/monitor/SKILL.md` — §2 fan-out / §3 loop: add the **watchdog** rule for long/background leaf work (bounded fallback wake-up + active liveness/artifact inspection on wake); state explicitly that a missing completion signal past the bound is a suspected fault to investigate, never evidence of progress; forbid the dispatcher from disabling its own oversight of an unfinished task.
- `plugins/workaholic/commands/monitor.md` — mirror the §2/§3 wording so the command's dispatch instructions match the skill.
- `plugins/workaholic/skills/drive/SKILL.md` — leaf side: a leaf that backgrounds a job must surface its **outcome either way** (failure as well as success) back to its caller; a leaf may not go idle on an unreported terminal result.

## Quality Gate

This ticket predates the mandatory `## Quality Gate` section; its original `## Acceptance Criteria` list is preserved verbatim below as the acceptance criteria, with the verification method and gate recorded at drive time (2026-07-24).

Decided: documentation-only verification — the change mandates no runtime scheduler and alters no script, so the hermetic suite plus the build/verify/metadata trio is the whole provable surface (developer may override at /drive).
Decided: the watchdog is stated as guidance for the dispatcher's existing wake-up mechanism rather than a new script — the ticket's Considerations call for a fallback, not a polling loop, and a bundled poller would be the tight loop it warns against (developer may override at /drive).

**Acceptance criteria** — the checkable conditions that must hold:

- [x] The `monitor` guidance requires a bounded fallback wake-up whenever the dispatcher hands off a long/background task and stops actively driving it, sized to the job's longest expected step.
- [x] The guidance requires **active liveness verification on wake** (inspect the declared artifact / log / process or container state) rather than inferring progress from the absence of a completion message.
- [x] The guidance states plainly that prolonged leaf silence is a **suspected fault to investigate**, never "still running," and that the dispatcher must not disable its own oversight of an unfinished task.
- [x] The `drive` leaf guidance requires a background-job launcher to report its outcome either way (failure included) and forbids idling on an unreported terminal result.
- [x] A brief note captures that detached/background jobs must be given an explicit self-contained environment (they do not inherit the interactive PATH), with early exit being exactly what the watchdog catches.
- [x] `commands/monitor.md` and `skills/monitor/SKILL.md` agree on the reworded §2/§3 guidance.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the hermetic suite, including the existing monitor/drive contract assertions that read these sections.
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` — `drive` is a built skill, so `outputs/workflows/skills/drive/SKILL.md` must regenerate and stay self-contained (`monitor` is Claude-only and not built).
- `node scripts/build-plugins/validate-metadata.mjs` and `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- Suite green, outputs/ rebuilt and fresh, metadata valid, layout conforming, and the three touched documents agreeing on the watchdog rule.

**Result (2026-07-24):** all six criteria met — see the run output recorded in the Final Report below.

## Considerations

- Guidance/documentation change only — no runtime scheduler is being mandated; the fallback wake-up uses the existing wake-up mechanism available to the dispatcher.
- Keep this proportionate: the watchdog is a *fallback*, not a tight polling loop — one bounded check that fires only if the completion signal is absent, so a healthy run pays almost nothing.
- Complements the sibling attempt-before-defer change: together they make both the "gave up too early" and the "waited forever" failure modes explicit.

## Final Report

Development completed as planned. The watchdog landed as a named block in `monitor/SKILL.md` §2 (bounded fallback wake-up → active liveness verification on wake → honest classification of silence), a fourth **Silent** case in the §3 classification, and a leaf-side counterpart at `drive/SKILL.md` §3c; `commands/monitor.md` mirrors both sections. Verified with `node scripts/test-workflow-scripts.mjs` (1301 passed / 0 failed), a clean `build.mjs` + `verify.mjs` regenerating `outputs/workflows/skills/drive/SKILL.md`, valid `validate-metadata.mjs`, and a conforming `layout-doctor.sh`.

### Discovered Insights

- **Insight**: The dispatcher contract already said "never freeze the session in a synchronous wait on the slowest leaf", and that instruction — read alone — is what permitted the six-and-a-half-hour stall.
  **Context**: Non-blocking and unwatched are different properties, but the §2 prose only asserted the first. The watchdog had to be written as the *other half* of that same paragraph, immediately after it, or a future reader draws the same conclusion: that not-waiting is the whole duty. Being non-blocking is what makes the fallback wake-up cheap, not what replaces it.
- **Insight**: The fix needed both a dispatcher-side and a leaf-side rule, because either one alone still leaves a hole.
  **Context**: A well-behaved leaf reporting failures (drive §3c) does nothing when the leaf dies outright; a dispatcher watchdog alone still burns the full bound when the leaf simply forgot to report. The dispatcher rule is deliberately phrased not to depend on leaves being well-behaved — that is precisely what makes the run robust to one that isn't.
- **Insight**: The wave loop's classification trigger was an unstated assumption worth making explicit.
  **Context**: §3 previously classified a wave "when its reports are in", which has no defined behavior when a report never arrives. Stating that a wave classifies on reports-in **or** bound-elapsed-and-verified closes that gap, and the "never let a second bound elapse on the same unverified silence" clause stops a verify step from itself becoming a new wait loop.
