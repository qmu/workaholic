---
created_at: 2026-09-01T12:33:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: adjust-the-plan-hourly-not-only-report-it
merge_policy:
verification_handoff: 
---

# Hold new divergence above a work-in-progress limit

## Overview

PROPOSED. Six missions ran in parallel on one repository with no sequencing, and every merge to
the base re-conflicted every open pull request on the loop's own generated index: five pull
requests sat conflicting while the tick reported them hourly as an external fact. Two in flight
and four queued would have produced the same work with none of the conflicts. `/propose`
already has the shape of the brake — `work_waiting` and `open_proposal` give *one mission per
strategy in flight* — but nothing bounds the **repository**, so N directions each within their
own gate still put N missions in flight together. This adds that bound as a declared limit.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — where the named gates are enumerated and each reported by name.
- `plugins/workaholic/skills/propose/scripts/` — the gate's reader.
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — already counts active attributed missions per direction; the repository-wide count composes over it.
- `.claude/settings.json` `env` block — where a per-repository declaration lives.

## Implementation Steps

1. Reproduce the shape: show that N directions each passing `work_waiting` and `open_proposal`
   put N missions in flight together, and that nothing anywhere counts the repository's total.
2. Declare the limit the way `WORKAHOLIC_CADENCES` is declared — in the repository's own
   `.claude/settings.json` `env` block, because a routine declares no environment variables of
   its own and its cloud environment record is account-level and shared.
3. **Absent means no limit.** A repository that declares nothing is byte-identical to one
   before this existed: the gate reports `skipped` by name, holds nothing, and `/propose`
   behaves exactly as it does today. A brake nobody asked for is worse than none.
4. Add it as a named gate in `/propose`'s existing enumeration, reported by name like every
   other (`work_waiting`, `open_proposal`, `observing`, …), placed so a direction refused by
   an earlier gate is not also counted here.
5. **A gate that cannot be read is not a gate**: an unreadable count reports its reason and
   holds nothing, matching `attribution_unreadable` and `inbox_unreadable`. Holding origination
   on a failed read would silently stop the loop.
6. Count what is actually in flight — active attributed missions with queued work — not open
   pull requests, which conflate the loop's own paperwork with the product's work.
7. Report the count and the limit whenever the gate fires, so a held tick says *why* rather
   than looking idle.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With no declaration, `/propose` is byte-identical to today and the gate reports `skipped`.
- With a declaration, a tick above the limit opens no issue and names the count and the limit.
- A tick at or below the limit proposes exactly as it does now.
- An unreadable count holds nothing and reports its reason.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the four rows above.
- `/propose` run against fixtures at, above and below the limit.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **This holds origination only.** It must not hold inbound work: an ask that arrives from
  outside is judged and emitted by `/specificate` regardless, exactly as the `観察中` stage
  gates origination and nothing else. A limit that swallowed inbound asks would drop the
  operator's own instructions on a busy day.
- **The limit's default is no limit, deliberately.** Picking a number for every consuming
  repository is the kind of tunable constant this repository refuses; the operator who
  measured six-in-parallel is the one who knows what their repository can carry.
- Holding divergence makes the loop quieter, which looks like the loop stopping. Ticket 6's
  post must say *held, N in flight against a limit of M* — otherwise this ships a silence
  indistinguishable from the outage this repository has already measured twice.
