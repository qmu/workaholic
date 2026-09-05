---
created_at: 2026-09-06T08:20:31+09:00
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
