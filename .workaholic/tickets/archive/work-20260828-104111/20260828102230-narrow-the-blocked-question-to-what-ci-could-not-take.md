---
created_at: 2026-08-28T10:22:30+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-a-proved-retirement-where-the-write-is-permitted
merge_policy:
verification_handoff: 
---

# Narrow the blocked question to what CI could not take

## Overview

PROPOSED. `/moderate`'s `retire-blocked:<unit>` question exists because Act 2 was refused
and nobody was told. Once CI takes that act, the question must fire **only for what CI
could not take either** — otherwise the operator is asked hourly (well, once per unit,
forever) for an act a workflow was about to perform, which is exactly the noise the
asked-once gate was designed around and worse, because the ask would be wrong.

Everything else about the question is byte-identical: the key `retire-blocked:<unit>`, the
asked-once gate, the addressee (the claim holder), the per-tick cap, the quiet hours and
the working-day hold. Only the **candidate set** narrows.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the `blocked`
  candidate set and its `needs_agent` payload
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate; unchanged
- `plugins/workaholic/skills/drive/reference/claims.md` — *When an act of the retirement is
  refused*; the record of what the question is for
- `.github/workflows/claim-retirement.yml` — what "CI also refused" is read from

## Implementation Steps

1. Read `step-retire-claims.sh`'s `blocked` derivation (`remote_branch_deleted == "failed"`)
   and the `needs_agent` payload it composes, and `ask-question.sh`'s key handling.
2. Decide and implement how "CI has also refused" is known **without a new store** — the
   natural reading is the branch still being on origin after CI has had its turn, which is
   the same `already_gone` / present distinction Act 2 already makes. Do not add a cursor,
   a queue or a field; if no store-free reading is available, report that rather than
   inventing one.
3. Narrow the candidate set to blocked units that reading covers. A unit whose branch CI
   is expected to delete draws no question.
4. Leave the key, the asked-once gate, the addressee, the cap and the holds byte-identical
   — assert this in the suite rather than by inspection.
5. Keep the question's composition exactly as it is: the unit, the **exact branch** left on
   origin, the refusal, and the acts that already stand. A question that does not name the
   branch does not say what to delete.
6. Keep the summary a function of the claim set and the act states alone, so a held block
   still renders identically and a newly blocked unit still moves it.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A blocked unit whose branch CI can still delete draws no question
- A unit CI also refused draws exactly one, keyed `retire-blocked:<unit>`
- Key, asked-once gate, addressee, per-tick cap, quiet hours and working-day hold are
  byte-identical to today
- The question still names the unit, the exact branch, the refusal and the acts that stand
- No new store, cursor or artifact field

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire` — including its two-tick asked-once assertion

**Gate** — what must pass before approval:

- Both pass, and a fixture shows one unit asked about once and a second, CI-deletable one
  never asked about

## Considerations

- The narrowing must not become a **suppression list**. Every term stays a function of the
  claim set and the act states; that is what keeps a newly blocked unit visible the hour it
  appears.
- If the store-free reading turns out not to exist, the correct outcome is to report that
  and leave the question exactly as it is — an over-eager question is better than a
  silently dropped one, and this repository has measured the cost of a blocked act nobody
  was told about.

## Final Report

Development completed as planned.

A store-free reading exists, and it is `drive/scripts/ci-retirement-turn.sh`: CI *deletes* the
branch when it succeeds and unmerged remote branches are the only claim oracle, so a successful
turn removes the claim row and the candidate with it. A **completed run at the base tip the tick
is reading** therefore means CI saw exactly this tree and the branch survived it. Three values —
`taken` asks, `pending` suppresses the ask for that tick only, `unavailable` (no such workflow
here) asks — and both an unreadable read and a repository without the workflow leave the question
exactly where it was, on the ticket's own rule that an over-eager question beats a silently
dropped one.

Only the candidate set narrowed. The key `retire-blocked:<unit>`, the asked-once gate, the
addressee (the claim row's own `author`), the per-tick cap, the quiet hours, the working-day hold
and the question's composition are byte-identical, asserted in the suite rather than by
inspection. The summary deliberately carries **no** CI term, so a held block still renders
identically tick after tick and a newly blocked unit still moves it.

### Discovered Insights

- **Insight**: matching the workflow run's `head_sha` against the base tip is a strictly better
  reading than "a run newer than the branch's last commit". A claim becomes superseded when the
  **base** moves, which can happen long after the branch tip stopped moving — so a timestamp
  comparison answers a proxy question, and it needs a clock, a timezone and date parsing that
  `head_sha` does not.
  **Context**: worth keeping if this reading is ever extended; the time-based form looks
  equivalent and is not.
- **Insight**: putting the CI reading into the step's `summary` would have been the obvious way
  to make a suppression visible, and it silently breaks the held-block stability rule — `ci_turn`
  flips as `main` moves, so a standing block would read as an hourly change.
  **Context**: the reading therefore moves in and out of `needs_agent` and nowhere else, which is
  what the ticket's own step 6 asked for and why the suppression is invisible in the log by design.
