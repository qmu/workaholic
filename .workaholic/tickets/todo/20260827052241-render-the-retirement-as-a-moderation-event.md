---
created_at: 2026-08-27T05:22:41+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Render the retirement as a moderation event

## Overview

PROPOSED. Every `/moderate` root line names a **repository event**, not the tick's
bookkeeping (2026-08-23): each step supplies `event` beside its log-facing `summary`, and the
root renders the event. A step with no event renders no line — the independent guard against
a nothing-happened line reaching the root.

A retirement is a repository event: a pull request was closed, a branch deleted, a worktree
reaped. Ticket 5's step must supply an `event` naming what it retired, and a tick that
retired nothing must render **no line at all**.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — supplies the `event`.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — reads `summary` for the diff and
  `event` for the root.
- `plugins/workaholic/skills/moderate/SKILL.md` — the event contract and the no-event rule.
- Any existing step that supplies an `event`, read as the shape to match.

## Implementation Steps

1. Read the whole of `moderate/SKILL.md`'s event record, including why the **step** supplies
   the event rather than the renderer deriving it, and why the diff still reads `summary`.
2. Supply `event` from the step when it retired at least one claim: what was retired, at a
   grain a person reading the root can act on or ignore.
3. Supply **no** `event` when the tick retired nothing — including a tick that found
   `superseded` rows and had every re-proof reject them. Nothing happened to the repository.
4. Keep `summary` audit-facing and unchanged in purpose: it is what the hour-to-hour diff reads,
   so it may name counts the event does not.
5. Keep the summary free of a timestamp or a bare hex object name, so the diff over a stable
   form is not defeated by construction.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick that retired ≥1 claim renders a root line naming what was retired.
- A tick that retired nothing renders no line from this step, in every case.
- The tick log's `summary` still carries the step's audit detail.
- The summary contains nothing that changes every tick by construction.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire` (ticket 7), asserting both the line and its absence.

**Gate** — what must pass before approval:

- Both the retired and the retired-nothing cases are asserted, not just the first.

## Considerations

- The failure this rule exists against: a line reading `no new documentation drift` announced
  that nothing happened while the diff rendered it as a change.
- The root posts only when the tick has a question. A retirement carries none, so this line is
  visible on a root some other step's question already opened — which is correct, and worth
  stating in the step's header so a later reader does not treat the line as a posting gate.
