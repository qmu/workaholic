---
created_at: 2026-08-27T01:20:38+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Ask a person about a unit that could not be delivered

## Overview

`/implement` may not ask anyone anything, so a run report is where an undelivered unit's story
ends. `/moderate` is the one surface that reaches a person by name, and none of its steps sees
this: `step-stuck-prs.sh` and `step-merge-conflicts.sh` read pull requests and `step-stalled-units.sh`
reads the claim oracle's **stale** rows — an undelivered unit is neither stuck nor stale, because
its claim reported and its pull request is green.

Add a step that hands every unit the loop finished and could not deliver to the check-in as a
question addressed to the claim holder, keyed once per unit through the existing asked-once gate,
naming the pull request, its age and the refusal. Never a count addressed to nobody — that is the
property both retired status roots lacked.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a finding reaches a person or it is not
  delivered

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — the closest sibling: reads
  `list-claims.sh`, hands rows to the check-in keyed `stalled-unit:<unit>`. **Read its header
  whole** — the threshold reuse argument and the "no age, no timestamp in the summary" correctness
  rule are both stated there and both apply here.
- `plugins/workaholic/skills/moderate/scripts/step-undrivable-units.sh` — the other precedent: a
  repository-scoped finding that never consults the running identity, and its refusal to reach
  `plan-units.sh` because the survey **stages** what its migrations converge.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the asked-once gate, the per-tick
  cap, the quiet hours and the working-day hold.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — step registration; every step contributes a
  report line and supplies `event` beside `summary`.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step list and the posting rules.

## Implementation Steps

1. Read `step-stalled-units.sh` and `step-undrivable-units.sh` in full, and state which of the two
   this step follows on each axis: whose question it is, whether it consults the running identity,
   and what it may read.
2. Derive the candidate set from the first ticket's reader plus the split reason — **not** from
   `plan-units.sh`, which stages what its migrations converge and is refused to a step whose
   contract is *writes nothing* (the reason `closable-missions` records).
3. Key each question `undelivered-unit:<unit>` through `ask-question.sh` so the asked-once gate,
   the cap, the quiet hours and the working-day hold all apply unchanged and no second ledger
   exists.
4. Address it to the **claim holder**, and name the pull request, its age and the refusal in the
   question body.
5. Register the step in `run.sh` with its `summary` and `event`, and report a degraded read by
   name rather than as a step that ran and found nothing.
6. Update `moderate/SKILL.md` and `CLAUDE.md`'s `/moderate` row (including its step count) in the
   same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An undelivered unit produces exactly one question, addressed to its claim holder, naming the
  pull request and the refusal.
- A second tick over the same unit asks nothing.
- A degraded read asks nothing and is named.
- The step writes nothing outside the tick log and reaches no writing reader.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Run the step twice over a fixture and confirm one question, then none.

**Gate** — what must pass before approval:

- The hermetic suite passes; `git status` is clean after the step runs.

## Considerations

- The summary must carry no age and no timestamp, for the correctness reason
  `step-stalled-units.sh`'s header records — a per-tick-varying summary breaks the root's
  changed-step diff by construction.
- The question is the delivery. A root line without it reproduces the status-line-addressed-to-
  nobody shape this repository has retired twice.

## Final Report

Development completed as planned.

**Which sibling it follows, stated per axis** (step 1, and the ticket required it explicitly):

| Axis | Follows | Why |
| ---- | ------- | --- |
| whose question | `stalled-units` | the claim holder is a real person who drove this unit and can retry its merge |
| the running identity | `undrivable-units` | never consulted — the claim's own `author` is the addressee, so an hourly repository-scoped question does not answer differently per account |
| what it may read | `undrivable-units` | `list-claims.sh` is a pure read; `plan-units.sh` is refused, because the survey reaches the mission readers, which carry the living migrations and **stage** what they converge |

The candidate set is the sibling ticket's split reason (`report_undelivered`) and the refusal
rides on the claim row as `merge_outcome` — surfaced by `list-claims.sh` through the same
`claims_merge_outcome` the oracle already calls, so no second derivation exists to drift. The
pull request's coordinates cost one `claim-merged.sh` lookup **per candidate**, and an
`unanswerable` read leaves them unstated rather than dropping the finding: the unit is
undelivered whether or not we could name its URL.

The summary carries no age and no timestamp, for the correctness reason `stalled-units`' header
records, and the step registers in `run.sh` beside `undrivable-units` — eighteen steps now, with
the count corrected in `moderate/SKILL.md`, its `reference/workflow.md` and `CLAUDE.md`.

### Discovered Insights

- **Insight**: The claim row was the right place to carry the refusal, and the TSV was not.
  **Context**: `claims_scan`'s row has a load-bearing field count — the library's longest
  warning is about what happens when a column is added, and an empty middle field silently
  shifts every field after it. `merge_outcome` is only ever wanted by a caller rendering the
  operator's view, so `list-claims.sh` reads it per row with a `git cat-file` over a blob the
  scan already reached: no new column, no network call, and one derivation.

- **Insight**: An `unanswerable` coordinate lookup must not drop the candidate, and that is a
  different rule from `claim-merged.sh`'s own.
  **Context**: The three-valued contract exists because a wrong `merged` releases work still in
  flight — there, an unread answer must not change the verdict. Here the verdict is already made
  offline by the oracle, and the lookup only decorates the question. Applying the same "leave it
  alone" instinct to the candidate itself would have suppressed the finding on exactly the runs
  where the network is worst, which is the opposite of what the contract is for.
