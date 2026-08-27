---
created_at: 2026-08-27T20:21:18+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: ask-for-the-one-act-a-declared-handoff-is-waiting-on
merge_policy:
verification_handoff: 
---

# Stop stalled-units asking about a declared handoff

## Overview

PROPOSED. `step-stalled-units.sh` filters exactly one verdict out of its candidates —
`superseded` — so an `awaiting_verification` claim whose tip has gone stale is handed to the
check-in as *"a claimed unit has not moved for a day or more"*. That is the wrong question: the
unit is not stalled by accident, it was **declared** unverifiable here at creation, and the
person is being sent to look at a claim rather than told the one act it waits on.

Left alone, this is worse than redundant. The asked-once ledger means the real question from
`handoff-units` then arrives beside a differently-worded one about the same unit, inside a
stream a person has learned to skip — the exact cost the `superseded` filter was added for.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a fact belongs in the summary; a question belongs to a person

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — the `finished` /
  `stalled` split (`select(.resume_reason == "superseded")` and its complement) and the
  `summary` line that counts what it does not ask about. Its header records why the
  `superseded` filter exists; this is the same argument one verdict over.
- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — the step that now owns
  the question; the two must not both ask.

## Implementation Steps

1. Reproduce: build a fixture with one stale `awaiting_verification` claim and confirm
   `step-stalled-units.sh` currently emits it in `needs_agent` under `stalled-unit:<unit>`.
2. Filter `awaiting_verification` from the `stalled` candidate set exactly as `superseded` is
   filtered — the same shape, in the same expression, so a reader sees one rule with two
   verdicts rather than two mechanisms.
3. Count it in the summary as its own finding, beside the `superseded` count. A fact belongs in
   the log; only the question moves.
4. Extend the header's *TWO FILTERS, NOT ONE* note to three, naming this verdict, its date and
   the reason: the unit is waiting on a declared act and `handoff-units` asks about it in the
   vocabulary of that act.
5. Confirm the step's `event` still renders nothing when the only claims present are filtered —
   a step with no finding renders no root line.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A stale `awaiting_verification` claim produces no `stalled-unit:<unit>` question
- It is counted in `step-stalled-units.sh`'s summary as a named finding
- A genuinely stale claim carrying any other verdict is asked about exactly as before
- No unit produces two questions in two vocabularies in the same tick

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Run both steps over one fixture holding a stale `awaiting_verification` claim and assert
  exactly one `needs_agent` entry across the pair

**Gate** — what must pass before approval:

- The hermetic suite passes and the ordinary stalled-claim question is unchanged

## Considerations

- Do **not** widen the filter to "any non-resumable verdict". `queue_drained` and
  `report_undelivered` are different states with different owners, and one of them is already
  asked about by its own step; a blanket filter would silently drop a class nobody covers.
- The filter and the new step must be kept honest together: if `handoff-units` ever stops
  asking, this filter turns the finding back into silence. The pin in the mission's later
  ticket is what keeps that pair visible.

## Final Report

**Reproduced first.** Against this repository's own claims with
`WORKAHOLIC_CLAIM_STALE_HOURS=1`, `step-stalled-units.sh` emitted
`stalled-unit:make-workaholify-converge-the-account-s-routines` — the `awaiting_verification`
claim behind PR #647 — under *a claimed unit has not moved for a day or more*.

`awaiting_verification` is now filtered from the `stalled` candidate set **in the same
expression** as `superseded` (`select(.resume_reason != "superseded" and .resume_reason !=
"awaiting_verification")`), so a reader sees one rule with two verdicts rather than two
mechanisms, and it is counted in the summary as its own finding beside the `superseded` count —
a fact belongs in the log; only the question moved. The header's *TWO FILTERS, NOT ONE* note is
now *THREE FILTERS, NOT ONE*, naming the verdict, its date and the reason, and recording that the
filter is **not** widened to "any non-resumable verdict": `queue_drained` and `report_undelivered`
are different states with different owners and a blanket filter would silently drop a class
nobody covers.

Verified over the live claim set at a 1-hour staleness threshold:

- `stalled-units` — `1 awaiting a declared verification`, and its questions are
  `stalled-unit:batch-20260818215156` and `stalled-unit:deploy-the-docs-site-on-merge-to-main`
  only: the genuinely stale claims, asked about exactly as before.
- `handoff-units` in the same tick — one question,
  `handoff-unit:make-workaholify-converge-the-account-s-routines`.
- **Exactly one `needs_agent` entry across the pair for that unit**, in one vocabulary.
- With `n_stalled == 0` the step emits `ok` with an empty `event`, so a tick whose only claims are
  filtered renders no root line.

`node scripts/test-workflow-scripts.mjs` — 4111 passed, 0 failed.
