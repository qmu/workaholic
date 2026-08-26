---
created_at: 2026-08-26T08:20:29+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Make the direction question actionable in its body

## Overview

A question a person cannot answer without opening a skill is a question that waits.
Each `direction-health` question must name three things in its own body: the **reading**
(this direction has run past its date / nothing is answering it / there is no live
direction), the **slug** to act on, and the **operator's own next act** — announce the
end so `/specificate` reaches `close.sh`, file the next direction, or say the direction
still stands.

It offers no button and no automation. The answer is prose, recorded by
`record-answer.sh` exactly as every other answer is, and nothing parses it: acting on it
stays the next run's judgement.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the step
  supplies the wording, because it is what knows what its reading means.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the question reply's
  shape is defined there and must not be re-invented here.
- `plugins/workaholic/skills/moderate/SKILL.md` — the three-part wording rule.

## Implementation Steps

1. Read `workaholic:notify`'s question shape and `step-human-checkin.sh`'s composition
   path before writing any wording: the mention token, the `🙋` and the position in the
   root's thread are settled and are not this ticket's to move.
2. For each reading, compose the body's three parts. Name the operator's act in the
   operator's own vocabulary — *announce that it ended*, not *call `close.sh`* — because
   the announcement is the sanctioned route and the script is not the operator's to run.
3. Say what the loop will and will not do: it will not close the strategy, and saying
   "it still stands" is a complete answer that costs nothing further.
4. Keep it short. The root is read in a channel, and a question longer than its answer
   is the noise two retired status roots were retired for.
5. State the three-part rule in `moderate/SKILL.md` so a later step reusing this surface
   inherits it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each question names its reading, its slug (or explicitly none, for `direction-none`)
  and the operator's next act, in that order
- No question instructs a person to run a script, and none implies the loop will close or
  edit a strategy
- The answer path is unchanged: `record-answer.sh` stores prose and nothing parses it

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-direction-health` (this mission's last ticket)
  renders each question body for inspection
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The post shape, mention token and threading are byte-identical to
  `notify/reference/notifications.md`
- The documentation this change makes wrong is updated in the same commit

## Considerations

- A dormant reading on a direction filed an hour ago is correct and could read as an
  accusation. The wording should describe the state, not the person.
- The three parts are a prose contract, not a script gate — the same class as this
  repository's `## Open Decisions` floor. What it buys is that a question missing one of
  them is visibly non-conformant.

## Final Report

Development completed as planned.

Each `direction-health` subject now carries its own `heading` and `body`, composed by the step
because the step is what knows what its reading means. The three parts run in the required
order — the reading, the slug (or explicitly *this repository* for `direction-none`), and the
operator's own next act — and the act is named in the operator's vocabulary (*announce that it
ended*, never *call `close.sh`*). Every body states what the loop will **not** do, so *it still
stands* reads as a complete answer. The post shape, the mention token and the threading are
untouched: `heading` fills `workaholic:notify`'s `🙋 <@U…> - <…>` line and `body` is the one
sentence beneath it, all three inside the 25-word bound (20 / 20 / 24 words as rendered). The
rule is stated in `moderate/SKILL.md` so a later step reusing this surface inherits it.

### Discovered Insights

- **Insight**: the wording had to be split into `heading` and `body` rather than being one
  string, because `workaholic:notify`'s question shape is itself two parts — the subject on the
  `🙋 <@U…>` line and one sentence under it.
  **Context**: a step that emitted one blob would have forced the composing agent to cut it in
  two, which is exactly the "re-invented here" failure the ticket's step 1 warns against. The
  split makes the notify shape the consumer of the step's fields rather than a thing the agent
  re-derives.
- **Insight**: "the operator's next act" for a `dormant` direction is *file its next move*, not
  *file the next direction* — the direction is still live and still theirs.
  **Context**: only the `overdue` and `none` readings put a direction's *existence* in question.
  Conflating the three acts would have told somebody to replace a direction that had merely gone
  quiet, which is the accusation the wording rule exists to avoid.
