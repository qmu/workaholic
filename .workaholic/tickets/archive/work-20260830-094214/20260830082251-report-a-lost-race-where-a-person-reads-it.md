---
created_at: 2026-08-30T08:22:51+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Report a lost race where a person reads it

## Overview

**No run report, no `/moderate` step and no claim verdict names *this unit was driven twice*.** The
run that lost reported an ordinary undelivered unit, and the hour of duplicated implementation is
recorded nowhere.

Two surfaces, on the pattern this repository already uses for every other blocked state: the run
**reports** and `/moderate` **asks**. `/implement` may not ask, so a run that loses a race names it
as its own outcome rather than as an ordinary refusal; and a race that already happened — a unit
with two branches, one of them retired-by-content — reaches a person through one question keyed per
unit, naming **both** branches, addressed to the claim holder, asked exactly once.

Neither surface gates, merges, closes, reverts or touches a claim. Reporting and asking is the whole
licence, exactly as `base-health`, `operator-pulls` and `handoff-units` are bounded.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` §7 — the run report's contract and its token table
- `plugins/workaholic/skills/moderate/scripts/` — the new step, beside `step-stalled-units.sh` and `step-undelivered-units.sh`
- `plugins/workaholic/skills/moderate/scripts/run.sh` — `STEPS`, which fixes the step ids
- `plugins/workaholic/skills/moderate/scripts/lib/` — `ask-question.sh`'s key, cap and hold, all unchanged
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the finding classification table, keyed on step id
- `plugins/workaholic/skills/drive/reference/claims.md` — where the reading is classified

## Implementation Steps

1. Decide **where the reading comes from** before writing either surface, and derive it once: a
   raced pair is two claims resolving to one unit, one of which ticket 6 now reads `superseded`
   while the other is live or reported. Read it through `lib/claims.sh`'s existing unit resolution —
   never a second walk, and never a stored field on any artifact.
2. **Run report** (`/implement` and `/drive` alike): a run whose own claim was refused by ticket 4's
   word names it as its own outcome, with both branches, rather than reporting an ordinary refusal.
   Follow §7's existing precedent for what moves the token: this **moves no token** — the run wrote
   nothing and the protocol worked — and it is named as evidence, in the voice `backlog_all_excluded`
   and `base-health` are named in.
3. **`/moderate` step**: one question per raced unit, keyed `<unit>` so it is asked exactly once
   however many ticks see it, addressed to the **claim holder** (the axis `stalled-units` and
   `undelivered-units` use), naming both branches and which one landed. `ask-question.sh` gains
   **nothing** — no key, cap or hold moves.
4. Do not double-ask: a raced loser that ticket 6 now reads `superseded` is already filtered out of
   `stalled-units`' candidates and retired by `retire-claims`. Decide explicitly which step owns the
   raced unit's question and make the other filter it and **count** it, on the
   `handoff-units`/`stalled-units` precedent — one step asks and the other filters, and either half
   alone is a defect.
5. Classify the new step id in `moderate/reference/workflow.md`'s finding table; an unclassified id
   reads `needs_ruling` by design, so leaving it out is silent rather than wrong, but it must be
   deliberate.
6. Classify the reading in `claims.md` beside the other vocabularies: every value here is a
   **judgement** (a claim set is re-read every tick and can change between two reads), with its
   consumers enumerated by name and the suite pinning it both ways.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A run that loses a race names it in its report, with both branches, and moves no token.
- `/moderate` asks once per raced unit, addressed to the claim holder, naming both branches.
- One raced unit never draws two questions in two vocabularies.
- `ask-question.sh` is byte-identical; no key, cap or hold moved.
- The reading is classified as a judgement with its consumers enumerated, and nothing merges, closes, reverts, gates or touches a claim.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-claim-race` asserts the question fires once over two ticks and that the sibling step is silent on the same unit.
- `sh scripts/e2e/loop-drill.sh verify-all` passes.
- `node scripts/test-workflow-scripts.mjs` passes (the tables' pin, both directions).

**Gate** — what must pass before approval:

- The race reaches a person exactly once, and the reading gates nothing.

## Considerations

- **The doubling risk is real**: `stalled-units`, `undelivered-units`, `retire-claims` and
  `catchup-blocked` can all see a raced pair. Step 4 is the ticket's hardest judgment and must be
  settled explicitly, not left to whichever step runs first.
- Resist adding a token row. A run that lost a race wrote nothing and the protocol worked; making it
  `pending` would report a failure on exactly the runs where the repair did its job.

## Final Report

Both surfaces shipped. The `/moderate` half is the ticket as written; the run-report half is the
ticket's intent sourced from a refusal that exists, and the substitution is stated here rather
than left to be discovered.

**The `/moderate` step.** `drive/scripts/list-raced-units.sh` is the reader — composing
`list-claims.sh` (one walk of the refs) and `lib/claims.sh`'s own `claims_unit_resolution`, with
no new verdict word, no second walker, no store and no field on any artifact — and
`moderate/scripts/step-raced-units.sh` asks the claim holders, keyed `raced-unit:<unit>`, naming
**both** branches with their verdicts and picking between neither. `ask-question.sh` is
byte-identical: no key, cap or hold moved.

**Step 1's judgement, made explicitly.** The candidate set is `ambiguous` — two or more *live*
claims — and **nothing else**. The ticket's own wording ("one of which reads `superseded` while
the other is live or reported") describes the *aftermath*, and that shape is byte-identical to
the **sanctioned** recovery in which a `superseded` claim's work is resurveyed and taken on a
fresh claim (`plan-units.sh`'s `resurveyed[]`). Separating a race from that recovery needs either
a clock threshold between the two claims' creation times or a field stored on an artifact, both
of which this repository refuses by name — so the aftermath is left where it is already handled
(the loser reads `superseded`, `retire-claims` retires it, `stalled-units` counts it) and this
reading answers only the state in which a person can still act. Recorded in the reader's header
and in the classification table, not just here.

**Step 4's judgement, settled explicitly for all four candidates.** `raced-units` asks;
`stalled-units`, `undelivered-units` and `catchup-blocked` filter and count, through one shared
`moderate/scripts/lib/raced-units.sh` over the scan each step has **already** made — no second
walk of the refs, and no second definition of a race, which is how a filtering step would start
disagreeing with the step that asks. `retire-claims` needs no change and gets none: its
candidates are `superseded` rows and an `ambiguous` unit has none **by definition**, so the two
sets are disjoint by construction.

**Step 2, and the one substitution.** Acceptance criterion 1 says a run that loses a race names
it "refused by ticket 4's word". That word rests on an arbitration this container cannot perform
— re-measured this run, `git push` to `refs/claims/*` answers `RPC failed; HTTP 403` with
`ls-remote` confirming nothing was created, and REST `POST /repos/{o}/{r}/git/refs` answers
`403 "Write access to this GitHub API path is not permitted through this proxy."`. A run **does**
lose a race here, one layer later: `archive.sh`'s re-check refuses `claim_taken_over` or
`ambiguous_claim` at the first write the base would see, with the tree byte-identical. The run
report is keyed on those refusals, and `drive/SKILL.md` §7 and `reference/routing.md` say in
their own words where the loss is detected and why. If the arbitration ever becomes available,
this surface takes ticket 4's word with no other change.

**The reading is classified and pinned.** `drive/reference/claims.md`, *Whether a unit is being
driven twice* — a seventh vocabulary in the one home, every value a **judgement** (a race
resolves the moment one branch merges), consumers enumerated, and no consumer may release a
claim, pick between the branches, delete a branch, close a pull request, revert, merge, gate or
hold work on it. `scripts/test-workflow-scripts.mjs` pins it both ways and additionally asserts
the reader is a pure read and all three siblings filter through the shared helper. The pin was
**proved able to fail**: flipping the `ambiguous` row to `proof` turns two rows red.

`lib/claims.sh`'s own comment on `ambiguous` still asserted the premise the mission corrected
three days of documents ago ("this state cannot arise from the sanctioned path at all") — a third
occurrence the correcting ticket's grep did not cover, since it searched `claims.md` and
`CLAUDE.md`. Corrected here, because a reader following the resolution into a comment that denies
the race exists cannot understand the step reading it.

Verified: `node scripts/test-workflow-scripts.mjs` 5422/0; `verify-claim-race` 13 load-bearing
rows (was 9), 1 breaker, pass; `verify-handoff-question`, `verify-condition-age`,
`verify-catch-up`, `verify-moderate`, `verify-act-effect`, `verify-retire` and
`verify-operator-pulls` all pass unchanged; `build.mjs` + `verify.mjs` +
`validate-metadata.mjs` + `layout-doctor.sh` clean.

### Discovered Insights

- **Insight**: a drill row asserting a sibling is silent passes vacuously when the fixture never
  puts that sibling's candidate set within reach.
  **Context**: the raced claims in `verify-claim-race` are fresh, so with the protocol's own
  staleness threshold `stalled-units` would not have listed them whatever the filter did. Forcing
  `WORKAHOLIC_CLAIM_STALE_HOURS=0` for that one probe is what makes the row fail when the filter
  is removed — demonstrated, not reasoned.
- **Insight**: inserting a section into a document parsed by a chain of `indexOf` splits silently
  moves its rows into the preceding section's parse window.
  **Context**: the new classification table landed inside the publication table's slice and the
  suite still passed, because its row shapes did not match that table's regex. The split was
  added deliberately rather than left to luck.
