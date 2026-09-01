---
created_at: 2026-08-28T01:20:45+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-what-the-direction-could-not-see-before-calling-it-arrived
merge_policy:
verification_handoff: 
---

# Name the residue in the arrival question

## Overview

`/moderate`'s `direction-arrived:<slug>` question names the unattributed missions by
**slug** and the queued-ticket count. A count alone costs the operator the same hand-read
it costs them today — they learn the answer is partial and still cannot see what was
missing, which is precisely the alternative the ask refused.

Nothing else about the step moves: the key, the asked-once gate, the addressee, and the
step's ask-and-nothing-else contract are unchanged. Per the previous ticket, a degraded
residue read yields no `arrived` reading at all, so it yields no question either.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the `arrived` question body
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — the residue rides through from the survey row
- `plugins/workaholic/skills/moderate/SKILL.md` — the step's contract
- `scripts/test-workflow-scripts.mjs` — the question body and the asked-once gate
## Implementation Steps

1. Read `step-direction-health.sh`'s header. The `arrived` body is a **description of the
   reading**, never an assertion that the direction is finished; adding the residue must not
   change that register.
2. Carry the residue from the survey row through `direction-state.sh` onto the `arrived`
   row. Add no second read — the step must not call `unattributed-work.sh` itself, or two
   readings of one fact will drift.
3. Name each unattributed mission by slug and give the queued-ticket count. Bound the render
   so a tree with many unattributed missions does not produce an unreadable question, and
   **count** whatever is cut rather than silently truncating.
4. Leave the key `direction-arrived:<slug>`, the asked-once gate, the addressee and the
   per-tick cap exactly as they are. Changing a body does not re-ask a question — the ledger
   keys on the step id — so this reaches a person the next time the question is first asked.
5. Assert in a hermetic case that a degraded residue read produces no `arrived` question.
## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `arrived` question names each unattributed mission by slug and the queued-ticket count.
- The key, the asked-once gate and the addressee are unchanged.
- A degraded residue read produces no arrival question at all.
- Anything cut by the render bound is counted, never dropped silently.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic case renders the question over the fixture and asserts the slugs appear.
- A case asserts the same question is asked exactly once over two ticks.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- The step still asks and does nothing else: no strategy closed, nothing proposed, no gate lifted.

## Considerations

- The question's register matters. It says *this looks finished, and here is what I could
  not see* — never *this is finished*. The residue is the reason the operator should check,
  not evidence that they should not.
## Final Report

Development completed as planned.

`/moderate`'s `direction-arrived:<slug>` question now names each unattributed mission **by
slug** with its queued-ticket count, appended to the heading beside what landed and the date.
The render is bounded to three names followed by `and N more`, so nothing is silently
truncated. The residue is carried from the survey row through `direction-state.sh` — the
step makes no second read, because two readings of one fact drift.

Nothing else about the step moved: the key, the asked-once gate, the addressee and the
per-tick cap are unchanged, and the body's register is unchanged — it describes the reading
and never asserts the direction is finished. A degraded residue read produces no `arrived`
reading upstream and therefore no question at all, which is asserted rather than assumed.

### Discovered Insights

- **Insight**: the residue belongs in the **heading** rather than the body. The body is
  bounded to one sentence naming the operator's act inside `workaholic:notify`'s 25-word
  limit, while the heading already carries parenthetical facts (`12 item(s) landed, dated
  …`); putting slugs there costs the body nothing.
  **Context**: it also keeps the act — *announce that it ended, or say it still stands* —
  the last thing the operator reads.
