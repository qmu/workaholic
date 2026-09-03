---
created_at: 2026-09-03T07:21:08+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Declare the fan-out bound for implement runners

## Overview

A fan-out needs a number, and the repository's rule for a number nobody can defend is to make
the operator declare it. `WORKAHOLIC_WIP_LIMIT` and `WORKAHOLIC_CADENCES` already live in
`.claude/settings.json`'s `env` block for exactly this reason, and both read **absent means the
behaviour that existed before**. This bound follows them.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `.claude/settings.json` — the `env` block where `WORKAHOLIC_WIP_LIMIT` and
  `WORKAHOLIC_CADENCES` are declared, for the same reason
- `plugins/workaholic/commands/infinite-development.md` — §2, which reads it
- `plugins/workaholic/skills/loops/SKILL.md` — where the declaration is documented
- `CLAUDE.md` — the environment declarations are listed here and must move in the same change

## Implementation Steps

1. Name it `WORKAHOLIC_IMPLEMENT_FANOUT`, declared in `.claude/settings.json`'s `env` block.
2. **Absent means 1** — the present single runner — so a repository that declares nothing is
   byte-identical to one before this existed. That is the safety property, stated as such.
3. A non-numeric or non-positive value is `bad_fanout`: it holds nothing, falls back to 1, and
   is reported. A gate that cannot be read is not a gate.
4. Document it where the other two are documented — `workaholic:loops`, `CLAUDE.md`, and the
   command body — in this change, not a later one.
5. Pick no number for any other repository. The operator who measured the seven-hour queue is
   the one who knows what this machine can carry.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Absent means 1 and such a repository behaves exactly as before.
- A bad value falls back to 1 and is reported by name.
- The declaration is documented in all three places in the same change.

**Verification method** — the commands/tests/probes that prove them:

- Unset the variable: the tick spawns one `implement` runner.
- Set it to a non-numeric value: the tick reports `bad_fanout` and spawns one.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No default above 1 is hard-coded anywhere.

## Considerations

A bound above the number of independently claimable units is not an error — the fan-out is
`min(bound, claimable)`, and a tick with one unit spawns one runner whatever the bound says.
