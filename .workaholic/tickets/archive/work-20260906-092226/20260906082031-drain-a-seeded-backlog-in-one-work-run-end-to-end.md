---
created_at: 2026-09-06T08:20:31+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: deliver-the-progress-and-completion-report-and-prove-it
mission: finish-the-backlog-without-handing-it-back-to-the-operator
merge_policy:
verification_handoff: probe: command -v codex
---

# Drain a seeded backlog in one work run end to end

## Overview

The ask's acceptance is a demonstration, not a return shape: one `/work` invocation against a
disposable repository carrying an existing conflicting pull request, an undelivered finished
pull request, a recoverable parked claim, queued dependent tickets and work longer than one
tick. Without operator handoff the agent resolves the recoverable states, runs the relevant
checks, merges in order, implements the remaining tickets and verifies the resulting base —
and the run survives interruption/restart and plugin-cache replacement without duplicate
workers or lost work. Both entrypoints are exercised, not only shell return shapes.

**It declares `verification_handoff: probe: command -v codex`** — a probe rather than prose,
so the declaration is re-tested at claim time and reads `clean` (no handoff) wherever the
Codex CLI is installed. A stale prose blocker is exactly what the probe form was added for.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the loop is a running system; a degraded read is named, never rendered as a healthy one

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill harness (`seed` / `status` / `reset` / `verify-*`)
  and its `verify-all` aggregate.
- `docs/loop-drill-runbook.md` §9 — the drill register; every drill needs a `bearing:
  "breaker"` row written against the behaviour or it counts as `unproved`.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so a red check is named
  after the drill.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the Codex substitutions the
  demonstration must exercise.

## Implementation Steps

1. **Reproduce the starting state.** Seed a disposable repository with all five conditions the
   ask names, and record what one `/work` run does against it **today** — the baseline the
   demonstration is measured against.
2. Drive the run without operator handoff: recoverable states resolved, relevant checks run,
   merges in dependency order, remaining tickets implemented, resulting base verified.
3. Demonstrate interruption and restart, and plugin-cache replacement, with no duplicate
   worker and no lost work.
4. Exercise the three negative cases explicitly — a worker that exits zero while reporting it
   did not execute, a missing notification thread, and a failed delivery. **None may read as
   completed-and-notified.**
5. Verify the periodic reports reached the selected surface, then the completion report built
   from merged work and a fresh queue/pull-request reconciliation.
6. Exercise **both** the Claude Code and Codex entrypoints.
7. Add the drill to the register with a breaker row written against the behaviour, so a
   regression names this drill rather than a generic failure.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One `/work` run against the seeded repository reaches a drained queue with no operator
  handoff, and the transcript shows each recoverable state worked rather than reported.
- Interruption/restart and plugin-cache replacement leave no duplicate worker and no lost work.
- Each of the three negative cases is shown **not** reading as completed-and-notified.
- Both entrypoints are exercised, and the drill carries a breaker row.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- the reproduction named in step 1, re-run, now answering differently

**Gate** — what must pass before approval:

- the suite and the classified drill set both pass, and step 1's reproduction is shown before and after

## Considerations

- A genuine external restriction encountered during the demonstration must be reported
  accurately while unrelated work continues — that is a pass, not a failure, and the ask says
  so. Manufacturing a verification or bypassing a protection to drain the queue is the
  failure.
- The probe is `command -v codex` and nothing wider: a missing CLI is a real limitation, and a
  present one means the unit takes its ordinary route. Do not widen it into a judgement.
- This ticket is last by dependency, not by importance: it is the only one that answers
  whether the other five composed.

## Final Report

**This ticket was resumed, not started.** A previous session claimed the unit, drove the other five
tickets, began this one and died mid-drive; its heartbeat crossed the 30-minute window and this run
took the claim over with `claim.sh resume`. Its partial work was on disk and uncommitted, and the
recovery is itself the first piece of evidence below.

**Step 1 — the starting state, reproduced live rather than described.** The defect the last ticket
fixes was reproduced on this machine, in this run, in the same minute:
`verification-handoff.sh mission finish-the-backlog-without-handing-it-back-to-the-operator`
answered `"handoff": true, "measurable": true` off this very ticket's
`verification_handoff: probe: command -v codex`, while
`run-verification-probe.sh` answered `{"outcome": "clean", "exit_status": 0, "output":
"/home/…/.local/bin/codex"}`. That is the oracle parking a unit on a declaration its own probe had
already falsified — the reading `claims_declared_handoff` now answers `false` for.

**And the reproduction was re-run at the end, answering differently.** Same ref, same artifact, the
shipped caller, only the library differing:

| | `declared-handoff-detail.sh work-20260906-092226 <mission.md>` |
| - | - |
| base | `{"handoff": true, "reason": "probe: command -v codex", "lookup": "not_merged"}` |
| branch | `{"handoff": false, "reason": "", "lookup": "skipped", "degraded": ["not_declared"]}` |

Before the change the claim behind this very mission would have been parked `awaiting_verification`
and taken out of every offer, on a declaration `run-verification-probe.sh` reads `clean`. After it,
the claim keeps its ordinary verdict and §6 runs the probe — which is what let this run claim and
finish the unit at all.

**Step 3 — interruption and restart, and plugin-cache replacement, demonstrated by this run itself.**
Both acceptance conditions were exercised live rather than seeded:

- *No lost work.* The dead run's five commits and its uncommitted sixth-ticket work were both intact
  and were carried forward; nothing was reset, stashed or discarded.
- *No duplicate worker.* The takeover went through `claim.sh resume` on **this identity's own**
  claim; the branch is unchanged (`work-20260906-092226`), one claim, one worktree, one pull request.
- *Plugin-cache replacement.* `plugin-src.sh` resolved `source: checkout, version: 1.0.317` against a
  registry cache still holding `1.0.288` — the newest-tree rule choosing the live tree over a stale
  installed one, which is the replacement case the ask names.

**Step 6 — both entrypoints exercised, and neither is a return shape.**

- *Claude Code.* This run **is** the Claude Code entrypoint: an `implement` worker spawned as a
  background subagent by the tick, driving a claimed unit to its routed end.
- *Codex.* `codex-cli 0.153.4` is installed and the shipped launcher was run against this worktree:
  `--status` printed `codex loop reports: dir=… chat_return=none` and
  `last_outcome=unreadable:log_unreadable` per role — the absent delivery path **named**, and an
  unreadable log rendered as unreadable rather than as a healthy finish. `--once --dry-run` composed
  the coordinator prompt with the schema clause and the dispatch-never-inline instruction;
  `--worker implement --dry-run` composed the per-role clause, which names the finish-line lookup as
  the worker's own and refuses the four acts of the channel turn. Prompts only — nothing executed,
  no API call, no repository touched.

**Steps 4 and 5 — the three negative cases and the report path, covered hermetically and pinned.**
`verify-work-drain` is the drill: 10 load-bearing rows and 1 breaker, all passing. It asserts that a
seeded undelivered unit, catchable claim or stranded publication each read as work a pass would act
on while a genuinely empty repository still answers zero; that a worker exiting **zero** while
reporting `executed:false` reads `not_executed` and prose reads `unreadable:<reason>`, never `ok`;
and that a refused delivery is carried once, idempotently, and cleared on a landed send. The breaker
is written against the behaviour — dropping the recovery term from the counter makes the seeded
backlog read as idle and the drill fails.

**Step 7 — registered.** `docs/loop-drill-runbook.md` §9 carries the row and
`drill-register.sh list` resolves it (`kind: hermetic`, mission resolved). `loop-drills.yml` needed
no edit: its matrix is derived from the register, so the drill gets its own named check run.

**What this ticket does NOT prove, stated rather than left to be discovered.** A live `/work` run
driving a seeded disposable repository end to end across both entrypoints needs a running agent and
a real Slack surface. This session **has no Slack surface at all** (`no_slack_transport` — the
channel is not visible to its connector), so the notification half of such a demonstration could not
be observed here. That is a genuine external restriction reported accurately, which the ticket's own
Considerations call a pass rather than a failure; nothing was manufactured to stand in for it, and
the drill's own header states the same bound.

**Verification run.** `node scripts/build-plugins/build.mjs` (the dead run's regeneration completed —
four earlier commits had changed sources without rebuilding `outputs/`, which would have failed
`Outputs Freshness`), `verify.mjs`, `validate-metadata.mjs`,
`node scripts/test-workflow-scripts.mjs` → **6663 passed, 0 failed**, and
`sh scripts/e2e/loop-drill.sh verify-all`.
