---
created_at: 2026-08-29T15:24:15+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
merge_policy:
verification_handoff: 
---

# Pin the silent act with a failing offline reproduction

## Overview

PROPOSED. This is a **failure report**, so this ticket reproduces and localizes
before anything is designed. The reported shape: `claim-retirement.yml` reports
`success` on every recent run while `list-retirable-claims.sh` still names three
`superseded_only` candidates, and `/moderate`'s `retire-blocked:<unit>` fires for
none of them because `ci-retirement-turn.sh` reads a completed run at the base tip
as `taken`.

**The reporter's assumed cause and the observed one differ, and the difference is
the point of this ticket.** The ask assumes a *refused delete* going unrecorded.
The 14:00 UTC run's own log (job 99110887116, `616e3e5`) shows
`{"ok": true, ..., "candidates": []}` — CI's `list-retirable-claims.sh` found
**zero** candidates while the container's identical reader, minutes later at
`9ae70cc`, found three. So on that run the act was never attempted and there is no
refusal to record. Both are instances of *a green run standing in for an act that
did not happen*; which one is live decides what the next tickets must record.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a failure that looks like success
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/quota-utilization.md` — an offline reproduction over a live wait

## Key Files

- `scripts/e2e/loop-drill.sh` — where the reproduction lands (`verify-ci-retirement` is the
  neighbouring drill and is green, which is itself part of the finding)
- `plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh` — the reading that infers `taken`
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate reader that
  answered differently in the two executors
- `.github/workflows/claim-retirement.yml` — the job whose header states *"a refusal is reported
  without failing the run"*
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the step that reported
  `0 retired` with nobody told

## Implementation Steps

1. **Reproduce, offline.** Build a fixture (a bare origin, the transport stubbed, no network) in
   which the oracle proves a claim `superseded`, a completed workflow run exists at the base tip,
   and the branch still stands. Assert the current chain reports the failure **nowhere**:
   `ci-retirement-turn.sh` answers `taken`, `step-retire-claims.sh` renders no `retire-blocked`
   candidate, and the tick log carries no line naming the standing branch.
2. **Localize which of the two causes is live**, and record the evidence for each rather than
   choosing by assumption:
   - **Candidate divergence** — CI's reader yields `[]` where the container's yields candidates.
     Compare the two inputs directly (refs fetched, `origin/main`, the merged-pull-request lookup's
     three-valued answer, `CLAIMS_FETCH_OK`) and name which term differs.
   - **Refused act** — the reader agrees and `delete-retired-claim-branch.sh` refuses by one of its
     own words. Drive one candidate through the fixture and capture the word.
3. **Record both readings in the ticket's own terms**: whichever is live, the failing assertion is
   the same — *a completed turn left a proved candidate standing and nothing anywhere says so*.
   Write the assertion against that behaviour, not against either cause, so the reproduction
   survives the repair of one of them.
4. Leave the reproduction **failing** on the unmodified tree. It is the ticket's deliverable; the
   repair belongs to the tickets after it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An offline reproduction exists in which a completed retirement turn leaves a proved candidate
  standing, and it **fails** on the unmodified tree.
- The failure is asserted on the observable — a proved candidate standing with no reading anywhere
  naming it — never on either hypothesised cause.
- The localization names which of the two causes is live, with the evidence that distinguishes
  them, and says so if both are.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh <the new row>` exits non-zero on the unmodified tree, with the
  standing candidate named in its output.
- The run makes no network call and needs no credential (`gh` stubbed; verified by unsetting any
  token in the fixture).

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- `sh scripts/e2e/loop-drill.sh verify-ci-retirement` still passes — the neighbouring drill is
  green today and must stay green, since its passing beside this failure is part of the finding.

## Considerations

- **The reporter's framing is carried as a hypothesis, never as step 1's design.** A ticket that
  opened by recording refusal words would have produced nothing on the measured run, where no act
  was attempted.
- The two causes may both be live on different runs; the reproduction is written so that neither
  answer is assumed.
- `verify-ci-retirement` passing while the act does not take effect in the world is the ask's own
  argument against "more drills" as the move — this reproduction is scoped to the **effect**, not
  to the mechanism inside a fixture.
