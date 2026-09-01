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

# Pin the gap between a tick finding and the work queue

## Overview

PROPOSED. Reproduce the gap the mission exists to close, as a hermetic test, before
anything is built against it. Two facts, both currently true and both invisible:
`propose/scripts/file-inbound-ask.sh` is reached from inside `/moderate` by exactly
one caller, `step-question-answers.sh`, and that caller acts on a **person's**
answer — no step files a finding of its own; and `[Specificate]`'s unattended
entrance (`list-inbound-issues.sh`) reads GitHub **issues**, so a finding captured
as a `.workaholic/feedbacks/` record is never discovered by it.

The pin fails the moment the path exists, so the rest of the mission is measured
against it rather than against a claim in prose. It is the same discipline the
`breaker row` gives each `loop-drill.sh` verify target.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/qa-ownership.md` — the change ships with the check that proves it

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the pin lives here beside
  the existing single-writer and single-caller pins (the proofs-and-judgements pin is
  the closest shape to copy).
- `plugins/workaholic/skills/moderate/scripts/step-question-answers.sh` — today's only
  in-`/moderate` caller of `file-inbound-ask.sh`; the pin enumerates it.
- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` — the one filer.
- `plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` — the
  issue-reading entrance; the pin asserts it reads issues and no `.workaholic/` path.

## Implementation Steps

1. Read `scripts/test-workflow-scripts.mjs` for the existing enumerated-caller pin
   shape (the one that fails when a consumer acts on a `judgement`) and reuse it —
   do not invent a second assertion style.
2. Add a pin asserting the **caller set** of `file-inbound-ask.sh` under
   `skills/moderate/`: exactly the steps an explicit allowlist names. Today that list
   is `step-question-answers.sh`; ticket 3 adds the filing step to the same list, so
   the pin is a ledger of intent and not a freeze.
3. Add a pin asserting that `list-inbound-issues.sh` derives its candidate set from
   the issues endpoint and reads no path under `.workaholic/feedbacks/` for
   *discovery* (it reads records only to compute `already_captured` — assert the
   distinction rather than the absence, or the pin is wrong the day it is written).
4. Run the suite and confirm both pins pass **now**; then confirm the first fails
   under a scratch edit that adds a second caller without listing it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The suite names every `skills/moderate/` caller of `file-inbound-ask.sh` and fails
  on an unlisted one.
- The suite asserts `[Specificate]`'s discovery reads issues, not records.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A scratch edit adding an unlisted caller makes the suite fail; reverting it passes.

**Gate** — what must pass before approval:

- The suite is green on an unmodified tree, and the deliberate break was shown to fail.

## Considerations

- The pin must not assert *no* caller exists, or ticket 3 cannot land without deleting
  it. An allowlist that later tickets extend is the point.
- Nothing here changes behaviour. If the pin turns out to be green only because it
  asserts something trivially true, say so in the branch story rather than widening it.

## Final Report

Development completed as planned. `testFindingToWorkGap` in
`scripts/test-workflow-scripts.mjs` pins both halves of the gap: the allowlist of
`skills/moderate/` scripts that reach `file-inbound-ask.sh` (today
`step-question-answers.sh` alone, which acts on a person's answer), and the behavioural
proof that `[Specificate]`'s discovery derives its candidates from the issues endpoint
while reading `.workaholic/feedbacks/` only to compute `already_captured`.

The deliberate break was run: a scratch `step-scratch-break.sh` calling the filer without
being listed turned exactly one row red (`every /moderate script that reaches the one filer
is on the allowlist`) and nothing else; removing it restored green.

### Discovered Insights

- **Insight**: the discovery half had to be pinned behaviourally, not by regex.
  **Context**: `list-inbound-issues.sh` genuinely reads the feedbacks directory, so a pin
  asserting "no `.workaholic/` read" would have been false the day it was written. Running
  the script twice over a stubbed `gh` — once with no records, once with a record naming one
  issue — proves the *distinction* (candidates from the endpoint, exclusions from records)
  rather than an absence that does not hold.
- **Insight**: the allowlist is a ledger of intent and must not assert emptiness.
  **Context**: ticket 3 of this mission adds `step-file-findings.sh` as a second caller. A
  pin asserting *no* caller would have had to be deleted rather than extended, which is how
  a guard stops being a guard.
