---
created_at: 2026-08-26T11:00:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826110016-add-the-moderate-step-direction-health.md
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Make the direction question actionable in its body

## Overview

A question that names a state and nothing else makes its reader open a skill to find out
what to do about it, and a question that costs a skill read is a question that waits. Each
`direction-health` question must name three things in its own body: **the reading**, **the
slug**, and **the operator's own next act** — announce the end so `/specificate` reaches
`close.sh`, file the next direction, or say the direction still stands.

It offers no button and no automation. The answer is prose, recorded by `record-answer.sh`
exactly as every other answer is, and nothing parses it — acting on it stays the next run's
judgement.

## Policies

- `workaholic:design` / `policies/interaction.md` — a question is addressed to a person and answerable without research
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the step supplies
  the body text, because it is the thing that knows what its reading means.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the question reply's shape
  (`🙋 <@U…>`, inside the tick root); this ticket adds a body, never a new post shape.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — records what each question says.

## Implementation Steps

1. Read `notify/reference/notifications.md`'s question-reply shape and keep it exactly —
   the post shape does not move, only what is written inside it.
2. For each of the three readings, write the next act in the operator's own vocabulary:
   - `overdue` — the direction ran past its date while still producing work; re-date it, or
     announce it ended so `/specificate` reaches `close.sh`, or say it still stands.
   - `dormant` — nothing has answered this direction and nothing is queued against it; say
     whether it still stands, or announce its end.
   - `none` — the repository holds no live direction; the loop has nothing to propose
     against until one is filed.
3. Name the slug in every per-strategy question. `direction-none` names the repository.
4. Never state or imply that the loop will close the strategy: it asks, it never closes,
   and a question that hints otherwise invites an answer nobody will act on.
5. Keep each question to what a person can read on a phone — the reading, the slug, the act.
6. Update `reference/workflow.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each question body names its reading, its slug (or the repository, for `none`) and one
  concrete next act
- No question body names `close.sh` as something the loop will run
- The post shape is byte-identical to the existing question reply

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a case per reading asserting the three parts
  are present in the composed body
- The existing notification-shape drift test continues to pass unchanged

**Gate** — what must pass before approval:

- The suite passes, including the notification-shape pin

## Considerations

- The three acts are the operator's, not the loop's. Where the honest answer is "the
  direction still stands", that is a real answer and the body must say so, or the question
  reads as a demand to close something.
