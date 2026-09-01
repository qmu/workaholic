---
created_at: 2026-08-26T11:00:16+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826110016-add-the-overdue-reading-to-the-strategy-survey.md
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Add the dormant reading to the strategy survey

## Overview

A live, in-date direction nothing is answering is invisible. It passes every gate, is
eligible on every tick, and a tick that can name no move for it reports
`no_evolutionary_move` into a run report that on the day it matters is read by nobody. Add
`dormant` beside `pace` and `overdue`: a strategy that is `active`, owned, in date and
legible, with **nothing landed in the window**, **nothing waiting**
(`waiting_missions + waiting_count == 0`) and **no open proposal**.

Every term is already computed by the survey or by `attributed-work.sh` beneath it. No new
counter, no new field on any artifact, and no second derivation of `pace`.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a reading that could not be made is named

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — `landed[]`,
  `waiting_missions`, `waiting_count` and the `$held` open-proposal set are all already in
  the row builder's scope.
- `plugins/workaholic/skills/propose/SKILL.md` — the readings' meanings.
- `CLAUDE.md` — the `/propose` row.

## Implementation Steps

1. Re-read the row builder after ticket 1 has landed, so `overdue` and `dormant` sit
   together and are obviously siblings rather than two separately-invented ideas.
2. Derive `dormant` from terms already present: `status == "active"`, `owns == "mine"`,
   `days_to_target != null` and `>= 0`, `unreadable == false`, `(landed | length) == 0`,
   `(waiting_missions + waiting_count) == 0`, and the slug absent from `$held`.
3. Any term that cannot be read makes the answer **not** `dormant` — an unreadable
   attribution must never be reported as a quiet direction, which is the same refusal
   `pace`'s `unknown` already makes.
4. Emit on every row, eligible and refused alike, exactly as ticket 1 does.
5. Change no gate, no refusal, no ordering. Assert it.
6. Update `SKILL.md` and `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An `active`, owned, in-date strategy with nothing landed, nothing waiting and no open
  proposal reads `dormant: true`
- The same strategy with **any one** of those terms non-empty reads `dormant: false`
- An `unreadable` row is never `dormant: true`
- `refusal`, ordering and `selected[]` are unchanged for every input

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — one case per term, each flipping exactly one
  input and asserting the reading moves with it
- A case with an unreadable attribution asserting `dormant: false`

**Gate** — what must pass before approval:

- The suite passes; no existing case's eligibility or order changes

## Considerations

- `dormant` and `late` overlap but are not the same: `late` reads *nothing landed with less
  time remaining than the window*, `dormant` reads *nothing landed, nothing queued and
  nothing proposed*. A direction can be dormant and not yet late.
- Reporting it is not asking about it — that is ticket 4, deliberately separate so the
  reading can land and be argued with before anybody is messaged.

## Final Report

Development completed as planned — the reading was already present on the base when this
ticket was driven and was verified here against its own Quality Gate rather than assumed.

`survey-strategies.sh` derives `dormant` from terms the row already holds: legible, `active`,
`mine`, in date, cited, nothing landed in the window, nothing waiting at either grain, and no
open proposal. Any term that cannot be read makes the answer `false` rather than `dormant`,
which is the refusal `pace`'s `unknown` already makes. It is emitted on every row, and no
gate, refusal or ordering moved.

### Discovered Insights

- **Insight**: `dormant` excludes an overdue row itself, and `direction-state.sh` also ranks
  `overdue` above `dormant` — two independent guards on the same boundary.
  **Context**: Breaking either one alone leaves the reading correct, which is good for
  robustness and misleading for testing: a drill row aimed at the precedence passes even
  when one guard is gone. What a fixture can actually pin here is the term neither guard
  covers, which is the undated case.
