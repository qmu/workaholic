---
created_at: 2026-08-30T08:22:51+00:00
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
