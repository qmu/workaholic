---
created_at: 2026-09-01T12:24:48+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
merge_policy:
verification_handoff: 
---

# Name every step summary carrying transport-derived volatility

## Overview

PROPOSED. `stuck-prs` is the summary the operator measured, but nothing says it is the only
one. Thirty-two steps compose a summary and every one of them is compared verbatim by the post
gate, so any step embedding a value a transport recomputes opens a root on an hour in which
nothing happened. This is the audit that turns "we fixed the one we saw" into "we know which
ones can do it" — a **reading**, reported, with a repair only where the audit finds one.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-*.sh` — every summary composer, thirty-two of them.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — each step's own spec, where the finding is recorded.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the comparison the audit is against.

## Implementation Steps

1. Read every `step-*.sh` summary composition and classify what each interpolates into it:
   a **repository** fact (a count, a slug, a state the tree owns) or a **transport** fact (a
   value an API recomputes between two identical reads).
2. Record the classification in `moderate/reference/workflow.md` beside each step's spec — one
   short clause per step, so the next person adding a step has the rule in front of them.
3. Repair only what the audit actually finds, each by the same rule ticket 4 used: move the
   volatile value out of the compared summary and leave it on the `headline` / `needs_agent`
   the question reads. Name each repair; a step the audit clears is named as cleared.
4. Write the rule down once, where a new step is written: **a summary is compared, so it
   carries what moved in the repository; a transport's answer belongs on the headline.**
5. Report the audit's own limits: a step whose composition is built by interpolation the audit
   cannot follow is **named as unaudited**, never counted as clean.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every step is classified, and the classification is written beside its spec.
- Each finding is either repaired or named with why it was left.
- A step the audit could not read is named as unaudited rather than as clean.
- The rule for a future step is stated in one place.

**Verification method** — the commands/tests/probes that prove them:

- The audit's own report in the branch story, one line per step.
- `node scripts/test-workflow-scripts.mjs` for any repair that ships.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **This ticket may honestly find nothing beyond `stuck-prs`.** That is a real and useful
  outcome, and it must be reported as one — an audit that finds one instance is not a failed
  audit. What it must not do is invent repairs to justify itself.
- Resist making this a mechanical check. Whether a value is transport-derived is a judgement
  about where the number comes from, and a regex over summaries would produce confident
  nonsense. The durable artifact is the written classification, not a script.
- It depends on ticket 4 only for the rule it applies; it can be read before that lands.
