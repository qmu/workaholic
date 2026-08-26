---
created_at: 2026-08-26T08:20:29+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Write direction-state.sh the one lifecycle reader

## Overview

Two readings now exist on the survey rows, and a consumer that assembled its own
answer out of them would be a second derivation of a lifecycle state — the failure this
repository names every time it insists on one reader per relation. Write
`strategy/scripts/direction-state.sh`: it **composes** `survey-strategies.sh`, never
re-deriving a reading, and answers `live | overdue | dormant | unreadable` per strategy,
plus the repository-level `none` when no `active` strategy exists at all.

`unreadable` is named and never collapsed into any other answer — the same rule `pace`'s
`unknown` already holds itself to.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — new; the one reader.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — its only input;
  read, never re-implemented.
- `plugins/workaholic/skills/strategy/SKILL.md` — where the artifact's readers are
  stated.
- `CLAUDE.md` — the strategy conventions paragraph.

## Implementation Steps

1. Read `strategy/scripts/attributed-work.sh`'s header first: it is this repository's
   worked example of a lossy reader that reports what it could not see, and this script
   inherits that posture.
2. Take the same optional arguments the survey takes where they are meaningful (window,
   `--open-proposals`), and pass them straight through rather than defaulting a second
   time.
3. Emit one JSON object: a per-strategy list of `{slug, state, reason}` plus a
   repository-level field carrying `none` when `active_count == 0`. Precedence is fixed
   and stated in the header: `unreadable` first, then `overdue`, then `dormant`, else
   `live`.
4. Degrade the way every reader here degrades: a survey that answers `ok: false` yields
   `unreadable` for every strategy with the survey's own reason carried through, and exit
   0 — a step that cannot read is reported, never rendered as quiet.
5. Write the header to say what it does **not** answer: it never closes, never proposes,
   never lifts a gate, and it is not a second `pace`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `direction-state.sh` answers one of `live | overdue | dormant | unreadable` for every
  `active` strategy, and `none` at the repository level when there are none
- Every state it reports is traceable to a field `survey-strategies.sh` emitted; the
  script contains no date arithmetic and no attribution walk of its own
- An unreadable survey yields `unreadable` with the survey's reason, exit 0

**Verification method** — the commands/tests/probes that prove them:

- `sh plugins/workaholic/skills/strategy/scripts/direction-state.sh | jq .` on this
  repository, and against a tree with no `strategies/` area
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The script writes nothing, commits nothing, and makes no network call the survey does
  not already make
- The documentation this change makes wrong is updated in the same commit

## Considerations

- The survey makes one network call (the open-proposal gate). This reader inherits that
  cost and must not make a second; callers that already hold the read pass it in.
- `none` is a repository-level answer while the others are per-strategy. Keeping both in
  one output is deliberate — a caller asking "what is the direction layer doing" must not
  have to call twice to learn it is empty.
