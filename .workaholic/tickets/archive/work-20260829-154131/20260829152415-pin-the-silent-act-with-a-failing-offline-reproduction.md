---
created_at: 2026-08-29T15:24:15+00:00
status: done
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

## Final Report

Development completed as planned. The reproduction lands as `verify-act-effect` in
`scripts/e2e/loop-drill.sh` and **fails on the unmodified tree**, three load-bearing rows red,
each on the reading rather than on either hypothesised cause.

**The reporter's assumed symptom is not the observed one, and the correction is the ticket's
main product.** The Overview (and the mission's Goal) say `retire-blocked:<unit>` fires for none
of the three standing units *because* the turn reads `taken`. Measured against this repository's
own tick log for 2026-08-29, that is false in its mechanism: `step-retire-claims.sh` suppresses
on `pending` and **asks** on `taken`, so all three units reached `needs_agent` on every tick.
What actually held them was the working-day hold (`off_day`, Asia/Tokyo weekday 6) — the gate
working exactly as designed.

What is wrong is narrower and worse. The tick log records, hour after hour:

> `ci_turn: taken so CI could not take the delete either`

That is an assertion about a second executor which **nothing established**. It is a false
statement in the one durable audit trail the tick keeps, and a false reading is worse than a
missing one: it retires the question instead of raising it, and the same inference answering
`pending` would have suppressed the ask outright. So the failing assertion is written against
the reading — *a completed turn that took no act must never read `taken`* — which is stable
under the repair of either cause.

### Which cause is live

Both were tested rather than assumed, by reproducing CI's **credential** locally (`gh api user`
refused, which is what a `GITHUB_TOKEN` installation token answers for `GET /user`):

| Reading | Under the container's credential | Under an Actions-style credential |
| ------- | -------------------------------- | --------------------------------- |
| `list-retirable-claims.sh` | names all 3 candidates | names all 3 candidates |
| `delete-retired-claim-branch.sh` | reaches the transport | refuses **`gh_unavailable`** |

**The refused-act cause is live; the candidate-divergence cause is not.** The two executors'
readers agree, so the report's assumption that CI's reader yielded `[]` does not hold here. The
act is refused at the transport probe — `gh-rest.sh available` runs `gh api user`, which an
Actions installation token cannot call — **before** the proof gate or any bound is consulted.
Both causes are drilled anyway, separately, because the repair of one is exactly what would
silently drop the other.

### Discovered Insights

- **Insight**: `gh-rest.sh available` probes `gh api user`, so every script guarded by it is
  unusable under a `GITHUB_TOKEN`, whatever the operation's own permissions are.
  **Context**: `GET /user` is not accessible to a GitHub App installation token. The CI-side
  Act 2 holds `contents: write` and could delete the branch, but never gets that far. Repairing
  the probe is a different change from reading the act back and is minted as its own ticket.
- **Insight**: the job-log REST endpoint returns a signed blob URL the loop's container cannot
  follow, while `GET /repos/{o}/{r}/check-runs/{id}/annotations` answers in full through
  `gh-rest.sh` with no redirect and no permission beyond read.
  **Context**: measured on this repository's own run 33260493563. It is why annotations are the
  surface the next ticket records onto, and why the job log is not a candidate.
- **Insight**: a drill the register does not classify fails `test-workflow-scripts.mjs`, so a
  new verb must be registered in `docs/loop-drill-runbook.md` §9 in the same change that adds
  it — not in a later ticket.
  **Context**: the `Breaker` column is recorded honestly as `no` until the breaker row exists.
