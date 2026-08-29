---
type: Feedback
title: Read back whether the loop's own act took effect
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-29T15:16:54+00:00
author: a@qmu.jp
supersedes: 
---

# Read back whether the loop's own act took effect

Source: https://github.com/qmu/workaholic/issues/725

The `[Propose]` routine opened this against the strategy
`an-autonomous-improvement-loop-run-by-the-routines` (move: breadth).

## What it asks for

Give the loop a reading for **whether an act it took actually took effect**, and make a
refused act a named finding rather than a green run nobody reads.

Every reading the loop has answers *what state did I find* — a claim, a queue, a base, a
direction, a drill. None answers *did the thing I just did happen*. The measured instance
is the claim retirement, standing at the time of the ask:

- `.github/workflows/claim-retirement.yml` had 92 runs; the five most recent, the latest at
  2026-08-29T14:00 UTC on `616e3e5`, all report `success`, and the `Delete the branches of
  claims proved empty` step reports `success` in each.
- At 14:45 UTC the same day, `drive/scripts/list-retirable-claims.sh` named **three**
  candidates the oracle still proves `superseded_only`: `batch-20260819063000`
  (`work-20260819-063001`), `make-a-rename-a-registry-entry-not-a-sweep`
  (`work-20260821-035855`) and `make-the-draft-release-note-an-agent-s-release-plan`
  (`work-20260818-205051`) — branches created 2026-08-18, 2026-08-19 and 2026-08-21, none
  with an open pull request.
- The `🔎 Moderation` root at 10:00 JST that day named three findings and **no**
  `retire-blocked` for any of the three.

So the act is reported taken, the run is green, the branch survives, and nothing anywhere
says so. The workflow's own header states the reason it cannot: *"a refusal is reported
without failing the run"* — the verdict goes to a job log, and the reading built on top of
it (`drive/scripts/ci-retirement-turn.sh`) infers *taken* from a **completed run at the
base tip** rather than from what the act answered, on the premise that a successful turn
removes the candidate. That premise is false in this repository today.

## What must become true

- The CI turn records **what it attempted and what each act answered**, per candidate,
  somewhere a later reading can consult — not only in a job log and not only as an exit
  status.
- `ci-retirement-turn.sh` answers from that recorded verdict — `taken`, `refused:<word>`,
  `pending`, `unreadable` — and never infers *taken* from a run's exit status alone.
- A refusal that **changes** reaches the unit's claim holder; a refusal that is unchanged
  stays held, so the asked-once discipline is narrowed rather than abandoned.
- The same question — *did my act take effect* — is answered in **one** place for the two
  acts the loop already performs on a proof: the retirement's Act 2
  (`drive/scripts/retire-claim.sh`, `delete-retired-claim-branch.sh`) and the delivery
  retry (`drive/scripts/retry-undelivered.sh`), which already records its own outcome onto
  the branch story and is the shape to generalise from.
- No new store, no field on any artifact, no second oracle: the effect is re-derived from
  the tree, the refs and the run the tick is already reading.

## Named seams

`.github/workflows/claim-retirement.yml`,
`plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh`,
`delete-retired-claim-branch.sh`, `list-retirable-claims.sh`, `retire-claim.sh`,
`plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh`,
`plugins/workaholic/skills/moderate/scripts/ask-question.sh`,
`plugins/workaholic/skills/drive/reference/claims.md`, `scripts/e2e/loop-drill.sh`.

## What it is chosen against

The rival mission — "return the work a dead claim is holding to the queue" — is real and
larger (seven standing claims, five reading `mergeability: content`, ten tickets queued
behind them), but a `content` conflict is by standing rule nobody's job here, so most of
its units end at a person's ruling, and it is downstream of this one: any release path it
built would be an act the loop takes and reports, and the loop cannot presently tell such
an act from one that silently did not happen.

The second rival — more drills — is refused because a drill proves a mechanism inside a
fixture, and the measured failure is a mechanism whose drill passes
(`verify-ci-retirement` is green) while the act it drills does not take effect in the
world.
