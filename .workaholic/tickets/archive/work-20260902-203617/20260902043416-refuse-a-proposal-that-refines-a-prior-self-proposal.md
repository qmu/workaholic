---
created_at: 2026-09-02T04:34:16+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refuse-an-ask-the-loop-wrote-to-itself
merge_policy:
verification_handoff: 
---

# Refuse a proposal that refines a prior self-proposal

## Overview

PROPOSED. The measured chain was five links long and every link was a refinement of the one
before: a verdict, then where its difference is seen, then what present practice it is
measured from, then recording that practice. Each was a defensible `depth` move against the
Aim. `depth` on a documentation-shaped aim can always invent one more axis, and nothing at
the bar asked whether the thing being deepened was itself the loop's own invention.

`/propose` already carries two judgement refusals beside its mechanical gates —
`describing_move` and `invented_obligation`. This adds the third, on the same standing, for
the same measured reason: refused by construction at the bar, not by a person noticing days
later.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md`, *The one thing it is for: an evolutionary
  move, never housekeeping* — where `describing_move` and `invented_obligation` are stated,
  and where this joins them.
- `plugins/workaholic/skills/propose/reference/loop.md` step 4 — where the move is chosen
  and where a refusal ends the tick honestly rather than as idle.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the mechanical gates;
  this is **not** one of them and must not be folded in.
- `plugins/workaholic/skills/propose/scripts/open-proposal.sh` — the body floor, including
  `## What this is chosen against`, which the measured chain passed honestly.
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — reads what has landed
  against a direction; the run reads it at step 3 and can see what produced each item.
- `CLAUDE.md` — the `/propose` gate list.

## Implementation Steps

1. Write the refusal where the other two judgement refusals live, with the measurement
   beside it: five links in one day, each refining the last, the direction abandoned
   mid-drive. A refusal without its measurement is re-argued by the next reader.
2. State the test the run applies at composition, in words: does the thing this move
   deepens trace back to a human ask or a human-authored strategy, or only to a previous
   proposal this loop wrote? A chain whose root is the loop's own output is refused.
3. Give it its own word — `self_refining` — and report it like every other refusal, so a
   tick refused for it never reads as idle. Do not widen `describing_move` to cover it: one
   word answering two questions is how the two drift, which this repository has recorded
   twice already.
4. Keep it a judgement rather than a gate. It reaches no expression in
   `survey-strategies.sh`, changes no `refusal`, no sort, no `selected`; a run refused for
   it opens nothing and says why. The mechanical gates stay byte-identical.
5. Name what it must not catch: a second mission that answers a **human's** ask on the same
   subject, and a follow-up repair mission the strategy's own scale allows. Depth is not
   banned; depth on the loop's own invention is.
6. Update `CLAUDE.md`'s gate list and `workaholic:propose` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The refusal is stated with its measurement, under its own word, beside the two existing
  judgement refusals.
- No mechanical gate, sort or `selected` reads it; those are byte-identical.
- What it must not catch is named in the same paragraph.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- A survey run over the current strategies is byte-identical before and after.

## Considerations

- This is prose the running model applies, and nothing mechanical checks it — the same
  limit `describing_move` and `invented_obligation` already carry. What it buys is that a
  proposal deepening the loop's own invention is visibly non-conformant, and that the
  operator can point at the rule rather than re-explaining the failure.

## Final Report

Development completed as planned. **`self_refining`** now stands beside `describing_move` and
`invented_obligation` in `workaholic:propose`, *A move that deepens the loop's own invention*,
with its measurement written next to it: a chain five links long in one day — a verdict, then
where its difference is seen, then what present practice it is measured from, then recording
that practice — each link a defensible `depth` move, each merged by the next ticks, the
direction abandoned mid-drive and the whole day reported as waste.

- **The test is stated in words** (step 2): does the thing this move deepens trace back to a
  human's ask or a human-authored strategy, or only to a previous proposal this loop wrote?
- **It has its own word** (step 3), reported like every other refusal so a tick refused for it
  never reads as idle. It is **not** folded into `describing_move` — one word answering two
  questions is how two questions drift.
- **It is a judgement, not a gate** (step 4). No propose script changed: `git diff` over
  `propose/scripts/` against the base is empty, and a survey run over the current strategies
  is byte-identical. The suite pins that none of the three refusal words appears in an
  expression in `survey-strategies.sh`.
- **What it must not catch is named in the same paragraph** (step 5): a second mission
  answering a **human's** ask on the same subject, and the follow-up repair mission the
  strategy's own scale allows. Depth is not banned; depth on the loop's own invention is.
- `reference/loop.md` step 4 and `CLAUDE.md`'s gate list moved in the same change (step 6).

### Discovered Insights

- **Insight**: `survey-strategies.sh`'s header names `describing_move` twice, in comments,
  because it explains which question is *not* its own and hands that answer in as
  `--aim-kind`. A drift pin over the raw file therefore fails on the healthy arrangement; the
  pin has to strip comments, exactly as this suite's other seam checks do.
  **Context**: The distinction worth pinning is *the word in an expression*, never *the word in
  the file* — a script explaining what it deliberately does not decide is the shape this
  repository wants more of, not less.
