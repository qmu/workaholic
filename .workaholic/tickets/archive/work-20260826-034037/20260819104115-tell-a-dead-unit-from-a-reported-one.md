---
created_at: 2026-08-19T10:41:15+00:00
status: done
author: a@qmu.jp
assignees:
depends_on:
mission:
merge_policy: review
verification_handoff:
claim: work-20260826-034037
---

# Tell a dead unit from a reported one

## Overview

`queue_drained` is decided before the story check in `drive/scripts/lib/claims.sh`, so it
answers two different questions with one word. A unit that **reported** — story committed,
pull request open, waiting on a human — is correctly non-resumable (the 2026-08-01 fix
`a-reported-unit-is-resumed-forever`). A unit that **died between §4 and §5** — every ticket
archived and pushed, no story, no pull request — reports the same reason and is equally
untouchable, and nothing else offers it either: its tickets are excluded `claimed_reported`
at every later survey, so no fresh claim reaches them. The work is stranded until a person
notices, and no step of `/housekeep` sees it (`step-stuck-prs.sh` and `step-merge-conflicts.sh`
both read **pull requests**, and this branch has none).

Measured 2026-08-19 on this repository: unit `batch-20260819063000`, branch
`work-20260819-063001`, two tickets implemented and pushed at 06:48 UTC
(`1bd8dec8`, `1543e902`), no `.workaholic/stories/work-20260819-063001.md` at the tip and no
pull request. The four `[Implement]` ticks that followed (07:30, 08:30, 09:30, 10:38) each
surveyed a clean, current checkout, found `missions: []`, `backlog: []`, `resumable: []`, and
finished having driven nothing while that work sat undelivered.

The distinguishing signal already exists and is already computed one branch below: the
`parked_with_pr` arm calls `claims_has_story`. Consulting it inside the drained arm separates
the two cases without touching the case the 2026-08-01 fix protects — that unit **has** a story
at its tip, so it keeps `queue_drained` and stays non-resumable.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — TypeScript/style conventions (all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — the workflow scripts are the surface being changed; the new reason must be a script's answer, not prose a session re-derives
- `workaholic:implementation` / `policies/objective-documentation.md` — the reason vocabulary is read by three consumers and must state a checkable fact
- `workaholic:operation` / `policies/ai-production-investigation.md` — the change exists so an unattended run can recover its own dropped unit instead of stranding it

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` - the one resumability scan; the `queue_drained` arm at the end of `claims_scan` is what splits
- `plugins/workaholic/skills/drive/scripts/claim.sh` - `resume` refuses `queue_drained`; it must accept the new reason and adopt/create the worktree at the pushed tip exactly as it does for `heartbeat_lapsed`
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` - renders `resumable[]` from the shared scan; the new reason belongs in the offer
- `plugins/workaholic/skills/drive/SKILL.md` - §1's two-tier `resumable[]` description and §7's token table both enumerate the reasons
- `plugins/workaholic/skills/drive/reference/claims.md` - the reason vocabulary and the "something left to drive" rule are stated here
- `plugins/workaholic/skills/drive/reference/survey.md` - the resumable-offer tiers
- `scripts/test-workflow-scripts.mjs` - hermetic smoke tests for the claim scripts

## Related History

The drained-queue gate was added deliberately and must survive this change: it stopped an
hourly runner re-taking a reported unit and pushing empty `Resume` commits onto a branch under
human review. What follows narrows that gate rather than reversing it.

- [20260801110246-a-reported-unit-is-resumed-forever.md](.workaholic/tickets/archive/work-20260801110823/20260801110246-a-reported-unit-is-resumed-forever.md) - introduced the drained-queue gate this ticket narrows (same surface)
- [20260804180033-claim-scan-invents-claims-in-a-shallow-clone.md](.workaholic/tickets/archive/work-20260804-194735/20260804180033-claim-scan-invents-claims-in-a-shallow-clone.md) - the precedent for suppressing a verdict when the input, not the unit, is the problem (same function)

## Implementation Steps

1. Reproduce first. In a throwaway repository (the `test-workflow-scripts.mjs` harness style),
   build a claim branch whose tickets are all archived, whose heartbeat is lapsed, and which
   carries **no** `.workaholic/stories/<branch>.md`; assert today's scan answers
   `resumable: false`, `resume_reason: queue_drained`, and that `claim.sh resume` refuses it.
2. In `claims_scan`, split the drained arm on `claims_has_story`: story present ⇒
   `queue_drained`, `resumable: false` (unchanged); story absent ⇒ a new reason —
   `report_incomplete` — with `resumable: true`. Leave the identity, ancestry and heartbeat
   gates ahead of it untouched: a foreign or shallow verdict must still win.
3. Teach `claim.sh resume` the new reason. It refuses on `queue_drained` by name; the new
   reason takes the same path as `heartbeat_lapsed` — adopt an existing worktree at the
   observed tip or create one **at the pushed branch tip**, publish the `Resume a PR-unit`
   commit, and let the push arbitrate the race.
4. Carry the reason into `plan-units.sh`'s `resumable[]` so the survey offers it.
5. State where the resumed unit re-enters. Its queue is drained, so §4 has nothing to drive:
   it enters at §5 (story, scan, pull request) and routes normally at §6. Say this in
   `SKILL.md` §1 and `reference/claims.md` rather than leaving it to be inferred.
6. Place it in §7's token table beside `heartbeat_lapsed`: an untaken `report_incomplete` unit
   **forbids `ok`** — it is a dead run's remains, not a unit waiting on a human.
7. Update `reference/survey.md`'s resumable-offer tiers (two tiers become three) and the
   `docs/` statement of the reason vocabulary if it names the set.
8. Add hermetic assertions to `scripts/test-workflow-scripts.mjs` for both arms of the split.

## Considerations

- The one case that must not move is a reported unit at an open pull request, including a
  conflicted one. `work-20260818-205051` (#521) and `work-20260818-215157` (#520) were both
  measured `mergeable_state: dirty` with green CI on the same day: they have stories at their
  tips, so they keep `queue_drained` and stay a human's business. Resolving a conflict on a
  claimed branch is explicitly not this change's subject (`step-merge-conflicts.sh`: "reported
  to their claim holders, never rebased here").
- Resist widening the repair to "adopt any drained claim". The signal is the missing story,
  which is a fact about the branch, not a staleness heuristic — the claim protocol deliberately
  has no staleness rule that acts.
- The stranded unit measured above is left for whoever implements this: it is recoverable by
  hand today (open its pull request from the pushed tip) and automatically once this lands.

## Quality Gate

**Acceptance criteria**

- A claim branch with a drained queue, a lapsed heartbeat and **no** story at its tip reports
  `resumable: true`, `resume_reason: report_incomplete` from `list-claims.sh` and appears in
  `plan-units.sh`'s `resumable[]`.
- A claim branch with a drained queue, a lapsed heartbeat and a story at its tip still reports
  `resumable: false`, `resume_reason: queue_drained`, and `claim.sh resume` still refuses it.
- A foreign-authored, shallow-history, or heartbeat-live claim is unaffected: its verdict is
  byte-identical to today's on all three inputs.
- `claim.sh resume <unit>` on the `report_incomplete` unit takes it over at the pushed branch
  tip, re-driving no archived ticket.
- `SKILL.md` §1/§7, `reference/claims.md` and `reference/survey.md` all name the third tier,
  and §7 states that an untaken one forbids `ok`.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with new hermetic cases covering both
  arms of the split and the three untouched verdicts.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean
  (the drive skill and its `reference/` ship in `outputs/workflows`).
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate**

- The suite is green, the generated `outputs/` diff is committed, and the reproduction from
  step 1 flips from `queue_drained` to `report_incomplete` on the same fixture.

## Final Report

Development completed as planned. The drained arm of `claims_scan` now splits on
`claims_has_story`: a story at the tip keeps `queue_drained` / `resumable: false`
(the 2026-08-01 gate, byte-identical), its absence reports the new
`report_incomplete` / `resumable: true`. `_cs_reported` moved above the verdict
block — it was already computed on every row since 2026-08-23, and it is now an
input to the verdict rather than a fact reported beside it, so one
`claims_has_story` call answers both forks and no extra git call was added.

`claim.sh resume` needed no new acceptance branch: its refusal ladder only runs
when `resumable != true`, so the new reason passes through by construction. Its
`queue_drained` refusal detail now says *drained **and** reported* and names the
other state. `plan-units.sh` needed no code change either — its classification
keys on `resumable` first, so a `report_incomplete` unit lands in
`claimed_resumable` and in `resumable[]` automatically.

Verified against the real measured unit, not only the fixture:
`batch-20260819063000` flips `queue_drained` → `report_incomplete`
(`reported: false`, 2 artifacts), while the three units with stories at their tips
(`work-20260818-205051` / `#521`, `work-20260818-215157` / `#520`,
`make-a-rename-a-registry-entry-not-a-sweep`) keep `queue_drained` and
`make-workaholify-converge-the-account-s-routines` keeps `parked_with_pr`.

### Discovered Insights

- **Insight**: `claim.sh resume` was reading the claim row's artifact list at
  `cut -f8`, which has been the `reported` column since it was inserted on
  2026-08-23 — so every takeover reported `artifacts: ["true"]` or
  `["false"]` instead of the unit's files. Fixed to `-f9` here, and asserted.
  **Context**: `lib/claims.sh`'s header defends the artifact list's position as
  *last* because a trailing empty field is the one case `read` handles correctly
  — and that protection is real for the three consumers that read the row with
  `while IFS='<TAB>' read -r ...` named fields, which all picked up the new
  column for free. It does nothing for a **fixed `cut -f<N>` index**, and this
  resume path is the codebase's only one. A column added to a TSV whose readers
  are mixed-style is a silent breakage for exactly the fixed-index half.

- **Insight**: the stranded unit was invisible to `/moderate` as well as to the
  survey, and for a reason that generalizes: `step-stuck-prs.sh` and
  `step-merge-conflicts.sh` both read **pull requests**, and the defining
  property of this state is that no pull request exists.
  **Context**: a state defined by an *absent* artifact cannot be found by any
  reader keyed on that artifact's presence, so it needs a reader over what *is*
  present — here the claim branch. That is why the fix belongs in the claim
  oracle rather than in a new maintenance step.

- **Insight**: two of the suite's existing claim tests reached `queue_drained` by
  archiving every ticket and never writing a story, so they were asserting the
  protected case through a fixture that was actually the *unprotected* one.
  **Context**: `testResumeSkipsDrainedUnit` and `testClaimSurvivesUndetectedRename`
  now commit a branch story before asserting. Neither test's subject moved — the
  fixture had simply been under-specified in a way only this split could expose,
  which is the ordinary cost of a verdict gaining a new input.
