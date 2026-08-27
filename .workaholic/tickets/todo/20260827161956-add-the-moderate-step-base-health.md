---
created_at: 2026-08-27T16:19:56+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827161955-name-the-merge-that-turned-the-base-red.md
mission: read-whether-the-base-survived-what-the-loop-merged
merge_policy:
verification_handoff: 
---

# Add the moderate step base-health

## Overview

<!-- PROPOSED. -->

A red base currently reaches a person through **no path at all**. `/implement` may
not ask anyone anything; `step-stuck-prs.sh` and `step-merge-conflicts.sh` read
**pull requests** and find nothing wrong with a merged one; `step-stalled-units.sh`
reads stale claims and this has no claim. The tick is the one surface that reaches
a person by name, and it has no step that looks at the base.

This adds `base-health` as `/moderate`'s twentieth step: hand a red base to the
check-in as **one question addressed to the attributed merge's author**, keyed
`base-red:<commit>` so an hourly tick asks exactly once however many ticks see it.
It **asks and nothing else** — it never re-runs a check, never reverts, never
merges, never touches a claim.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — degrade by name, never silently

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-base-health.sh` — **new**, the step.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — its `STEPS=` line is the single
  registration point; add `base-health` there, before `human-checkin`.
- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the shape to
  copy. Its header states the three axes a new step must answer (whose question, whether
  the running identity is consulted, what it may read) and this ticket answers them below.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate. Four refusals
  (`quiet_hours`, `answered`, `already_asked`, `tick_cap`, `day_cap`); the key is what
  makes the asked-once guarantee mechanical.
- `plugins/workaholic/skills/drive/scripts/attribute-base-red.sh` — from ticket 2, the
  candidate source.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step list and contract.

## Implementation Steps

1. Read `step-undelivered-units.sh` first, including its header's three-axis table.
   State this step's answers in **its own** header: the question goes to the **attributed
   merge's author** (`stalled-units`' axis — a real person who can act on it); the
   **running identity is never consulted** (`undrivable-units`' axis — a red base is a
   fact about the repository, and an hourly question that answered differently per
   container is the failure that axis exists to prevent); and it reads the ticket-2
   walk, **never `plan-units.sh`**, which stages what its living migrations converge.
2. Call the ticket-2 attribution once per tick and take its `red` answer as the candidate.
3. Key the question `base-red:<attributed commit sha>` — on the **commit**, not on the
   tick, not on the day. That is what makes "exactly once per commit" mechanical rather
   than a rule somebody remembers.
4. Compose the question naming: the commit, its pull request, the failing check names,
   and that a re-run may clear it. Address it to the attributed author.
5. Route it through `ask-question.sh` unchanged, so quiet hours, the working-day hold,
   the per-tick cap, the day cap and the `answered` state all apply with no second ledger.
6. **`unattributable`** still asks — the base is red and that is worth a person's
   attention — but names that the walk could not attribute it, and is keyed on the
   **tip** commit. Decide and state this in the header; do not let it silently vanish.
7. A **degraded** read (`unanswerable`, or the walk refusing) asks **nothing** and is
   reported by name in the step's `summary`. A reading we could not make is not a
   finding about the repository — the rule `direction-health` already holds for
   `unreadable`, and `strategy-pace` for our own degradation.
8. Register `base-health` in `run.sh`'s `STEPS=` line and update the step count in
   `moderate/SKILL.md` (ticket 8 carries `CLAUDE.md`).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- a red base produces exactly one question per commit, addressed to the attributed author
- the same red commit seen by a later tick produces no second question
- a degraded read asks nothing and is reported by name
- the step writes nothing anywhere but its own tick-log line, and never merges or reverts
- `run.sh` invokes it and it contributes a report line whether or not it found anything

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-base-health` (ticket 7) over a stubbed transport
- `node scripts/test-workflow-scripts.mjs`
- reading the step for any write outside `log-append.sh`

**Gate** — what must pass before approval:

- the asked-once gate is proved by two consecutive simulated ticks over one red commit
- no `AskUserQuestion` anywhere in the step

## Considerations

- The step is placed **before** `human-checkin`, like every other question-producing
  step. Note that `human-checkin` is exempt from `--deadline-seconds` and this step is
  not: a slow tick may not reach it, which is reported as unreached, not as green.
- Do **not** re-run a failing check from here. "Flake" is not a root cause and re-running
  is an act; this step's whole contract is that it asks.
- The overlap with a person already watching CI is deliberate and cheap: the asked-once
  key bounds it to one question per broken commit, ever.
