---
created_at: 2026-09-02T06:55:00+00:00
status: done
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

## Final Report

Development completed as planned.

### The shape, decided first and recorded

**A question to a person, exactly as step 1 predicted.** The available reading is *the acceptance
is unticked and the queued tickets describe behaviour the base already has*, and the second half
is a judgement about behaviour rather than a file test —
`list-stranded-publications.sh`'s own history records a survey-side *already implemented* test
refused by name for that reason. So `unrecorded-missions` closes nothing, excludes nothing and
touches no claim: it establishes that nothing **recorded** the work, never that the work is
undone, and whether to close or re-drive is the assignee's.

### The measurement that changed the reading

**The ticket's third term cannot be read for the missions it is about, and the repair is a second
source.** Step 2 says *the mission's recorded `claim:` branch* — and `claim.sh` does write that
field, **on the claim branch**. A branch closed unmerged never reaches the base, so `main`'s copy
carries no `claim:` line at all: all three measured missions
(`take-the-moderation-tick-s-log-off-main`, `read-the-base-s-colour-past-a-bookkeeping-tip`,
`prove-a-claim-branch-is-empty-before-deleting-it`) read `status: active` with no `claim:` field
today. The field is therefore read first and the **claim oracle's own row for the unit** second
(`list-claims.sh`, keyed on the `Claim <unit>` commit).

**And the three measured missions are still named by nobody, which is reported rather than worked
around.** Their branches have since been deleted — by the `pull_request_closed_unmerged`
retirement this same mission shipped — so neither source resolves a branch and the step counts
them **`claim_branch_unresolved`**: a named absence, never a candidate, because this step may not
name a mission whose pull request it never read. Verified live against this repository: `10 active
mission(s) scanned; 0 ... closed unmerged with nothing recorded; 1 still being driven; 6 whose
claim branch neither the mission nor the claim scan names`. Inventing a branch for them — by
matching a slug against closed pull-request bodies, say — would be a guess dressed as a proof, and
the three are already live work somebody must rule on, which the ticket itself says.

The four tree terms gate the one bounded pull-request read, so a mission failing any of them costs
no network call: `active`; `checked == 0` with `total > 0`; the changelog records no archived
ticket; the queue is non-empty (a drained one is `closable-missions`' candidate or nobody's).
`merged` and `open` are each counted and named by nobody; an unreadable pull request is `degraded`
with reason `pull_request_unreadable` and never *nothing to close*, while every candidate the step
did prove is still handed over.

Registered in `run.sh`'s `STEPS`, in `moderate/reference/workflow.md` (§12a, the classification
table as `needs_ruling`, and the transport-derived-count table), and in `CLAUDE.md`'s step table
and prose. The hermetic test stubs the **transport** rather than the step, so every tree term is
under test for real with no `gh` call.

### Discovered Insights

- **Insight**: a mission's `claim:` field is only ever true of a branch that merged.
  **Context**: `claim.sh` writes it into the mission on the claim branch, so the base learns the
  branch's name only if that branch lands. Any future reading that wants *which branch drove this
  mission* has the same hole, and the claim oracle — keyed on the `Claim <unit>` commit rather than
  on any field — is the only source that answers for a branch still standing.
- **Insight**: the retirement and this reading are in tension by construction.
  **Context**: deleting a `closed_unmerged` branch is right (it can never merge) and it destroys
  the last evidence linking that branch to its mission. Both shipped on this mission. Anything
  that wants to keep the link has to record it at claim time on a ref that survives, which is a
  ruling nobody has made.
