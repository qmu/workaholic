---
created_at: 2026-08-29T19:21:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: follow-the-pull-requests-the-loop-opens-for-a-person
merge_policy:
verification_handoff: 
---

# Report the pull-request reading in the run reports as evidence

## Overview

PROPOSED. `/implement`'s and `/propose`'s run reports name the reading in the voice
`pace`, `overdue` and `expiring` already use: **evidence, never a verdict**. No refusal,
no sort, no `selected` and no token reads it, and the change must be pinned as
byte-identical everywhere else.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a reading is reported where the run is recorded
- `workaholic:design` / `policies/api-design.md` — a reading that gates nothing says so

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §7's run-report contract and its token
  table; the precedents that **move no token** (`backlog_all_excluded`, `base-health`,
  `catch_up_refused: content_conflict`).
- `plugins/workaholic/skills/propose/SKILL.md` — where `pace`, `overdue`, `expiring`,
  `dormant`, `quiescent` and `arrived` are already named as evidence in a run report.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the survey whose
  `refusal`, `pace`, sort and `selected` must be byte-identical across the change.
- `scripts/test-workflow-scripts.mjs` — where the byte-identity pin goes.

## Implementation Steps

1. Add the reading to `/implement`'s run report, once per run rather than once per unit
   — it is one fact about the repository, `base-health`'s own rule — naming each un-acted
   operator-facing pull request, its age and the refusal word that made it the operator's.
2. Add it to `/propose`'s run report in the same voice, beside `arrived` / `expiring`.
3. **It moves no token.** A pull request waiting on a person is not a fact about the unit
   this run drove, so `ok` stays reachable over it — the ground `base-health` and
   `backlog_all_excluded` already stand on. State that in the contract, with the reason.
4. **It gates nothing.** No refusal, no `pace` value, no sort, no `selected` and no
   eligibility reads it; `/propose` keeps proposing against a direction whose ruling is
   unanswered.
5. Pin the byte-identity: a hermetic diff over `survey-strategies.sh`'s output across the
   change, and a test asserting that no script in the driving chain reaches the reader.
6. A degraded read is reported **as degraded** and never as *nothing waiting*.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Both run reports name the reading; a degraded one is named as degraded.
- The reading moves no token: `ok` is reachable over an un-acted operator-facing pull request.
- `refusal`, `pace`, `overdue`, `dormant`, `quiescent`, the sort and `selected` are
  byte-identical across the change.
- No script in the driving chain reaches the reader.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the byte-identical diff and the reachability assertion)
- `sh scripts/e2e/loop-drill.sh verify-propose` unchanged in verdict.

**Gate** — what must pass before approval:

- The suite passes and `sh scripts/e2e/loop-drill.sh verify-all` reports no new failure.

## Considerations

- The tempting error is to withhold `ok` on an un-acted ruling, on the grounds that it
  blocks the queue. It does — and `/implement` may not ask, so a withheld token would
  report a failure hour after hour to a report nobody opens, while the person who can act
  is reached by ticket 3's question. Reporting is the whole licence.

## Final Report

**Implemented.** Both run reports name the reading, in the voice `pace`, `overdue` and
`expiring` already use: **evidence, never a verdict**.

- **`/implement`** (`drive/SKILL.md`): read **once per run, not once per unit** — one fact about
  the repository, `base-health`'s own rule — in §1, and named in §7 beside the base's health.
  Each un-acted operator-facing pull request is named with its number, its age and the
  **refusal word** that made it the operator's. A `merged`/`closed` reading is settled and not
  named; an **`unreadable`** one is named *as unreadable, by its reason*, never as *nothing
  waiting*; a degraded membership read carries no pull list at all and is reported the same way.
- **`/propose`** (`propose/SKILL.md`): the same reading in the same voice, beside `arrived` /
  `expiring`, as a `/propose`-level fact riding no survey row.
- **It moves no token**, stated in the contract with its reason, and added to §7's token table
  as its own row: a pull request waiting on a person is not a fact about the unit this run
  drove. The ticket's Consideration is answered explicitly — a withheld `ok` would report a
  failure hour after hour into a report nobody opens, while the person who can act is reached by
  `/moderate`'s `operator-pull:<number>` question.
- **It gates nothing**: no refusal, no route, no demotion, no claim, no merge, no sort, no
  `selected` and no eligibility reads it.
- **Byte-identity pinned (step 5):** `survey-strategies.sh` is **unmodified** (`git diff` empty),
  so `refusal` / `pace` / `overdue` / `dormant` / `quiescent` / the sort / `selected` are
  byte-identical by construction rather than by assertion; and the suite pins that no script in
  the driving chain reaches the reader, that both documents name the reading, and that both state
  it gates nothing.

**Gate:** `node scripts/test-workflow-scripts.mjs` passes and
`sh scripts/e2e/loop-drill.sh verify-propose` is unchanged in verdict (`pass`).
