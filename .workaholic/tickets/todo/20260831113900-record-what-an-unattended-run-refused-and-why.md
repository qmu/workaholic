---
created_at: 2026-08-31T11:39:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# Record what an unattended run refused and why

## Overview

The policy's second admitted outcome is *refuse the single action and carry on,
recording what was refused and why* — and it is only admissible if the record actually
reaches somebody. Without it a refusal is indistinguishable from an action that silently
did nothing, which is the shape this whole mission exists to remove one level up.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/run.sh` — where a step's status and reason
  are classified (`step_missing` / `step_error` / `no_output` / `bad_output` /
  `jq_compile_error`), the one place a new classification belongs.
- `plugins/workaholic/skills/drive/SKILL.md` §7 — the run report contract, which already
  names each unit's outcome and every degradation by name.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the tick's own log line.


## Implementation Steps

1. Define what a refusal record carries: the action refused, the reason, and the fact
   that the rest of the run continued. Three facts, no more — a refusal is not a stack
   trace.
2. Put it where the run's other degradations already go: the tick's log line and the run
   report, both of which a person already reads, rather than inventing a surface.
3. Report it as **degraded** rather than as success: a run that refused an action did not
   do everything it set out to do, and reporting `ok` over it is the collapse this
   repository names by other names elsewhere.
4. It **moves no token and gates nothing** — a refused action is a fact about one step,
   not a verdict on the run, and the person who must act is reached by the tick's own
   question.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A refused action appears in the run report and the tick log, naming the action and the
  reason, and the run reports it as degraded rather than as `ok`.
- A run that refused nothing is byte-identical to today.
- No token moves and no gate reads the refusal.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`

**Gate** — what must pass before approval:

- The refusal is reported in the surfaces that already exist; no new store and no field
  on any artifact.


## Considerations

- Whether a refusal can be detected from inside the run at all depends on what the
  previous ticket establishes about configuration: a prompt that is refused by policy may
  surface as an ordinary tool error rather than as a labelled refusal. Say which of the
  two this records rather than claiming coverage it does not have.

