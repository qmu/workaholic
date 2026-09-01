---
created_at: 2026-08-27T23:22:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827232222-give-a-refused-delete-its-own-reported-word.md
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Report what stands and what is outstanding

## Overview

A retirement blocked on one act has already taken the other two, and the report does
not say so. `step-retire-claims.sh` renders a refused row as
`<unit> refused (<reason>)` — the acts that **succeeded** are dropped, so a re-run
reads as a re-run of three acts when it is a re-run of one. Measured: three units
whose pull requests were closed days ago still read as bare refusals on every tick.

The retired row already does this correctly (`pr <state>, branch <state>, worktree
<state>`); the refused row is the half that lost it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a report says what is true

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the refused
  row's `line=` expression, which reads only `.reason` today.
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — already emits all
  three act states on every row, so no new field is needed.

## Implementation Steps

1. Render a refused row with all three act states beside its reason, exactly as the
   retired row does — the states are already on the row, so this reads them rather
   than deriving anything new.
2. Keep `already_closed`, `already_gone`, `absent` and `none` reading as the
   successes they are, never as degradations; a row showing `pr already_closed,
   branch failed` is the whole point of the change.
3. Keep `not_attempted` distinct from `failed` and `absent` — a gate that never ran
   made no finding about the world, and the refusal path must keep saying so.
4. Keep the summary **free of any age or timestamp**: the root calls a step changed
   when its summary differs from the same step's an hour ago, and only a timestamp,
   a bare hex object name and a clock time are normalised out. A stable summary is
   what the diff needs, and it is what ticket 6 depends on.
5. Leave the `event` field's rule untouched — a tick that retired nothing supplies
   no event and renders no root line.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A refused row names the acts that stand and the act that is blocked.
- The summary carries no age and no timestamp, so an unchanged condition renders an
  unchanged summary.
- The retired row, the success words and `event` are byte-identical to before.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire`

**Gate** — what must pass before approval:

- Two consecutive runs over an unchanged claim set produce identical summaries.

## Considerations

- This ticket is independent of ticket 3: whether or not a second transport exists,
  a reader must be able to see that two of three acts already stand.
- The stability requirement in step 4 is load-bearing for ticket 6, which keys on
  the diff. Adding a count of hours-blocked here would silently defeat it.

## Final Report

Development completed as planned.

`step-retire-claims.sh`'s refused row renders all three act states beside its reason, exactly as
the retired row already did:

```
batch-blocked refused (branch_delete_failed; pr already_closed, branch failed, worktree absent)
```

The states are already on the writer's row, so this **reads** them and derives nothing new. What
follows from that:

- `already_closed`, `already_gone`, `absent` and `none` render as the **successes** they are — a
  row reading `pr already_closed, branch failed` is the whole point of the change.
- `not_attempted` stays distinct from `failed` and `absent`. A gate that never ran made no finding
  about the world, and the refusal path keeps saying so.
- The retired row, every success word, and `event` are **byte-identical** to before: a tick that
  retired nothing still supplies no event and renders no root line.

**No age and no timestamp** (step 4, and ticket 6 depends on it): every term is a function of the
claim set and the act states alone, so two runs over an unchanged claim set produce identical
summaries. `verify-retire`'s `retire_blocked_summary_stable` row proves it across two consecutive
ticks and fails when a varying term is introduced — verified by prefixing the summary with
`$(date +%s)`, which failed exactly that row.

### Discovered Insights

- **Insight**: the retired row and the refused row were written at the same time and only one of
  them kept the act states. The asymmetry is invisible in the code — the two `jq` expressions sit
  four lines apart — and visible immediately in the log, where a refusal is the row a person is
  actually reading.
  **Context**: the half of a pair that renders the *unhappy* path is the half that gets less
  attention and is read more often. Worth checking both branches of any such pair render the same
  facts.
- **Insight**: a stable summary is load-bearing infrastructure for the root's change diff, not a
  cosmetic preference — and the cheapest way to break it is to add something genuinely useful, like
  how long a block has stood.
  **Context**: the age is not lost; it belongs in the question, which names the unit. The rule is
  *the diff needs a stable string, the person needs the age*, and the two surfaces are different.
