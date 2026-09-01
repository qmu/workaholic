---
created_at: 2026-08-27T11:25:28+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-operator-revise-a-live-direction-through-the-loop
merge_policy:
verification_handoff: 
---

# Write the third-writer reversal into the documents

## Overview

PROPOSED. "Exactly two writers and no third" is recorded in three places and has been
re-decided three times, which is why the suite pins it. A mission that adds the third
writer and leaves those sentences standing produces a documentation defect by this
repository's own rule — and worse, leaves a future reader unable to tell a deliberate
reversal from an oversight. Each document must say what moved, what did not, and why the
authorship premise survives.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `CLAUDE.md` — the **Strategy** bullet ("There are exactly two writers and no third"),
  the `/specificate` row's *changed* branch, and the `/moderate` row's
  `direction-health` paragraph ("never edits a live strategy").
- `plugins/workaholic/skills/strategy/SKILL.md` — the drafting-exemption paragraph and
  *The lifecycle state of a direction*'s refusal pins.
- `plugins/workaholic/skills/specificate/SKILL.md` — *Strategy lifecycle announcements*,
  the third table row.
- `plugins/workaholic/skills/moderate/SKILL.md` — the `direction-health` step's "never
  edits a live strategy" clause.
- `scripts/test-workflow-scripts.mjs` — the pins that encode the rule mechanically.

## Implementation Steps

1. Rewrite each of the sentences above to state the rule as it now is: **three** writers —
   `create.sh` creates, `amend.sh` revises the three revisable parts, `close.sh` ends —
   and nothing else writes the file.
2. State what did **not** move, in each place it is load-bearing: the operator's merge is
   still the authorship; a strategy-touching proposal still never auto-merges; `/drive`
   still never surveys a strategy; matching is still by explicit slug only; the citation
   still runs strategy → feedback one way; the retired `strategy:` relation stays retired;
   no routine amends on its own judgement.
3. Answer the two-writer reasoning rather than deleting it. It was written to stop a
   machine authoring the operator's direction, and it holds — what changed is that a
   machine can now *carry* a revision the operator announced, on a pull request only they
   can merge.
4. Update the `direction-health` step's clause precisely: the step still never amends. It
   is `/specificate`'s route that does, and conflating them would undo the pin that
   assertion exists to hold.
5. Confirm the mechanical pins agree with the prose after ticket 1 moved the writer count
   — the suite must fail if a fourth writer appears, exactly as it failed on a third.
6. Regenerate `outputs/` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No document still states "exactly two writers and no third" as current behaviour.
- Each rewritten passage names what moved, what did not, and why the authorship premise
  survives.
- The suite's writer pin names three writers and still fails on a fourth.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A grep for the retired sentence across the repository, returning only history.

**Gate** — what must pass before approval:

- The suite is green, `outputs/` is regenerated, and the grep is clean.

## Considerations

- This ticket is where the mission is most easily under-delivered: the code works without
  it, and the cost of skipping it is invisible for weeks and then expensive. Treat the
  documents as part of the change, not as a follow-up.

## Final Report

Development completed as planned. Every place recording "exactly two writers and no third" now
states the rule as it is — **three** writers, `create.sh` creates, `amend.sh` revises the three
revisable parts, `close.sh` ends, and nothing else writes the file — and each says what did
**not** move: the operator's merge is still the authorship, a strategy-touching proposal still
never auto-merges (and since this mission that is the seam's refusal, not the caller's), `/drive`
still never surveys a strategy, matching is still by explicit slug only, the citation still runs
strategy → feedback one way, the retired `strategy:` relation stays retired, and no routine
amends on its own judgement. The two-writer reasoning is **answered rather than deleted**: it
existed to stop a machine authoring the operator's direction, and it holds — what changed is that
a machine can now carry a revision the operator announced, onto a pull request only they can
merge.

Rewritten: `CLAUDE.md`'s Strategy bullet and `/moderate` row; `strategy/SKILL.md`'s drafting
exemption, its Scripts block, *What it does not answer*, the refusal pins and the write-time
floor; `specificate/SKILL.md`'s announcement table and its retirement note;
`moderate/SKILL.md`'s never-edits clause; `moderate/reference/workflow.md`;
`rules/workaholic.md`; `direction-state.sh`'s and `attributed-work.sh`'s headers;
`docs/proposal-loop-runbook.md`; `docs/loop-drill-runbook.md`. `direction-health`'s clause is
precise: **the step still never amends** — it is `/specificate`'s route that does. The mechanical
pins agree: the closure list now forbids `amend.sh` beside `close.sh`, and the writer set is
pinned at three so a **fourth** still fails. `outputs/` was regenerated and `verify.mjs` is
clean; a grep for the retired sentence returns only history.

The prose landed in the auto-merge ticket's archive commit (one worktree, default staging); this
report records the documentation half of it.

### Discovered Insights

- **Insight**: `attributed-work.sh`'s header refused a strategy-side list of slugs *because*
  nothing edited a live strategy. That premise is now false and the refusal still holds — for a
  different reason, which the header now states: `amend.sh` is bounded and operator-driven, so
  nothing would keep such a list current as work landed.
  **Context**: a reason that rests on an impossibility needs re-deriving, not deleting, the day
  the impossibility ends. Deleting it would have made the option look newly available.
- **Insight**: the closure pin forbidding `amend.sh` in `direction-health` is the sharpest of the
  three, because reading a direction's lifecycle state and writing one are now one script apart.
  **Context**: the pin was written when no writer of a live direction existed; it becomes
  load-bearing exactly now.
