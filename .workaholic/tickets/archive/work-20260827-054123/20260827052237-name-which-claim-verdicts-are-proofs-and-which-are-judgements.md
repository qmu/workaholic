---
created_at: 2026-08-27T05:22:37+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Name which claim verdicts are proofs and which are judgements

## Overview

PROPOSED. The claim oracle emits a verdict word per row, and two of those words are
**proofs** — a reading the tree or a merged pull request established — while the rest are
**judgements**, a reading that says *look at this*. Nothing writes that distinction down,
so each consumer that wants to act on a verdict must re-derive which ones are safe to act
on. The two consumers this mission adds (the delivery retry, the retirement writer) would
each carry their own copy, and two copies of a rule are how the rule drifts.

`superseded` and `report_undelivered` are proofs. `stale`, `queue_drained`,
`report_incomplete`, `ambiguous_claim` and `unanswerable` stay judgements, and a judgement
is still a person's or a takeover's business.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the one scan that computes every
  verdict word; the table keys on what it already emits and adds no new derivation.
- `plugins/workaholic/skills/drive/reference/claims.md` — the claim protocol's full record;
  the table's home, beside the verdicts it classifies.
- `plugins/workaholic/skills/drive/SKILL.md` — states the model once; names the split.
- `CLAUDE.md` — the Claim protocol section, updated in the same change.

## Implementation Steps

1. Read `lib/claims.sh`'s verdict chain end to end and list every word it can emit, so the
   table is keyed on the actual set rather than on the words this ticket names.
2. Write the table in `drive/reference/claims.md`: one row per verdict word, each classified
   `proof` or `judgement`, each with the one sentence saying what established it and what a
   consumer may therefore do.
3. State the rule the table encodes: a consumer may **act** on a proof and may only **report**
   or **ask about** a judgement. Name why `unanswerable` is a judgement — it is the absence of
   a reading, and acting on an absence is the failure the three-valued lookup exists to avoid.
4. Reference the table from `drive/SKILL.md`'s Claims section and from `CLAUDE.md`, so a
   consumer arrives at it from either entrance.
5. Add no field to any artifact and no new script: the classification is prose over a word
   `lib/claims.sh` already emits.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every verdict word `lib/claims.sh` can emit appears in the table exactly once.
- `superseded` and `report_undelivered` are the only rows classified `proof`.
- No new frontmatter field, no new script, no second derivation of a verdict.

**Verification method** — the commands/tests/probes that prove them:

- Read the verdict chain and diff its word set against the table's rows by hand.
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The table and `lib/claims.sh` agree on the word set, and the two consumers this mission
  adds read the table rather than restating it.

## Considerations

- The table is documentation, and documentation cannot enforce itself. That is why ticket 8
  pins the split mechanically; this ticket is the source that test reads against.
- Adding a machine-readable classifier function to `lib/claims.sh` is the tempting
  alternative. Weigh it against the mission's own rule that a consumer keys on the word:
  a function that returns `proof`/`judgement` is a second derivation of the same fact.

## Final Report

Development completed as planned.

The verdict chain in `lib/claims.sh` was read end to end and the table keyed on the word set it
actually emits, not on the seven words the Overview named. That set is larger than the ticket
assumed: the resumability verdict alone emits ten words (`identity_unresolved`,
`foreign_identity`, `shallow_history`, `claim_active`, `superseded`, `report_undelivered`,
`queue_drained`, `report_incomplete`, `parked_with_pr`, `heartbeat_lapsed`), beside the `stale`
boolean, the merged lookup's three values (`merged` / `not_merged` / `unanswerable`) and the
five unit-resolution words (`none` / `single` / `live` / `superseded_only` / `ambiguous`).
Nineteen rows in three tables grouped by which reading emits them, each classified and each
carrying the sentence saying what established it and what a consumer may therefore do.

`superseded` and `report_undelivered` are the only rows classified `proof`. No frontmatter field
was added, no script was written, and no classifier function was added to `lib/claims.sh` — the
Considerations named that alternative and it is refused in the table's own text, because a
function returning `proof`/`judgement` is a second derivation of the fact the table exists to
hold once.

### Discovered Insights

- **Insight**: The unit-resolution words (`none` / `single` / `live` / `superseded_only` /
  `ambiguous`) sit on a different axis from the resumability verdict — they answer *which row a
  writer may read*, never *is this unit's work finished*.
  **Context**: Flattening them into one list would have made `live` look like a licence to act,
  when what it licenses is reading that row's own verdict. The table keeps them in a separate
  section that says so, which is what stops a later consumer from acting on the resolution word
  instead of the verdict behind it.

- **Insight**: Three of the judgements — `identity_unresolved`, `shallow_history` and
  `unanswerable` — are the **absence** of a reading rather than a reading that says *look at
  this*.
  **Context**: They are the strongest argument for the split's direction: acting on an absence is
  the exact failure the three-valued merged lookup was designed to avoid, and stating the reason
  per row means a later change cannot promote one to a proof without contradicting the sentence
  beside it.

- **Insight**: An absent merge-outcome section keeps `queue_drained` rather than producing a
  third word.
  **Context**: `report_undelivered` is claimed only on positive evidence, so `queue_drained` is
  *not* "the merge was not refused" — it is "no refusal was recorded". The table states this,
  because a consumer reading it as proof of delivery would act on silence.
