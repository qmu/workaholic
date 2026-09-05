---
created_at: 2026-09-03T07:21:08+09:00
status: done
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

## Final Report

Development completed as planned.

`WORKAHOLIC_IMPLEMENT_FANOUT` is now documented in all three places in one change — the command
body's §2 (`plugins/workaholic/commands/infinite-development.md`), `workaholic:loops`, and
`CLAUDE.md`'s *Loops* — each naming `.claude/settings.json`'s `env` block as the declaration site,
beside `WORKAHOLIC_WIP_LIMIT` and for its reason, and each stating that **absent means 1** and that
a **non-numeric or non-positive** value is `bad_fanout`, holding nothing, falling back to 1 and
reported by name. `workaholic:loops` carries the two bounds as one table so a reader meets the
absent-means and invalid-means answers together.

**No value was written into this repository's own `.claude/settings.json`, and that is a decision
rather than an omission.** Step 5 is explicit that the number is the operator's — *pick no number
for any other repository; the operator who measured the seven-hour queue is the one who knows what
this machine can carry* — and none of the three acceptance criteria asks for a declared value: they
ask that absent means 1, that a bad value falls back and is reported, and that the declaration is
documented in all three places. The verification method reads the same way (*unset the variable:
the tick spawns one implement runner*). Writing a number nobody chose would be exactly the constant
this repository refuses elsewhere. The gate — *no default above 1 is hard-coded anywhere* — was
checked by searching the whole tree for both names: every occurrence is prose stating the semantics,
and no script or manifest carries a default at all.

### Discovered Insights

- **Insight**: the fan-out arithmetic already lived in the command body before this ticket, but the
  *declaration site* did not — `min(WORKAHOLIC_IMPLEMENT_FANOUT, …)` was named while nothing said
  where an operator would put the number.
  **Context**: a name is not a declaration. Reading a variable and telling an operator where to set
  it are separate obligations here, and the second is what makes the first usable; `.claude/settings.json`
  is the answer for the same reason `WORKAHOLIC_WIP_LIMIT` and `WORKAHOLIC_CADENCES` live there — a
  routine selects an account-level environment and declares no variables of its own, so a
  per-repository number has nowhere else to go.
