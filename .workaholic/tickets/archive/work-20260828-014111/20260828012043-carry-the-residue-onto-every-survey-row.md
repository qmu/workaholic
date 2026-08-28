---
created_at: 2026-08-28T01:20:43+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-what-the-direction-could-not-see-before-calling-it-arrived
merge_policy:
verification_handoff: 
---

# Carry the residue onto every survey row

## Overview

`survey-strategies.sh` carries the residue on **every** surveyed row — eligible and refused
alike — and **no gate, no `pace`, no `overdue`, no `dormant`, no `quiescent`, no sort and no
`selected` moves**. That discipline is not new: `overdue`, `dormant` and `quiescent` each
shipped under it, each computed before `refusal` so the refusal expression stays
byte-identical.

The refused case is the point. A direction refused `past_target_date` is exactly the one
whose residue the operator must still see, because that is the direction they are about to
be asked to re-date or close.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the row gains the residue; read its header and the `overdue`/`dormant`/`quiescent` blocks first
- `plugins/workaholic/skills/strategy/scripts/unattributed-work.sh` — the reader composed here
- `plugins/workaholic/skills/propose/SKILL.md` — the survey's output contract
- `scripts/test-workflow-scripts.mjs` — the byte-identity pin
## Implementation Steps

1. Read the `overdue`, `dormant` and `quiescent` blocks in `survey-strategies.sh`. Each
   states why it is computed before `refusal` and why it is emitted on both row sets; this
   ticket follows the same shape and adds nothing else.
2. Call `unattributed-work.sh` **once per survey run**, not once per row — the residue is a
   fact about the repository, not about a direction — and put the same answer on every row.
3. Emit it as its own field carrying the reader's `readable`, its reason, the mission slugs
   and the counts. Do not fold it into `pace` or any existing field: one field answering two
   questions is how the two drift (`overdue`'s own reasoning).
4. Pin byte-identity: over a fixture, `refusal`, `pace`, `overdue`, `dormant`, `quiescent`,
   the sort order and `selected` are identical with and without the residue present.
5. Document the field in `propose/SKILL.md`'s output contract beside the other readings.
## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every row in `eligible[]` and `refused[]` carries the residue.
- The residue read runs once per survey, not once per row.
- `refusal`, `pace`, `overdue`, `dormant`, `quiescent`, the sort and `selected` are
  byte-identical to their pre-change values over the same fixture.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic case diffs the survey's gate-bearing fields with and without the residue and
  asserts they are unchanged.
- A case asserts a **refused** row carries the residue.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- No gate gained a term and no new refusal reason exists.

## Considerations

- The survey already makes one network call (`list-open-proposals.sh`). The residue read is
  local, so this adds none — keep it that way, and keep `--open-proposals` passing a held
  read through.
## Final Report

Development completed as planned.

`survey-strategies.sh` reads `unattributed-work.sh` **once per survey run** — the residue is
a fact about the repository, not about a direction — and puts the same object on every row,
eligible and refused alike. It is its own field (`readable`, `reason`,
`missions: [{slug, queued}]`, `mission_count`, `ticket_count`), never folded into `pace` or
any existing one, and it is computed before `refusal` so that expression stays
byte-identical. The read is local, so the survey still makes exactly one network call and
`--open-proposals` still passes a held read straight through.

A hermetic case diffs `selected`, the eligible order, every refusal, `pace`, `overdue` and
`dormant` with the residue present and emptied, and asserts they are unchanged; a second
asserts a **refused** row carries it.

### Discovered Insights

- **Insight**: `refused` maps an explicit field list, so a new row field reaches the eligible
  rows for free and the refused rows only if it is named there. The refused row is the one
  that matters here — an arrived direction past its date is refused `past_target_date` — so
  omitting it would have silently dropped the field on exactly the case it exists for.
  **Context**: the same trap `landed_count` and `target_date` fell into on 2026-08-27 and were
  added to that map for.
