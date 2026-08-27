---
created_at: 2026-08-27T14:24:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827142444-ask-the-operator-once-whether-an-arrived-direction-is-done.md
mission: say-when-a-direction-has-arrived
merge_policy:
verification_handoff: 
---

# Report the arrival as a moderation event

## Overview

PROPOSED. Each `/moderate` step supplies an `event` beside its log-facing `summary`, and the
`🔎 Moderation` root renders the event — because the root names **repository events**, not the
tick's bookkeeping. An arrived direction is a repository event: a direction's work is all in.

Supply it. A tick with **no** arrival renders no line, per the standing no-nothing-happened-line
guard: a step with no event renders nothing, which is the independent protection against a line
announcing that nothing changed.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — where `event` is
  composed today (the `phrase` + `links` construction near the emit).
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the `event` contract.

## Implementation Steps

1. Read how the step composes `event` today, including the `repository == none` override and the
   empty-event path that renders no line.
2. Extend the phrase to name an arrived direction, linking it as the other readings link theirs.
3. Leave `summary` carrying every count, including `unreadable` — the audit trail loses nothing,
   which is the standing split between the two fields.
4. Confirm a tick with no arrival and no other finding still emits an empty `event`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An arrived direction produces a non-empty `event` naming it and linking it.
- A tick with no non-`live` reading produces an empty `event` and therefore no root line.
- `summary` keeps every count it carried before.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The step run over an arrived fixture and over an all-`live` fixture.

**Gate** — what must pass before approval:

- The empty-event path demonstrated, so no "nothing happened" line can reach the root.

## Considerations

- The event is the post-facing phrase and the summary is the log-facing one; keeping the counts out
  of the event is deliberate, not an omission.

## Final Report

Development completed as planned. `step-direction-health.sh` supplies the arrival in `event`:
*a direction has its work in* / *N directions have their work in*, **leading** the phrase in the
reader's own precedence order, then the overdue clause, then the dormant one. Reading an arrival
after a lateness clause about a different direction is how a success gets read as a failure,
which is the defect the reading removes. The links construction was already keyed on
`slug != ""`, so every arrived direction is linked with no change to it.

`summary` keeps every count and gains `arrived` beside live/overdue/dormant/unreadable — the
audit trail loses nothing, which is the standing split between the two fields.

The empty-event path is demonstrated rather than asserted: a tree whose only strategy reads
`live` emits `{"status": "ok", "summary": "1 live, 0 arrived, 0 overdue, 0 dormant, 0
unreadable; repository ok; 0 to ask", "event": "", ...}` through the step's early `emit ok`, so
no root line can be rendered. The `repository == none` override is untouched.

Verified: `node scripts/test-workflow-scripts.mjs` — 4031 passed, 0 failed; the step run over an
arrived fixture (non-empty event naming and linking the direction) and over an all-`live`
fixture (empty event). Both are pinned by `loop-drill.sh verify-arrival`.

### Discovered Insights

- **Insight**: the existing phrase construction assigned the first clause with `phrase="..."`
  and appended later ones with `phrase="${phrase:+${phrase}; }..."`, so inserting a new clause
  **before** the first one silently discards it unless the old first clause is converted to the
  append form.
  **Context**: the two-clause shape hid this — it only breaks when a third clause is prepended.
  Any future reading added ahead of `overdue` must convert its successor the same way.
