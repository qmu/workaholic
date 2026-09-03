---
created_at: 2026-09-03T13:39:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-verification-handoff-a-probe-re-run-at-claim-time
merge_policy:
verification_handoff: 
---

# Stop a handoff sentence spreading beyond its own unit

## Overview

«A per-ticket sentence became a session-wide premise, then a brief, then a runner's
instruction.» The contagion is the part the ask calls worth fixing: one file read once produced a
belief that stopped six tickets, three of which declared nothing at all. This ticket writes the
bound — a handoff is derived per unit, through the one reader, and never inherited from prose.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/implement.md` — the unattended executor's ceiling
- `plugins/workaholic/skills/drive/SKILL.md` — the verification axis and the run's own bounds
- `plugins/workaholic/skills/drive/reference/routing.md` — where the axis is read
- `plugins/workaholic/rules/workaholic.md` — the fleet-facing rule
- `plugins/workaholic/skills/drive/reference/failure-contract.md` — how a blocked outcome must name what it read

## Implementation Steps

1. Write the rule where a run must read it to act: **a unit's verification axis is derived for
   that unit, by the one reader, at the moment it is claimed.** A statement about another unit,
   about a sibling ticket, or about the repository at large is never a reason to park a unit.
2. State the measured failure beside it, because a rule without its failure gets reasoned away:
   one top-level access declaration was read, it fronted a different site, the two entrances that
   mattered were declared in their own packages and were never opened, and three of four
   declarations were false.
3. Bound the **reporting** side the same way: a `blocked` outcome names the sources it read and
   what they said (`failure-contract.md` already requires this for an Open Decision) — a handoff
   that cannot name the probe or the file it read is not a handoff.
4. Carry the rule into `commands/implement.md` byte-identically, because a routine-fired ceiling
   outranks a document read earlier, and pin the pair in `test-workflow-scripts.mjs` as the other
   inlined rules are pinned.
5. Say what this does **not** do: it adds no check. Whether a session inherited a premise is a
   reading about that session's own reasoning and no file test can see it; what the rule buys is
   that a run parking a unit on somebody else's sentence is visibly non-conformant.
6. Update `CLAUDE.md`'s statement of the axis in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The per-unit derivation rule, with its measurement, is stated in `rules/workaholic.md` and `drive/SKILL.md`.
- `commands/implement.md` carries it byte-identically to its source.
- A `blocked`/`handoff` outcome is required to name the probe or file it read.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the byte-identity row pinning the ceiling against its source.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the bundle regenerated for the changed skills.

**Gate** — what must pass before approval:

- No hook and no script gate is added; this ticket is prose and its pinning test, exactly as scoped.

## Considerations

- Prose is checkable by nothing, and this repository has recorded that limit before. It is
  stated rather than papered over: the pinning test proves the words reach the ceiling, never
  that a run obeyed them.

## Final Report

**Outcome**: implemented — the bound is written where a run will read it.

`workaholic:drive` §6 now states it in one paragraph: **a run never declares a handoff for its own
unit, and never inherits one it did not derive.** The declaration is read **per unit, through the one
reader, at the moment it routes**; a sentence read out of one ticket is a fact about *that* unit and
about nothing else; and if a unit's own reader says nothing, the unit has no handoff.

**The measurement is stated with it**, because the rule without its failure gets rationalised away:
one file read once became a session-wide premise that stopped **six** tickets, **three of which
declared nothing at all**. That is the contagion — a per-ticket sentence becoming a premise, then a
brief, then a runner's instruction.

**It is prose, and that bound is itself stated.** No script can see a session forming a belief from
something it read; what the suite can prove is that the rule is present where a run reads it, and the
assertion says exactly that rather than implying more. The mechanical half is already load-bearing:
`verification-handoff.sh` is the one reader, it is called per unit, and it answers only from that
unit's own members — so a run following the route cannot inherit anything.

**Verified**: `node scripts/test-workflow-scripts.mjs` asserts the bound's presence in the skill.
