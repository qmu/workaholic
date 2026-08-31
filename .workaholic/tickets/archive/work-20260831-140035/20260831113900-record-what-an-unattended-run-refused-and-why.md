---
created_at: 2026-08-31T11:39:00+00:00
status: done
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


## Final Report

Development completed as planned, and the honest finding is that **the mechanism already existed
and the contract did not**. A refusal record carries three facts and no more — the action refused,
the reason, and that the rest of the run continued — and it uses `run.sh`'s closed status
vocabulary, which already has **`blocked`** and which `log-append.sh` already accepts. A step that
refuses reports `blocked` with its own reason and a summary naming those three facts, which puts
the refusal in the tick log line and the run report a person already reads, keeps it out of `ok`,
and carries it into the root's impairment clause beside a `degraded` read. **No new status, no new
store, no field on any artifact and no new surface** — everything a refusal needed was already
there and unsaid, which is why the change is a contract rather than a mechanism.

The contract is stated in `moderate/SKILL.md`'s standing rules and in `reference/workflow.md`, with
the agent-side convention (`log-append.sh` under `<step>-refused`, the `<step>-filed` shape applied
to the other outcome), and `drive/SKILL.md` §7 carries the matching clause for the executor's run
report. It **moves no token and gates nothing**.

**The limit the ticket asked for is stated rather than glossed.** This records a refusal **this
repository's own code decides to make**. A permission prompt denied by the harness is *not
observable from inside a script at all* — a script has no notion of having been refused one — and
the sibling ticket established that the documented routine model says such prompts should not arise
at all. Where one does, it surfaces if at all as an ordinary `step_error`. The contract says so, so
no reader takes it as evidence that every refusal in a tick is visible.

### Discovered Insights

- **Insight**: `blocked` had been in the status vocabulary since the tick shipped and no step ever
  emitted it.
  **Context**: the value existed with no stated meaning, which is how a vocabulary entry becomes
  either dead or misused. Giving it one meaning — a refusal — is cheaper and safer than adding a
  sixth status, and it inherits the impairment clause for free.
