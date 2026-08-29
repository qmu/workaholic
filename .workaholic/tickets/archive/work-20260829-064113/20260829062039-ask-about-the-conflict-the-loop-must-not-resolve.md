---
created_at: 2026-08-29T06:20:39+00:00
status: done
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

## Final Report

Development completed as planned. `moderate/scripts/step-catchup-blocked.sh` is registered in
`run.sh` between `undelivered-units` and `handoff-units`, keyed `catchup-blocked:<unit>`,
addressed to the claim holder, naming the branch, its pull request and the files both sides
changed. It reads `list-claims.sh` and never `plan-units.sh`, writes nothing, and reaches no
writer at all. A degraded read asks nothing and is named. It is classified `needs_ruling` in
the findings table — deliberately, since which side of a content conflict keeps its behaviour
is exactly what the loop refused to decide — and documented as §26 of `reference/workflow.md`.

**The split the ticket asked for is drawn on the reading, not on the pull request.** Candidates
are claims whose `mergeability` is `content` *and* which are finished and waiting
(`report_undelivered` or `queue_drained`). A branch nothing has attempted therefore draws no
question here: `merge-conflicts` reports what GitHub calls conflicted (*nobody has looked yet*)
and this asks about what the shared classification rule examined (*the loop looked and only you
can decide*). Everything else is somebody's question already — `claim_active` and
`heartbeat_lapsed` belong to the run driving or resuming the unit, `parked_with_pr` has work
left, `awaiting_verification` draws `handoff-unit`, `superseded` holds nothing.

**Step 4 of the plan — making `merge-conflicts` filter — was written, measured and refused.**
The only way to know which units this step asks about is to read the claim oracle, and
`list-claims.sh` fetches; the suite's own fixture for `merge-conflicts` carries a real
`origin` URL, so the filter put a **network fetch** inside a hermetic test and inside a step
whose whole cost is one bounded REST read. The requirement ("one asks and the other counts")
holds without it, because `merge-conflicts` asks nobody anything — `needs_agent` is empty by
construction and its finding rides step 6's reminder. Where two steps could each *ask*, the
split **is** enforced: `undelivered-units` filters a `content` row out of its own candidates
and counts it in its summary. The refusal and its measurement are recorded in
`step-merge-conflicts.sh`'s own header, beside the narrowing of the standing no-rebase rule,
so neither is re-tried from scratch.

### Discovered Insights

- **Insight**: "This step must not duplicate that step" has two different costs depending on
  whether the step *asks* or merely *reports*.
  **Context**: A reporting step already satisfies the one-question rule; making it filter buys
  nothing and can cost a read it has no business making. The test is *who receives a question*,
  not *whose output mentions the item*.
- **Insight**: A `/moderate` step's cost is part of its contract, and the hermetic suite
  enforces it by accident.
  **Context**: `step-merge-conflicts.sh`'s fixture sets a real remote, so any script that
  fetches fails the suite the moment it is called from there. That is a useful guard and worth
  knowing before reaching for `list-claims.sh` in a step that does not already read it.
