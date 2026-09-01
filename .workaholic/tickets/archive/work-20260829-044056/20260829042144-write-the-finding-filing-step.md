---
created_at: 2026-08-29T04:21:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-s-own-findings-become-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Write the finding-filing step

## Overview

PROPOSED. `step-file-findings.sh`: the step that turns a **repairable** finding into
one `[FB]` issue. Its candidates are the run's own step reports — the tick already
knows what every step found — and the filing goes through
`propose/scripts/file-inbound-ask.sh`, which stays the **one** filer, assigned to the
running identity so the next `[Specificate]` at `:15` ingests it, carrying the
direction through `feedback/scripts/ask-feedback-line.sh`, still the one writer of
that line. Nothing new opens an issue.

The split follows `step-inbound-sweep.sh`'s precedent: the **script** owns the
mechanical half (candidates, classification, the brake, what an earlier tick already
filed) and hands the set back in `needs_agent`; the **agent** takes the act after
`run.sh` returns, because the filing is a network write and because the tick's own
`event` must not claim an act the step has not taken.

The tick's *writes nothing but its own log line* contract is intact: an issue lives on
GitHub, outside the tree — the ground `/propose`'s inbound sweep already stands on.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — a degraded read is named, never rendered as quiet

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` — new; the step.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — `STEPS` gains the id; place it
  where its inputs are ready and before `human-checkin`, which ticket 6 suppresses against.
- `plugins/workaholic/skills/moderate/scripts/step-inbound-sweep.sh` — the split's
  precedent: read how it shapes `needs_agent` and copy that shape.
- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` — the one filer; called,
  never reimplemented, never modified beyond what a new caller legitimately needs.
- `plugins/workaholic/skills/feedback/scripts/ask-feedback-line.sh` — the one writer of
  the direction line.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's contract.

## Implementation Steps

1. Read `step-inbound-sweep.sh` and `step-question-answers.sh` end to end: the first for
   the `needs_agent` split, the second for how an agent-taken filing is already worded.
2. Write `step-file-findings.sh`. Candidates: the run's own step reports, filtered to the
   ids ticket 2's table calls `repairable`. Emit per candidate the step id, its `summary`,
   and what the issue body should carry. It **writes nothing** — not even its own log
   line, which `run.sh` writes.
3. Compose the issue body from the finding itself: what the tick found, which step found
   it, and the repair the finding names. Keep it in the shape `/propose`'s issue already
   uses (`kind` / `source` / `subject` header, then the direction line), so
   `[Specificate]` ingests it with no new branch.
4. Judge the direction as the inbound sweep judges it — explicit slug, else the `active`
   set, else no line — and pass the strategy's refs through `ask-feedback-line.sh`.
   Never write the line by hand.
5. Register the step in `run.sh`'s `STEPS`, and write its contract into
   `moderate/reference/workflow.md`: what it reads, what it hands back, and that its
   `event` is **empty** until the agent has acted (`standing-rulings`' rule, same reason).
6. It **never reaches `plan-units.sh`** — that survey stages what its living migrations
   converge, and this step writes nothing (the reason `closable-missions` records).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `repairable` finding appears in `needs_agent` with everything the filing needs.
- A `needs_ruling` finding never appears there.
- `file-inbound-ask.sh` and `ask-feedback-line.sh` remain the only filer and the only
  direction-line writer; the tick still writes nothing but its own log line.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — ticket 1's caller pin, now listing this step.
- `bash plugins/workaholic/skills/moderate/scripts/run.sh --only file-findings` over a
  fixture, with no network: the step reports and writes nothing.

**Gate** — what must pass before approval:

- The suite is green and the step's own run leaves the tree byte-identical.

## Considerations

- Do not give the step an `event` that claims a filing. The agent files after `run.sh`
  returns; ticket 7 owns what the report says about it.
- A finding's `summary` is written for a maintainer diagnosing the tick. Composing an
  issue body straight from it will read badly; write the body for the person and the
  `[Specificate]` run that will read it.

## Final Report

Development completed as planned. `step-file-findings.sh` reads the classification table out of
`reference/workflow.md` — its one home — filters this tick's own step reports to the
`repairable` set, derives each candidate's id through `lib/question-id.sh`, and hands the set
back in `needs_agent` for the agent to file through `file-inbound-ask.sh`. It writes nothing,
its `event` is always empty, and it never reaches `plan-units.sh`.

`run.sh` gained the seam its candidates come from: the accumulated rows are written to a temp
file outside the repository and named in `WORKAHOLIC_TICK_REPORTS`, refreshed after every row.
The step is registered in `STEPS` immediately before `human-checkin`.

Verified: `node scripts/test-workflow-scripts.mjs` (the new `testFileFindingsStep` plus ticket
1's caller pin, now listing this step), and `run.sh --only file-findings --no-log` over a
fixture leaves the tree byte-identical.

### Discovered Insights

- **Insight**: `event` — not `status` — is the honest "this step found something" signal, and
  the tick log does not carry it.
  **Context**: every finding-producing step emits `status: ok` whether it found something or
  not; what distinguishes them is the post-facing `event` the step supplies. The log
  deliberately keeps only `status` and the log-facing `summary`, so a candidate set read from
  the log would have had to guess from free text. That is why `run.sh` had to expose its own
  accumulated rows rather than the step reading `log-read.sh`.
- **Insight**: the reports file must be seeded `{"steps": []}`, not left zero-length.
  **Context**: with `--only file-findings` no row exists yet, and an empty file made the step
  report `reports_unreadable` — a degradation announced for an entirely ordinary state, which
  is the exact collapse every reader in this skill is written against.
- **Insight**: `needs_ruling` needed no code path.
  **Context**: the step filters *to* the repairable set, so a step the table does not name is
  simply never a candidate. The safe default falls out of the data structure rather than
  being a branch somebody must remember to keep.
