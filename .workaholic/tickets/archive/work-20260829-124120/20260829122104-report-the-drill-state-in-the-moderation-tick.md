---
created_at: 2026-08-29T12:21:04+00:00
status: done
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

## Final Report

Development completed as planned.

`moderate/scripts/step-drill-health.sh` is step 21, registered in `run.sh`'s `STEPS` beside
`base-health` and classified `needs_ruling` in `moderate/reference/workflow.md`'s
`file-findings` table — `base-health`'s row for `base-health`'s reason: it composes the same
check-run reader, so every value it carries is a judgement a re-run can turn green.

It reads the **last completed** run at the base tip the tick is reading, through
`drive/scripts/read-drill-verdicts.sh` — a new composition of `read-base-checks.sh` (still
the one derivation of a commit's check state anywhere in this plugin) and the drill
register. Because CI names each matrix leg after its drill, the failing check's **name is
the drill's name**: no second call, no log parsing, no clock and no date arithmetic.

Every failing drill becomes one question keyed `drill-failing:<drill>`, so twenty-four
ticks see one broken proof and exactly one question goes out; keying on the commit would
re-ask on every merge that followed the break. It is addressed to the **shipping mission's
assignee**, resolved through `gather/scripts/identity.sh` — an unmapped address leaves the
question addressed to nobody rather than stamping one nobody verified — and the question
names the mission so whoever reads it can redirect when the drill has outlived its author.

A green run supplies no `event` and therefore renders no root line; a degraded read is
`degraded` by name (`drill_run_unreadable:<reason>`) and asks nothing; a repository shipping
no `Loop Drills` workflow reads `unavailable` and asks nothing at all. A failing check that
is **not** a drill is `base-health`'s question, not this one.

It asks and nothing else: it never re-runs a leg, reverts, merges, holds, or touches a
claim; it never reaches `plan-units.sh` (that survey stages what its living migrations
converge); and it writes nothing but its own tick-log line.

### Discovered Insights

- **Insight**: `read-drill-verdicts.sh` answers `no_failing_drill` rather than `green`, and
  the distinction is load-bearing. `read-base-checks.sh` returns `red` as soon as one check
  has failed, which masks a sibling leg still pending — so "no drill is reported failing at
  this commit" is what was observed, and "every drill passed" is not.
  **Context**: The same discipline `read-base-checks.sh` applies to `unanswerable`: a word
  that says what was read beats one a reader will over-interpret.

- **Insight**: `read-base-checks.sh` builds its `failing` array with `jq -c`, which emits
  `"name":"x"` with no space after the colon, while its own printf-built fields carry one.
  A reader matching only the spaced form silently found nothing and reported "no drill
  failing" over a red drill run.
  **Context**: Composing a script whose output is half printf and half `jq -c` means
  tolerating both shapes rather than assuming the half you happen to be reading.
