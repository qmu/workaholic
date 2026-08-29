---
created_at: 2026-08-29T12:21:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Report the drill state in the moderation tick

## Overview

Add a `/moderate` step that reads the **last completed** CI drill run's verdicts and asks a
person once about a drill that is failing or has gone unrunnable. A red CI job reaches
whoever happens to look at the merge; the tick is the one surface in this repository that
addresses a named person. **A green run supplies no event and renders no line** — the
standing rule that a status line addressed to nobody is noise, on which two keyed roots
were already retired.

## Policies

- `workaholic:operation` / `policies/observability.md` — a finding that reaches a person
- `workaholic:implementation` / `policies/error-handling.md` — a degraded read is named, never rendered as quiet

## Key Files

- `plugins/workaholic/skills/moderate/scripts/run.sh` — the `STEPS` list the step is
  registered in; every step contributes a report line
- `plugins/workaholic/skills/moderate/scripts/step-base-health.sh` — the closest precedent:
  reads CI state, asks once keyed on the commit, gates nothing, and stays silent when green
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the asked-once gate, the
  per-tick cap, the quiet hours and the working-day hold
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step vocabulary and the
  closed `file-findings` classification table an added step must be entered in
- `plugins/workaholic/skills/drive/scripts/read-base-checks.sh` — the one derivation of a
  commit's check state; compose it rather than deriving a second

## Implementation Steps

1. Read the last **completed** drill run at the base tip the tick is reading, composing
   `read-base-checks.sh` — no second derivation of a commit's check state, and no clock,
   timezone or date parsing (`ci-retirement-turn.sh`'s store-free discipline).
2. Ask one question per failing or unrunnable drill, keyed `drill-failing:<drill>` so it is
   asked exactly once however many ticks see it, naming the drill, its verdict and the
   mission ticket 5 resolved.
3. Address it to that mission's assignee, resolved through `gather/scripts/identity.sh` —
   an unmapped login leaves the question addressed to nobody rather than stamping an
   address nobody verified.
4. Supply an `event` only when something is failing or unrunnable, so a green hour renders
   no root line at all.
5. Report a read that could not be made as `degraded` by name (`drill_run_unreadable`,
   `no_workflow`), asking nothing — spending a person's attention on our own degradation is
   what `strategy-pace` already refuses. A repository without the workflow is `unavailable`
   and produces no question.
6. Classify the step in `moderate/reference/workflow.md`'s table — an unclassified step id
   reads `needs_ruling` by design, so leaving it out is a silent step.
7. Write nothing but the step's own log line, and never reach `plan-units.sh` (that survey
   stages what its living migrations converge).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A failing or unrunnable drill produces exactly one question, asked once, naming the
  drill, the verdict and the mission.
- A green run produces no question, no event and no root line.
- A degraded read asks nothing and is named by its own reason.
- The step writes nothing but its own log line and touches no claim, merge or gate.

**Verification method** — the commands/tests/probes that prove them:

- A `/moderate` tick over a fixture whose last run holds one failing drill, run twice, to
  prove the asked-once gate.
- The same tick over a green fixture, proving silence.
- The same over an unreadable one, proving the named degradation.
- The checkout diffed before and after the tick, proving nothing was written.

**Gate** — what must pass before approval:

- All four probes behaved as stated and the step is entered in the classification table.

## Considerations

- The question's addressee is a judgement: the mission's assignee is the person who shipped
  the mechanism, but a drill can outlive its author's involvement. Naming the mission in
  the question body is what lets whoever reads it redirect.
- Reading the **last completed** run rather than the current one is deliberate: a pending
  run is not a verdict, and asking about one is the over-eager question CI retirement's own
  reading already refuses.
