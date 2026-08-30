---
created_at: 2026-08-30T08:22:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Correct the settled-by-the-push premise

## Overview

`drive/reference/claims.md` states, in two places, that *the protocol settles a race by the push,
so the state cannot arise from the sanctioned path*. **Read against the mechanism, that premise is
true for one path and false for the other**, and the false half is load-bearing: `ambiguous_claim`
is *reported, never picked between* on the strength of it.

Measured: `claim.sh resume` pushes an empty `Resume a PR-unit` commit onto a branch that **already
exists**, so two takeovers of one unit contend on **one ref** and the second is rejected
non-fast-forward — the premise holds exactly as written (`claim.sh` §5, `resume_race_lost`). A
**fresh** claim mints `work-$(date +%Y%m%d-%H%M%S)` in `branching/scripts/create.sh` and pushes
`-u`, so two runners that survey before either pushes contend for **nothing**: both pushes succeed,
on different refs, and `branch_collision` fires only in the narrower same-second case.

This ticket corrects the document. It changes no behaviour — tickets 3–5 do that — and it comes
first so the rule and the mechanism stop disagreeing while the repair is being written.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — the record states what is true now

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — lines carrying the premise (the two-live-claims paragraph and the `ambiguous` row of *Proofs and judgements*)
- `plugins/workaholic/skills/drive/scripts/claim.sh` — the two paths, one of which does contend
- `plugins/workaholic/skills/branching/scripts/create.sh` — the clock-derived branch name
- `CLAUDE.md` — the claim-protocol section repeats the premise verbatim and must move with it

## Implementation Steps

1. Read the **whole** of `drive/reference/claims.md` before editing: the premise appears in more
   than one place and the two occurrences are about different questions (`claims_unit_resolution`'s
   `ambiguous` and the *Proofs and judgements* table row).
2. State what the measurement showed, in the document's own voice and with its date: the premise
   holds for `resume` (one ref, non-fast-forward arbitration) and **did not** hold for a fresh
   claim (clock-named ref, no contention), with the 2026-08-30 pair named as the measurement.
3. State what the claim **must** contend for — one ref per unit — as the property the repair
   delivers, so ticket 3 has a written target rather than an inferred one.
4. Leave `ambiguous_claim`'s behaviour untouched and say so: it stays **reported, never picked
   between**, and its justification becomes *the repair makes this unreachable from the sanctioned
   path*, rather than the assertion that it already was.
5. Update `CLAUDE.md`'s claim-protocol section in the same commit, per this repository's
   same-change documentation rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The document names both paths and says which one the premise described.
- The 2026-08-30 measurement is named with both branch names.
- `ambiguous_claim`'s standing (reported, never acted on) is unchanged in behaviour and restated in reasoning.
- `CLAUDE.md` carries the same correction.

**Verification method** — the commands/tests/probes that prove them:

- `grep -n "settles a race by the push" plugins/workaholic/skills/drive/reference/claims.md CLAUDE.md` returns no uncorrected occurrence.
- `node scripts/test-workflow-scripts.mjs` passes (the proofs-and-judgements pin reads this file).

**Gate** — what must pass before approval:

- No verdict word is added or removed, and no behaviour moves in this ticket.

## Considerations

- **The pin reads this document.** `test-workflow-scripts.mjs` fails when the proofs-and-judgements
  tables and their enumerated consumers disagree about a word; the correction is prose *around* the
  tables, so the tables' rows must be left keyed exactly as they are.
- The temptation is to reclassify `ambiguous` while touching it. Resist: it is a judgement because
  it is the absence of a settled reading, which the repair does not change.
