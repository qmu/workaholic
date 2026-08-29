---
created_at: 2026-08-29T06:20:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# Ask about the conflict the loop must not resolve

## Overview

PROPOSED. A `/moderate` step handing every claim whose catch-up was refused
`content_conflict` to the check-in as one question addressed to the **claim holder**, keyed
once per unit, naming the branch, the pull request and the files both sides changed.

**A branch nothing has attempted is not this question.** That is the whole point of the split:
*nobody has looked yet* and *the loop looked and only you can decide* ask a person for
different things, and one word for both is how four conflicted pull requests went unread for
three days. It follows `undelivered-units` on whose question it is and `undrivable-units` on
the other two axes — the running identity is never consulted, and it reads `list-claims.sh`,
never `plan-units.sh`, which stages what its living migrations converge.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the precedent to
  follow for shape, key and addressee.
- `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — the neighbouring step
  that must not ask the same question twice; one asks and the other counts.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the step list.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the finding classification table,
  which an unclassified step id makes read `needs_ruling`.

## Implementation Steps

1. Add the step beside `undelivered-units`, reading `list-claims.sh` and the ticket-2 reader.
2. Key it `catchup-blocked:<unit>` (or the word the mission settles on) so it is asked once.
3. Address the claim holder. Resolve the addressee to an address through
   `gather/scripts/identity.sh`; an unmapped login leaves the question addressed to nobody
   rather than stamping an address nobody verified.
4. Make `merge-conflicts` count rather than ask about a unit this step asks about — one unit,
   one question, in one vocabulary.
5. Classify the new step id in the findings table deliberately; leaving it unclassified makes
   it read `needs_ruling`, which is the safe default and must be a decision either way.
6. It **asks and nothing else**: no merge, no close, no claim touched, no gate lifted.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One question per unit, asked once, naming the branch, the pull request and the conflicted files.
- A branch nothing has attempted draws no question from this step.
- `merge-conflicts` does not ask about the same unit; it counts it.
- The step writes nothing but its own log line and never reaches `plan-units.sh`.
- A degraded read asks nothing and is named.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Two ticks over one fixture produce exactly one question, and the neighbouring step is
  silent on that unit while still asking about an ordinary conflicted pull request beside it.

## Considerations

The addressee question is worth stating: the claim holder drove the unit and can judge the
conflict, which is why it follows `undelivered-units` rather than `undrivable-units` on that
axis even though it follows the latter on the other two.
