---
created_at: 2026-09-02T06:55:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: leave-only-live-work-in-the-unmerged-branch-list
feedback: 20260901112130-the-unmerged-branch-list-is-30-long-and-22-of-them-are-dead.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
merge_policy:
verification_handoff: 
---

# Close a mission whose work landed by another route

## Overview

MINTED while driving `20260901112558-localize-why-the-in-flight-gate-let-a-duplicate-through.md`,
which is a **diagnosis** ticket and may change no behaviour — so the repair its evidence named is
written here rather than there.

**Measured 2026-09-01/02.** Three missions still read `status: active` with `0/3` acceptance and
**17 queued tickets** between them, and the `/implement` survey offered all three on 2026-09-02:

| Mission | Loop's pull request | The route the work actually took |
| ------- | ------------------- | -------------------------------- |
| `take-the-moderation-tick-s-log-off-main` | #790, closed unmerged | #789, a person's own single commit, merged 2026-08-31T19:37 |
| `read-the-base-s-colour-past-a-bookkeeping-tip` | #801, closed unmerged | #800, a person's own single commit, merged 2026-08-31T22:54 |
| `prove-a-claim-branch-is-empty-before-deleting-it` | #802, closed unmerged | #800, the same commit |

The behaviour each mission asked for is on `main` today — `attribute-base-red.sh` walks past a
`no_checks` tip, `lib/claims.sh` carries `claims_branch_empty_against_base`, `.gitignore` carries
`.workaholic/moderations/`. Only the **bookkeeping** is missing: the tickets were never archived,
because the branch that would have archived them was closed unmerged, so nothing ticked the
acceptance and `close.sh` was never reached. Drivability is derived from *active area + plan +
queued tickets*, and all three terms still hold, so the loop is queued to re-implement work that
already landed.

**No gate is at fault** (that is the diagnosis ticket's own finding): the claim protocol held one
claim per unit throughout, and `/propose`'s `work_waiting` / `open_proposal` govern the
origination of an *ask*, which no one of these was. A person implementing a filed finding by hand
is a route the loop cannot see, and this ticket is about what the loop does **afterwards**.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a reading that could not be made is named

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-closable-missions.sh` — the step that already
  re-proves a mission closable and lands the close in a publish tree. Its proof is **arithmetic**
  (`progress.sh`: `checked == total`, `unlinked == 0`, plus an empty queue), which none of these
  three missions can satisfy: their acceptance is `0/3` precisely because no seam ticked it.
- `plugins/workaholic/skills/mission/scripts/close.sh` — the one writer of an end state, and
  `archive.sh`'s `achieved` close is the only automatic one, on the arithmetic alone.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — where the three missions are still
  offered, and where an exclusion (if one is the answer) would have to be named.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step spec, and the
  `file-findings` classification table an unclassified step id falls through.

## Implementation Steps

1. **Decide the shape first, and record the decision.** The reading available is *the mission's
   acceptance is unticked and its queued tickets describe behaviour the base already has* — which
   is a **judgement about behaviour**, not a file test, and `list-stranded-publications.sh`'s own
   history records that a survey-side *already implemented* test was refused by name for exactly
   that reason. So the deliverable is expected to be a **question to a person**, not an act.
2. Add the reading: a mission that is `active`, whose acceptance is unticked, and **whose own
   `## Changelog` records no archived ticket** while a pull request on its recorded `claim:` branch
   was **closed unmerged** — three terms, each read from the tree or from the pull request through
   `drive/scripts/branch-pull-request-state.sh`, and none of them a guess about code.
3. Ask the mission's assignee, once, under its own key: *this mission's pull request was closed
   without merging, so nothing recorded its work; close it or drive it again.* Lead with what
   happened, the slug after it, one act named.
4. Close nothing and exclude nothing. `close.sh` writes `abandoned` and `carried` only on a
   person's intent, and an automatic exclusion would hide a mission whose work genuinely still
   needs driving.
5. Record the step, its key and its classification in `moderate/reference/workflow.md` and in
   `CLAUDE.md`'s step table.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission whose recorded claim branch's pull request was closed unmerged, and whose changelog
  records no archived ticket for it, is named exactly once, addressed to its assignee.
- A mission whose pull request merged, and one still being driven, are each named by nothing.
- A degraded pull-request read names its reason and is never rendered as *nothing to close*.
- No mission is closed, no unit is excluded, and no claim is touched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic rows for the closed-unmerged case, the
  merged case, the in-flight case and an unreadable pull-request read.
- The three measured missions above are each named once by the new reading in this repository.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

## Considerations

- **The subject belongs beside the supersession and close machinery**, not beside the
  unmerged-branch list; it is minted onto this mission because the failure contract has a minted
  ticket inherit the provoking ticket's `mission:` relation, and no acceptance item was appended
  for it. Moving it to a mission of its own is the operator's call.
- The three measured missions are **live today**: whatever this ticket ships, somebody still has to
  rule on those three, and driving them as they stand would re-implement `main`.
- Do not reach for a *has this already been implemented* test over the code. That is a judgement
  about behaviour, and this repository has already refused one by name for the same reason.
