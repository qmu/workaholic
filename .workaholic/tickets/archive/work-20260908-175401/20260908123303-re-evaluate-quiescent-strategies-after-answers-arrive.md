---
created_at: 2026-09-08T12:33:03+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: turn-quiescent-blockers-into-mature-decisions-and-resume-work
merge_policy:
verification_handoff: 
---

# Re-evaluate quiescent strategies after answers arrive

## Overview

Make a recorded answer invalidate the terminal-looking quiescent explanation and cause the next loop turn to evaluate the strategy with that answer as new evidence.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — coordinate answer ingestion with due-role dispatch.
- `plugins/workaholic/skills/propose/` — consume resolved blocker evidence on the next survey and judgment.
- `plugins/workaholic/skills/moderate/` — settle the standing question after its answer is recorded.

## Implementation Steps

1. Trace the existing Slack answer path through feedback capture and question settlement.
2. Make settlement expose a fresh, derived input that the next propose turn can observe without a stored workflow cursor.
3. Ensure the strategy is re-evaluated while ordinary open-work and attribution brakes still apply.
4. Prove an unanswered blocker stays standing and an answered blocker permits a new move or a newly justified refusal.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- An answer settles the exact question and the next eligible loop turn re-evaluates the strategy.
- The answer does not bypass mechanical work-in-flight or attribution gates.

**Verification method** — the commands/tests/probes that prove them:

- Run end-to-end fixtures from Slack reply through feedback record to the next propose survey.

**Gate** — what must pass before approval:

- Both the resumed and still-refused outcomes name the answer evidence that changed the judgment.

## Considerations

Prefer existing records and derived state over a new mutable reopen flag.

## Final Report

Development completed as planned.

`no_evolutionary_move` stops being terminal at the place it is reported: `/propose` step 4 now
reads `moderate/scripts/decision-maturity.sh` **before** it may report the word, and a
`resumable: true` reading — a person answered, and the direction still reads blocked — puts their
words into the judgment. The report names the `answer_state` either way, and one that does not is
non-conformant on its face. The reading lifts no gate: every survey refusal holds unchanged, so
an answer licenses no proposal the gates did not already allow.

The reopening is **derived**, exactly as the ticket's Considerations asked: `resumable` is two
existing readings conjoined at the moment it is read, so there is no flag to clear, no cursor to
advance and nothing that can go stale. The coordinator routes nothing new either — the answer is
recorded inside the tick that read the thread and picked up by the ordinary `[Propose]` turn.

### Discovered Insights

- **Insight**: writing the `${CLAUDE_PLUGIN_ROOT}` invocation form for a script that lives in
  **another** skill resolves that whole skill into the calling skill's script closure. Naming
  `moderate/scripts/decision-maturity.sh` that way in `propose/` broke six cross-agent bundles
  with thirty unresolved references (`lib/raced-units.sh`, `lib/speaking-window.sh`,
  `lib/tick-thread-key.sh`, `../bootstrap/session-start.sh`) and `verify.mjs` exited 1.
  **Context**: `workaholic:drive` already records this restraint for its own cross-skill reader
  (`moderate/scripts/condition-age.sh`) and says a later reader must not "fix" it into the
  invocation form. The convention is to write the bare `skill/scripts/name.sh` path — the run has
  already resolved `src` — and `verify.mjs` is the check that catches a regression.

- **Insight**: the reopening had to be prose rather than a script, and the boundary is worth
  stating. *Which move an answer makes nameable* is a model's judgment; putting it in a script
  would put a judgment inside a gate. What a test can hold instead is that the three surfaces a
  `/propose` run actually reads — the command ceiling, the skill and `reference/loop.md` — each
  carry the instruction, and that no artifact anywhere grew a reopen flag.

- **Insight**: the answer ledger lives in `.workaholic/moderations/`, which is git-ignored and
  local to the checkout that wrote it. A container that carries no tick log therefore reads
  `answer_state: never_asked` — the honest absence, not a claim that nobody answered — and the
  resumption only works where the tick and the propose turn share a checkout, which is the local
  loop's normal shape since 2026-09-02.
