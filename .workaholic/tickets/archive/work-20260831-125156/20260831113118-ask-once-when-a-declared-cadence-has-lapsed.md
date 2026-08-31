---
created_at: 2026-08-31T11:31:18+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notice-a-periodic-artifact-that-stopped-being-produced
merge_policy:
verification_handoff: 
---

# Ask once when a declared cadence has lapsed

## Overview

The reading reaches nobody until a step carries it. Add one `/moderate` step that hands
every `lapsed` cadence to the check-in, keyed so one lapse costs one question however
many ticks see it — the ask's own dedup requirement, and the gate already provides it.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/run.sh` — the `STEPS` list.
- `plugins/workaholic/skills/moderate/scripts/step-undrivable-units.sh` — the closest
  precedent: a repository-scoped finding, the running identity never consulted.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate. Read and
  called, **never modified**.


## Implementation Steps

1. Add the step, composing the previous ticket's reader and deriving no reading of its
   own.
2. Key each candidate `cadence-lapsed:<name>` so the existing asked-once gate dedups it —
   no second ledger, no cursor, no field on any artifact.
3. Address it to the person the declaration names if it names one; otherwise leave it
   addressed to nobody rather than stamping an identity nothing verified. The **running
   identity is never consulted**: a lapsed cadence is a fact about the repository.
4. Supply an `event` **only** when something lapsed, so a healthy tick renders no root
   line; report an `unreadable` read as `degraded` by name and ask nothing about it.
5. It **asks and nothing else**: never re-runs a routine, never writes an artifact to
   satisfy a cadence, never touches a claim, and writes nothing but its own log line.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A lapsed cadence produces exactly one question across repeated ticks.
- A tick with nothing lapsed supplies no event and renders no root line.
- An unreadable read is `degraded` by name and asks nobody.
- `ask-question.sh` is byte-identical; no key, cap or hold moves.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-cadence-lapse`

**Gate** — what must pass before approval:

- The step writes nothing but its own log line and never reaches `plan-units.sh`, which
  stages what its living migrations converge.


## Considerations

- Whether the declaration can name an addressee is settled by the first ticket's shape;
  if it cannot, the question is addressed to nobody, which is honest and still visible on
  the root.
- The step count in `CLAUDE.md` and the skill moves by one; that is the next ticket's job
  and must not be forgotten.


## Final Report

Development completed as planned. `step-cadence-lapse.sh` composes `cadence-state.sh` and
derives no reading of its own; it is registered in `run.sh`'s `STEPS` between `drill-health`
and `strategy-digest`. Each lapsed cadence is keyed `cadence-lapsed:<name>` so the existing
asked-once gate dedups it — no second ledger, no cursor, no field on any artifact, and
`ask-question.sh` is byte-identical. The question is addressed to nobody, which is the
declaration's shape rather than an oversight: it names a cadence, a pattern and a period and no
person, and this step will not stamp an identity nothing verified. An `event` is supplied only
when something lapsed, an `unreadable` cadence is reported `degraded` by name and asked about by
nobody, and the running identity is never consulted.

### Discovered Insights

- **Insight**: an `unreadable` cadence must not suppress a question about a *different* cadence
  that read `lapsed`.
  **Context**: the obvious implementation returns early on any degradation, which trades one
  silence for another — the same trade `run.sh` refuses when it declines to zero `needs_agent`
  on a jq compile error. The step reports `degraded` and still hands the lapsed candidates over.
- **Insight**: this step deliberately carries no `condition-age.sh` reading, unlike the four
  question steps that do.
  **Context**: those four have instantaneous readings and borrow the age of the *question* as a
  lower bound. This reading already answers the condition's own age off the commit that produced
  the artifact, which is the stronger fact; attaching the ledger age would put two numbers for
  one question in front of a person and add a fifth consumer to a table pinned at four
  (`drive/reference/claims.md`, *Which question reads which age*).
