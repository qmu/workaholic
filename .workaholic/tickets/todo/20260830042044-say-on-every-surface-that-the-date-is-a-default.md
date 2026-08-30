---
created_at: 2026-08-30T04:20:44+00:00
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
