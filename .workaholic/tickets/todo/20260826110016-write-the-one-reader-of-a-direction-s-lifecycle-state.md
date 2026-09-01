---
created_at: 2026-08-26T11:00:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826110016-add-the-dormant-reading-to-the-strategy-survey.md
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Write the one reader of a direction's lifecycle state

## Overview

Tickets 1 and 2 put two readings on the survey's rows. Consumers must not each assemble
them into an answer — two assemblers of one question is how they drift, which is the rule
`read-feedback-relation.sh` and `attributed-work.sh` already state in their own headers.
Write `strategy/scripts/direction-state.sh`: **one reader**, composing
`survey-strategies.sh` and never re-deriving a reading, answering `live | overdue | dormant
| unreadable` per strategy plus the repository-level `none` when no `active` strategy
exists at all.

`unreadable` is named, never collapsed into any other answer. `none` is the state that is
byte-identical to a quiet healthy hour today and is the reason the repository level exists
at all.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/reachability.md` — one question, one reader

## Key Files

- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — new; the one reader.
  It lives beside `attributed-work.sh` and `list.sh` because the state belongs to the
  strategy artifact, not to `/propose`.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — composed, never
  re-implemented.
- `plugins/workaholic/skills/strategy/SKILL.md` — the artifact's readers are listed there.
- `CLAUDE.md` — the strategy paragraph names its readers.

## Implementation Steps

1. Read `attributed-work.sh`'s header first — it is the template for a lossy reader that
   reports what it could not answer, and this reader must match its discipline.
2. Write `direction-state.sh` taking an optional slug and an optional root. With no slug it
   answers for every surveyed strategy plus the repository level.
3. Precedence, stated in the script and fixed: `unreadable` first (a state we could not
   read is never any other), then `overdue`, then `dormant`, else `live`.
4. Emit `{ok, states: [{slug, title, assignees, state, days_to_target, reason}],
   repository_state, surveyed_count}`. `repository_state` is `none` only when the `active`
   set is genuinely empty — an unreadable survey is `unreadable`, never `none`.
5. Exit 0 on every path with `ok: false` and a named reason for a survey that refused, the
   same shape `list-inbound-issues.sh` uses: a reader that cannot read is reported, never
   rendered as an empty answer.
6. Write nothing. No commit, no branch, no file under `.workaholic/`.
7. Update `strategy/SKILL.md` and `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each of `live`, `overdue`, `dormant`, `unreadable` is answerable, and `unreadable` is
  never reported as one of the other three
- `repository_state: none` is emitted for a tree with no `active` strategy, and **not**
  emitted when the survey itself refused
- The script writes nothing anywhere and makes no commit
- It re-derives neither `overdue` nor `dormant` — both are read off the survey's rows

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a case per state over a seeded tree, plus one
  asserting an empty `active` set answers `none` and a refused survey answers `unreadable`
- A `git status --porcelain` assertion around the call proving the tree is untouched

**Gate** — what must pass before approval:

- The suite passes and the no-write assertion holds

## Considerations

- The repository level is a property of the tree, not of any strategy, so it is a separate
  field rather than a synthetic row — a row with no slug would be a strategy that is not one.
- The reader answers *what state is this in*. It never answers *what should be done about
  it*: that is the question body, ticket 5.
