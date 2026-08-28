---
created_at: 2026-08-28T01:20:47+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-what-the-direction-could-not-see-before-calling-it-arrived
merge_policy:
verification_handoff: 
---

# Carry an operator attribution through the loop

## Overview

The announcement route that carries an operator's ruling that an unattributed mission does
answer a direction: it appends that **named strategy's own existing** `feedback:` refs to
that **named mission**, through the publish tree behind a pull request.

This is `amend.sh`'s premise exactly — a machine carries a ruling the operator announced by
explicit slug, onto a pull request only they can merge — and it removes the one act this
repository still leaves to a hand-edit of `main`. It adds no field and revives no
`strategy:` relation: the refs it appends are the ones the citation walk already reads.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/` — the new append writer lives beside `amend.sh`, whose bounds and refusal discipline it copies
- `plugins/workaholic/skills/strategy/scripts/amend.sh` — the model for *writes nothing on any refusal*
- `plugins/workaholic/skills/specificate/reference/workflow.md` — the lifecycle-announcement steps 9b/9c/9d this route joins
- `plugins/workaholic/skills/specificate/SKILL.md` — the announcement table and its recognition rules
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — read only; it already refuses to auto-merge a strategy-touching tree
- `scripts/test-workflow-scripts.mjs` — the append's landing and every refusal
## Implementation Steps

1. Read `amend.sh` end to end. Copy its discipline literally: bounded to one act, asserts
   the immutable half over its own candidate, and writes **nothing** on any refusal — no
   partial write, no staged half, no write-then-revert.
2. Write the append. It takes a strategy slug and a mission slug, reads the strategy's own
   `feedback:` refs through the existing single reader, and appends the ones the mission
   lacks to that mission's `feedback:` list. It is **idempotent**: a mission that already
   carries them is left byte-identical.
3. Refuse by name: `not_active` for a closed direction, an unknown mission named as such, an
   unknown strategy likewise. Matching is by **explicit slug only** — a title or a paraphrase
   never matches, the recognition rule every lifecycle route already holds.
4. Join it to `/specificate`'s announcement route as a sibling of steps 9b/9c/9d, recognised
   from an announcement that names both slugs, and record-only with its reason otherwise.
   A run never appends on its own reading that a mission looks like it belongs somewhere.
5. Confirm the write lands through the publish tree behind a pull request. Note that this
   route writes under `.workaholic/missions/`, not `.workaholic/strategies/`, so
   `publish-tree-pr.sh`'s `strategy_touching` refusal does not fire — decide and state
   explicitly in the skill whether this pull request should auto-merge, and pin the choice.
6. Add hermetic cases: the append landing, the append being a no-op the second time, and
   each refusal leaving the mission byte-identical.
## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An announcement naming a strategy slug and a mission slug appends that strategy's existing
  refs to that mission, behind a pull request.
- Re-running it leaves the mission byte-identical.
- Every refusal (`not_active`, unknown mission, unknown slug, no revision) writes nothing.
- No artifact gained a field and the `strategy:` relation is not revived.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic cases for the landing, the idempotent re-run and each refusal.
- A case asserting the mission's frontmatter differs only in its `feedback:` list.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- Matching is by explicit slug only, proved by a case where a title-only announcement is
  record-only.

## Considerations

- The auto-merge question is real and must be settled in the skill rather than left to the
  driver: this carries an operator ruling but writes a mission, not a strategy, so the
  seam's `strategy_touching` refusal does not cover it. State the decision and its reason.
- The bound is the whole safety property. It appends refs that already exist on a strategy
  the operator named; it must never author refs, never remove any, and never touch the
  strategy file.
## Final Report

Development completed as planned.

`strategy/scripts/carry-attribution.sh <strategy> <mission>` appends a named `active`
strategy's **own existing** `feedback:` refs to a named active mission and writes nothing
else. It copies `amend.sh`'s discipline literally — bounded to one act, asserts the immutable
half over its own candidate (both the rest of the frontmatter and the whole body), and writes
**nothing** on any refusal: `strategy_not_found`, `mission_not_found`, `not_active`,
`no_revision`, `no_slug`, `immutable_field`. A re-run leaves the mission byte-identical and
reports `already`. Matching is by explicit slug only. It adds no field and revives no
`strategy:` relation: the refs it appends are the ones the citation walk already reads.

It joins `/specificate`'s announcement route as **step 9e** (SKILL.md's table, the recognition
rule and the workflow's steps), recognised from an announcement naming **both** slugs, and
record-only with its reason otherwise. A run never carries an attribution on its own reading.

**The auto-merge decision, settled in the skill:** its pull request **does not auto-merge** —
it carries an operator's ruling, so the operator's merge is the authorship. But this one is
the **caller's** rule rather than the seam's, and that difference is stated rather than
blurred: `publish-tree-pr.sh` derives `strategy_touching` from a path under
`.workaholic/strategies/`, and this route writes `.workaholic/missions/`, so the seam cannot
see it. Step 9e leaves `WORKAHOLIC_AUTO_MERGE` unset and a hermetic assertion pins that
step's own text.

### Discovered Insights

- **Insight**: `testDirectionHealthRefusals`' writer detector resolves path variables one hop
  and then asks what is done with them, so a script merely *holding* a `strategies/` path in a
  variable is safe while one that assigns anything derived from it and later redirects into
  that name would register as a fourth writer.
  **Context**: it is why this script redirects the strategy read to a file under its temp
  directory rather than capturing it into a variable — a habit worth keeping in any future
  script that reads a strategy.
- **Insight**: the byte-identity check has to cover the **body** as well as the frontmatter.
  A frontmatter-only assertion passes over a candidate whose awk pass silently dropped a body
  line, which is the failure mode of every line-rewriting filter.
