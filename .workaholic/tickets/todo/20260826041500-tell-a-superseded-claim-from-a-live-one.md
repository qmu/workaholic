---
created_at: 2026-08-26T04:15:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy: review
verification_handoff:
---

# Tell a superseded claim from a live one

## Overview

A claim is in flight iff its **branch** carries commits not yet on the base
(`drive/scripts/lib/claims.sh`, `git rev-list --count base..ref`). That is the right
question for a branch whose work is genuinely outstanding, and the wrong one for a branch
whose **content** reached the base by another route — a unit recovered by hand, a change
re-applied onto a fresh claim branch, a revert-and-redo. Such a branch is unmerged forever,
so it is claimed forever, and every consumer reads it as work.

The cost was theoretical while `queue_drained` made every drained claim untouchable. It is
now measured: the `report_incomplete` tier (2026-08-19,
`20260819104115-tell-a-dead-unit-from-a-reported-one`) makes a drained, unreported claim a
**mandatory** takeover that forbids `ok`. On 2026-08-26 the first run to hold that tier
resumed `batch-20260819063000` (branch `work-20260819-063001`) exactly as designed — and
the unit turned out to have been recovered by hand onto `work-20260821-221006` on
2026-08-21, so both its tickets were already archived on `main` and the tick's behaviour
had shipped and been refined since. `git merge-tree origin/main work-20260819-063001`
reports ten conflicts, three of them `modify/delete` against
`plugins/workaholic/skills/housekeep/`, deleted on `main` by the `/housekeep` → `/moderate`
rename: merging the branch would revert that rename.

The run finished the tier honestly — it wrote the story, opened the pull request, and left
the merge to a human — and that is what a run should do when it cannot tell the two apart.
The ask here is to let the reader tell them apart, so the next one does not spend a full
story-and-pull-request cycle on a branch that exists to be closed.

**This is scoped to the reading, not to acting on it.** Nothing here deletes a branch,
closes a pull request, or breaks a claim: staleness has been reported-never-acted-on since
the protocol shipped, and a superseded verdict is the same kind of fact.

## Policies

- `workaholic:implementation` / `policies/command-scripts.md` — the verdict must be a script's answer, not prose a session re-derives
- `workaholic:implementation` / `policies/objective-documentation.md` — a new reason word is read out of cron logs and must state a checkable fact
- `workaholic:implementation` / `policies/observability.md` — a claim nothing can explain is indistinguishable from work nobody is doing
- `workaholic:operation` / `policies/ai-production-investigation.md` — the change exists so an unattended run stops spending cycles on a branch that cannot land

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the one resumability scan; the unmerged test (`_cs_ahead`) and the verdict ladder that would gain the reading
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — renders `resumable[]` and the `claimed_*` exclusion vocabulary
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the operator-facing reader
- `plugins/workaholic/skills/drive/reference/claims.md` — the reason vocabulary and the "something left to drive" rule
- `plugins/workaholic/skills/drive/reference/survey.md` — the resumable-offer tiers
- `scripts/test-workflow-scripts.mjs` — hermetic tests for the claim scripts

## Related History

- [20260819104115-tell-a-dead-unit-from-a-reported-one.md](.workaholic/tickets/archive/work-20260826-034037/20260819104115-tell-a-dead-unit-from-a-reported-one.md) — added the `report_incomplete` tier this ticket answers the cost of; same function, same fork
- [20260804180033-claim-scan-invents-claims-in-a-shallow-clone.md](.workaholic/tickets/archive/work-20260804-194735/20260804180033-claim-scan-invents-claims-in-a-shallow-clone.md) — the precedent for suppressing a verdict when the branch, not the unit, is what the scan cannot answer for

## Implementation Steps

1. Reproduce first, hermetically: build a claim branch, drive its ticket, then land the
   *same ticket* on the base from a different branch (the hand-recovery shape). Assert that
   today's scan reports the original branch `resumable: true`, `resume_reason:
   report_incomplete`, and that `claim.sh resume` accepts it.
2. Decide the signal and write it as one function beside `claims_has_work` /
   `claims_has_story`. Two candidates, and the reproduction should decide between them
   rather than a preference:
   - **The unit's artifacts are archived on the base.** Direct, cheap, offline
     (`git ls-tree` on the base for each claimed ticket's basename under
     `.workaholic/tickets/archive/`), and it answers the actual question for a batch unit.
     A mission unit needs the mission's own resolution instead.
   - **The branch's diff is already contained in the base.** More general and more
     expensive, and it is wrong for a branch whose content landed *refined* rather than
     verbatim — which is exactly what happened on 2026-08-21.
3. Report it as a verdict, never an action: a new `resume_reason` (`superseded`) with
   `resumable: false`, and a matching `excluded[]` reason in `plan-units.sh`. It must sit
   **after** the identity and ancestry gates and **before** the drained fork, so a foreign
   or shallow verdict still wins and a superseded branch never reads `report_incomplete`.
4. State plainly in `reference/claims.md` that the verdict is reported and never acted on —
   nothing deletes the branch or closes its pull request, exactly as `stale` has always
   worked. Name what an operator does instead.
5. Update `reference/survey.md`'s tiers, `SKILL.md` §7's token table (a `superseded` claim
   must **not** forbid `ok` — there is no work in it), and `docs/drive-loop-runbook.md`'s
   reason vocabulary and its troubleshooting rows.
6. Add hermetic assertions for the new verdict and for all three untouched ones
   (`heartbeat_lapsed`, `report_incomplete`, `queue_drained`) on the same fixture.

## Considerations

- **Resist making it act.** The obvious next step — delete the branch, close the pull
  request — is not this ticket's, and `release-claim.sh`'s header already states why: it
  discards an unfinished unit and is never a recovery path. A machine that deletes a pushed
  branch on its own verdict is the failure the claim protocol has refused since it shipped.
- **A superseded claim must not forbid `ok`.** It is the opposite of outstanding work, and
  a verdict that pins every run to `pending` would be worse than the state it names.
- **The mission-unit case is not the batch case.** A mission claim stamps only
  `mission.md`, which is not archived by driving; whatever step 2 chooses must answer for
  both kinds or say plainly that it answers for one and leaves the other on today's reading.
- **Do not widen this into "close the pull request too".** `batch-20260819063000`'s pull
  request is a human's to close; this ticket is about not offering its branch again.

## Quality Gate

**Acceptance criteria**

- A claim branch whose driven tickets are archived on the base under a *different* branch
  directory reports `resumable: false` with a distinct reason from `list-claims.sh`, and is
  excluded rather than offered by `plan-units.sh`.
- A claim branch with genuinely outstanding work is unaffected: `heartbeat_lapsed`,
  `report_incomplete`, `parked_with_pr` and `queue_drained` are byte-identical to today's
  verdicts on the same fixtures.
- A foreign-authored or shallow-history claim still wins over the new verdict.
- The new verdict does **not** forbid `ok`, and `SKILL.md` §7 says so.
- Nothing in the change deletes a branch, closes a pull request, or releases a claim.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with new hermetic cases for the new
  verdict and for the four untouched ones.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate**

- The suite is green, the generated `outputs/` diff is committed, and the reproduction from
  step 1 flips from `report_incomplete` to the new verdict on the same fixture.
