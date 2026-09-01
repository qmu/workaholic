---
created_at: 2026-08-30T04:28:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: catch-a-reported-claim-up-before-its-conflict-hardens
merge_policy:
verification_handoff: 
---

# Keep one unit to one question

## Overview

PROPOSED. `/moderate`'s `catchup-blocked` step asks the claim holder about a
`content` conflict on a reported claim. Once the run catches a unit up, that unit's
conflict no longer exists — and a question about a conflict the loop just repaired
is exactly the wasted attention this mission exists to stop spending.

The step **filters** such a unit out of its own candidates and **counts** it instead:
the same shape `stalled-units` already uses for `awaiting_verification` and
`superseded` — one step acts and the other filters, and either half alone is a
defect.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-catchup-blocked.sh` — the
  candidate set (`mergeability == "content"` and `resume_reason` in
  `{report_undelivered, queue_drained}`) and its header's recorded reasoning
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — untouched: the key,
  the asked-once gate, the addressee and the per-tick cap do not move

## Implementation Steps

1. Read `step-catchup-blocked.sh` whole, header included: it records why its
   candidate set is the **reading** rather than a pull request's `mergeable: false`,
   and the filter must not disturb that.
2. Filter out a unit whose conflict this run repaired, and **count** it rather than
   dropping it silently — a filtered candidate that vanishes from the summary is a
   finding nobody can see.
3. Move **nothing** else: the key, the asked-once gate, the addressee, the per-tick
   cap, the holds and every other candidate stay byte-identical.
4. The step still **asks and nothing else**: no merge, no rebase, no close, no claim
   touched, no gate lifted.
5. Prefer deriving *repaired* from the claim reading itself over a cross-run store:
   a caught-up branch reads `clean`, so the existing candidate expression may already
   answer it. Measure before adding anything; if it does, say so and change nothing.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit the run caught up draws no `catchup-blocked` question and is counted
- A unit still `content` draws its question exactly once, as today
- The key, the gate, the addressee and the cap are byte-identical
- No new store, cursor or field on any artifact

**Verification method** — the commands/tests/probes that prove them:

- The drill rows added by this mission's last ticket, over two ticks
- `sh scripts/e2e/loop-drill.sh verify-catch-up`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `ask-question.sh` byte-identical

## Considerations

- If the filter turns out to need no code — because a repaired branch already reads
  `clean` and leaves the candidate set on its own — the honest outcome is a recorded
  finding and no change. Say which, rather than adding a filter to have added one.
