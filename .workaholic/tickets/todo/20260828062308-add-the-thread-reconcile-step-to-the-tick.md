---
created_at: 2026-08-28T06:23:08+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: reconcile-a-stale-thread-with-the-unit-s-real-state
merge_policy:
verification_handoff: 
---

# Add the thread-reconcile step to the tick

## Overview

The reader from `read-which-announced-items-may-still-be-called-in-flight` names candidates; this
ticket makes the tick run it, log it, and hand the thread reads back to the agent.

The split is `step-unanswered-asks.sh`'s and `step-question-answers.sh`'s, for their reason:
**Slack is a connector held by the session, not by a script.** The script owns the mechanical half
(which candidates, which bounds, what an earlier tick already reconciled); the agent owns the
lookup, the thread read and the post. That makes the step's `event` a question in its own right —
`unanswered-asks` and `question-answers` both emit an **always-empty** `event`, because at the
moment `run.sh` reads their line nobody has read a thread yet and any event would be a claim about
a reading not made. The same holds here, and the step must follow it rather than announce a
reconciliation it has not performed.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — every degradation named, never rendered as quiet

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-question-answers.sh` — the closest precedent: a bounded per-candidate thread read handed back in `needs_agent`
- `plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` — the empty-`event` precedent and its reason
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the step list, which is the contract
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — how a step asks whether an earlier tick already filed this
- `plugins/workaholic/skills/moderate/reference/workflow.md` — where the step's section is written
- `plugins/workaholic/skills/moderate/SKILL.md` — the step count and what the tick may write
- `CLAUDE.md` — the behaviour record

## Implementation Steps

1. Write `step-thread-reconcile.sh`: run the candidate reader, subtract the candidates an earlier
   tick already reconciled (its own `thread-reconcile-filed` lines, through `log-read.sh`), and
   hand the remainder back in `needs_agent` with everything the agent needs per candidate.
2. **Bound the set** with an env-configurable maximum (default in line with
   `WORKAHOLIC_ANSWER_READ_MAX`'s 10), newest first, the remainder reported rather than dropped.
3. **`event` is always the empty string**, so a tick that reconciles nothing renders no root line.
   Write the reason into the section, citing `unanswered-asks`.
4. Distinguish an **absent** log (`no_log_area`, a readable answer yielding an empty already-done
   set) from an **unreadable** one (`degraded` by name, handing back nothing) — filing against a
   ledger that could not be read is how one thread gets a second reply.
5. Register the step in `run.sh` beside `handoff-units` and `undelivered-units`, so it reads the
   same kind of finished-unit fact those two read.
6. Write the step's section in `moderate/reference/workflow.md`: reads, writes, `event`, the split
   table, the bound, the degradations, and what it never does.
7. Update the step count and the step list in `moderate/SKILL.md` and `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The step is registered in `run.sh` and contributes exactly one log line every tick
- It writes nothing but its own log line — no post, no merge, no branch, no artifact
- `event` is always empty, so a tick that reconciles nothing renders no root line
- An unreadable log is `degraded` by name and hands back no candidates; an absent one yields an empty already-done set
- The candidate set is bounded and the remainder is reported

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the step over a fixture: candidates, the dedup subtraction, both log states, the bound
- `bash plugins/workaholic/skills/moderate/scripts/run.sh --deadline-seconds 60` on a fixture — the step contributes a line

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes
- `outputs/` regenerated (`node scripts/build-plugins/build.mjs`) and `verify.mjs` clean

## Considerations

- **The step must not read `plan-units.sh`** — the survey runs the living migrations and *stages*
  what they change, which `closable-missions` and `undrivable-units` both refused for a step whose
  contract is *writes nothing*.
- The `<step>-filed` line is an optimisation the agent is handed, not the gate: the real dedup is
  structural — the agent reads the thread before writing, so a thread already carrying its finish
  is never touched. Say so in the section, so a later reader does not add a cursor.
- Placing it beside `handoff-units` and `undelivered-units` is deliberate: all three read a unit
  the loop finished, and the three next actions differ. Keep the vocabularies separate.
