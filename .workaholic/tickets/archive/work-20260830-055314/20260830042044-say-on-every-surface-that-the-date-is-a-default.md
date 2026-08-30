---
created_at: 2026-08-30T04:20:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-a-dateless-direction-with-the-operator-s-one-week-default
merge_policy:
verification_handoff: 
---

# Say on every surface that the date is a default

## Overview

PROPOSED. A strategy's `## Schedule` is normally the operator's own words about
their own date. A defaulted one is not, and nothing on the artifact would say so —
so a direction the loop dated would read exactly like a direction the operator
dated, and the veto (edit the date before merging) would be a veto nobody knew they
held.

The exemption's whole premise is that **the operator's merge is the authorship**.
A merge is only an authorship if the person merging can see what they are being
asked to author. This ticket makes the default visible on the three surfaces that
carry it, and nowhere else.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 9b composes
  the `## Schedule` prose handed to `create.sh`; step 10 composes the pull-request
  body; step 13 composes the run report
- `plugins/workaholic/skills/specificate/SKILL.md` — the strategy form's outcome
  wording
- `plugins/workaholic/skills/strategy/scripts/create.sh` — takes the schedule prose
  as an argument and must stay unchanged: **no field is added to the artifact**

## Implementation Steps

1. Compose the `## Schedule` prose so it names the date as the one-week default,
   what it was counted from, and that editing it before merging is how the operator
   sets their own — one sentence, in the artifact's existing prose, so nothing is
   stored twice and no reader needs a second document.
2. Name it in the pull-request body beside the form's other outcomes, in the clause
   step 10 already reserves for what the run decided and why.
3. Name it in step 13's one-line run report as part of the strategy form's outcome
   (`target_date:default` / `target_date:stated`), so a defaulted date and a stated
   one are told apart in the report without a new field anywhere.
4. Add **no** frontmatter key: `read.sh`, `list.sh`, `amend.sh`, `survey-strategies.sh`
   and every date reading stay byte-identical, and an amendment that later replaces
   the date leaves the artifact exactly as an ordinary revision does.
5. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A defaulted strategy's `## Schedule` says the date is the default and how to change it
- The pull-request body and the run report each name it once
- A strategy whose date the ask stated carries none of that wording
- No strategy frontmatter key is added and no reader changes behaviour

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/hooks/validate-strategy.sh` on the drafted file
- `bash plugins/workaholic/skills/strategy/scripts/read.sh <slug>` — same shape as
  for a stated-date strategy
- `sh scripts/e2e/loop-drill.sh verify-stage` and `verify-revision` still pass

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes
- `git diff` shows no change to any strategy reader

## Considerations

- The wording lives in the artifact's own prose rather than in a field, because a
  field would be a second thing every reader must learn and every amendment must
  keep current — and once the operator edits the date, a field saying "default"
  would be a lie nothing clears.
- Keep it to one sentence: the strategy is bounded prose an operator reads whole,
  and a paragraph of machine apology at the top of it is the noise this repository
  retires posts for.

## Final Report

Development completed as planned.

The default is named on exactly three surfaces and nowhere else:

1. **The strategy's own `## Schedule` prose** (step 9b) — one sentence naming the
   one-week default, the **basis** it was counted from (the reader's own `basis`), and
   that editing the date before merging is how the operator sets their own.
2. **The pull-request body** (step 10) — `target_date:default` with its basis, or
   `target_date:stated`, in the clause the step already reserves for what the run decided
   and why. This is the body the operator reads *before* deciding to merge, and the merge
   is the authorship.
3. **Step 13's one-line run report** — the same two words, so a direction the loop dated
   and one the operator dated are told apart without a new field anywhere.

A strategy whose date the ask stated carries none of that wording, on any of the three.
`SKILL.md` and `CLAUDE.md` carry the rule and its premise in the same change.

**No frontmatter key was added.** `git diff --stat` is empty over
`skills/strategy/scripts/` and `survey-strategies.sh`, so `read.sh`, `list.sh`, `amend.sh`
and every date reading are byte-identical and no reader changed behaviour.

Verified: `node scripts/build-plugins/build.mjs`, `verify.mjs`,
`node scripts/test-workflow-scripts.mjs` — 5364 passed, 0 failed;
`sh scripts/e2e/loop-drill.sh verify-revision` — pass, 11 load-bearing rows;
`verify-stage` — pass, 16 load-bearing rows.

### Discovered Insights

- **Insight**: the two surfaces the ticket calls "the pull-request body" and "the run
  report" are composed in different steps (10 and 13) from the same facts, and each
  already carries an obligation written in the same shape — `carried:`/`dropped:` and
  `assignee_unmapped:` both appear in both places by name.
  **Context**: `target_date:` joins an existing pattern rather than starting one, which is
  why it needs no new plumbing and no field. A later reader adding a fourth such fact
  should add it to both steps in one change, as all three existing ones are.

- **Insight**: the reason for putting the wording in prose rather than in a field is
  sharper than "one less field" — a `defaulted: true` becomes **false** the moment the
  operator edits the date, and nothing in the loop would clear it, because `amend.sh` is
  bounded to the three revisable parts and would leave it standing.
  **Context**: the artifact would then assert, permanently, that a date the operator
  personally chose was a machine's guess. That is why the sentence lives inside the
  `## Schedule` prose the operator is editing anyway: correcting the date and correcting
  the claim about it are the same act.
