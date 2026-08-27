---
created_at: 2026-08-27T20:21:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: ask-for-the-one-act-a-declared-handoff-is-waiting-on
merge_policy:
verification_handoff: 
---

# Pin the new consumer as report-and-ask only

## Overview

PROPOSED. `drive/reference/claims.md`'s *Proofs and judgements* table classifies
`awaiting_verification` as a **judgement**, so a consumer may only report it or ask about it —
never close, delete, merge, retire or otherwise act on it. That is prose, and prose cannot
enforce itself: the hermetic pin exists precisely because nothing else stops a later change from
acting on a judgement. `handoff-units` is a new consumer of that verdict and must be enumerated
in the pin as a **reporting** consumer, with the suite failing if it ever reaches an acting call
site.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` — a rule stated in prose that a change can silently break is pinned

## Key Files

- `scripts/test-workflow-scripts.mjs` — the proof/judgement pin (~line 23706, the section
  header records why it exists) and `testProofJudgementSplit` in the suite list (~16770).
- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*, the single
  home of the classification; the `awaiting_verification` row (~278) already states the trap.
- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — the consumer being
  enumerated.

## Implementation Steps

1. Read the existing pin end to end before editing — the whole section, not the assertion that
   looks nearest. It already enumerates the delivery retry and the retirement writer as acting
   consumers of the two proofs and covers the base-health sub-table; the shape for a
   **reporting** consumer is what this ticket adds or reuses.
2. Enumerate `step-handoff-units.sh` as a reporting consumer of `awaiting_verification`, and
   assert it reaches **no** acting call site: nothing that merges, closes a pull request,
   deletes a branch, retires a claim, resumes, or releases.
3. Assert the classification itself has not moved — `awaiting_verification` is still a
   `judgement` in the table — so a later change that promoted it to a proof fails here rather
   than silently licensing action.
4. Assert `step-stalled-units.sh` no longer asks about the verdict, so the pair from the third
   ticket cannot drift apart: one step asking and the other filtering is the invariant, and
   either half alone is a defect.
5. Add no classifier function and no field on any artifact — the table is the one place the
   classification lives, and a second derivation is exactly what it exists to prevent.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The suite fails if `step-handoff-units.sh` reaches an acting call site
- The suite fails if `awaiting_verification` is reclassified away from `judgement`
- The suite fails if `stalled-units` starts asking about the verdict again
- No classifier function or artifact field was introduced

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Deliberately break each invariant in a scratch copy and confirm the suite fails on each —
  a pin nobody has seen fail is a pin nobody knows works

**Gate** — what must pass before approval:

- All three deliberate breaks are observed to fail the suite, and the suite passes unbroken

## Considerations

- The tempting error the table already records: `awaiting_verification` is read straight off
  the tree, which *looks* like `superseded`'s property. It is not — a proof cannot become false
  by looking again, and this one is designed to, because driving the declared ticket releases
  it. The pin must not be written in a way that blesses acting on it.
- Keep the assertion keyed on the verdict word the scripts emit, not on a step name spelled
  twice; a renamed step should still be covered.
