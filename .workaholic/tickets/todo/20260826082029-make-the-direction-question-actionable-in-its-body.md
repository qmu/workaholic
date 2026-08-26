---
created_at: 2026-08-26T08:20:29+00:00
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
