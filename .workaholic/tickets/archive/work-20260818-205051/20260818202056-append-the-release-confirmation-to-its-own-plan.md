---
created_at: 2026-08-18T20:20:56+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-draft-release-note-an-agent-s-release-plan
merge_policy:
verification_handoff: 
---

# Append the release confirmation to its own plan

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

Issue #512's fourth gap: *"Post-release confirmation exists in `/ship`'s
`## Deployment Verification`, but is not connected to the draft as a continuous
experience."* The experience asked for is one document per target that carries the
release through its whole life — the plan while it is pending, then the release,
then the confirmation and report appended to that same note.

The pieces exist and are separately correct. `/ship` §5-D records a deployment
attempt (`pass`/`fail`/`not_run`/`bypassed`) into the story and into the note's
append-only `## Deployment Verification`; `record-release-cut.sh` and
`confirm-release.sh` write the durable ship record under `.workaholic/releases/`.
What is missing is the join: the draft a planner keeps current and the note a
release confirms into are not experienced as one thing.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` / `policies/delivery.md` — the release and confirmation path
- `workaholic:operation` / `policies/runtime-behavior.md` — what confirmation must prove

## Key Files

- `plugins/workaholic/skills/ship/scripts/confirm-release.sh` — writes the
  confirmation half of the durable record.
- `plugins/workaholic/skills/ship/scripts/record-release-cut.sh` — writes the cut.
- `plugins/workaholic/skills/ship/scripts/sync-release-note.sh` — projects the
  non-authoritative copy; reports divergence per target and section before writing
  and never overwrites a published release. Both constraints bind here.
- `plugins/workaholic/skills/ship/scripts/commit-release-note.sh` and
  `read-release-notes.sh` — the `.workaholic/release-notes/` writers and reader.
- `plugins/workaholic/skills/ship/SKILL.md` §5-D — the deployment-verification
  contract this must not weaken.

## Implementation Steps

1. Map the current lifecycle end to end and write it down first: which artifact
   holds what, at which stage (`draft` / `staging` / `confirmed`), and which script
   is the sole writer of each. The mission's value here is a join, and a join over a
   misread map is worse than none.
2. Decide what "one continuous document" means concretely for a target whose draft
   lives outside git (a GitHub draft release) while its durable record lives in
   `.workaholic/releases/`. Two stores already exist by decision; the derivation is
   the source of truth and both are projections. Preserve that — do not make a
   second source of truth to get continuity.
3. Make the confirmation and the report append to the note that planned the release,
   so a reader opening one target sees plan → release → verification in order.
4. Honour the two standing refusals of `sync-release-note.sh`: a published release
   is never overwritten, and a projection is never a merge. A confirmation append
   must be an append.
5. Preserve `/ship`'s existing `## Deployment Verification` semantics exactly — it
   is append-only and records `not_run` and `bypassed` as first-class outcomes.
   Continuity must not quietly drop the unflattering ones.
6. Update `ship/SKILL.md`, `CLAUDE.md` and `.workaholic/README.md` in the same change.

## Quality Gate

<!-- Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- For one target, a plan, its release, and its confirmation are readable as one
  document in order.
- A `fail`, `not_run` or `bypassed` confirmation is as visible as a `pass`.
- A published release is never overwritten by the projection.
- Both copies remain identical by construction, as they are today.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-plan` and `verify-cadence`
- `node scripts/test-workflow-scripts.mjs`
- Walk one target through cut → confirm on a scratch repository and read the note.

**Gate** — what must pass before approval:

- The walkthrough shows the three stages in one document, the smoke tests pass, and
  no published-release overwrite path was added.

## Considerations

- The risk is inventing a third store for continuity's sake. Two exist by decision
  and the derivation is the truth; a third would drift within a week.
- This ticket depends on the plan seam existing but not on Open Decision 1's
  resolution — the confirmation join is the same work whichever way the planner runs.
- `.workaholic/release-notes/` is written only at ship and release time, never by a
  tick. That is deliberate and this ticket does not change it.

## Final Report

Development completed as planned.

**The map, written first** (step 1), because the value here is a join: the **plan** is
derived by `draft-release-note.sh` and projected into the target's GitHub draft release
by `sync-release-note.sh`; the **window** lives in `.workaholic/releases/<branch>.md`,
written at the cut by `record-release-cut.sh` and at each attempt by
`confirm-release.sh`; the **per-target attempt** is appended to
`.workaholic/release-notes/<slug>.md` (and to the branch story) by `record-evidence.sh`,
which is one writer with two destinations. Every one of those is correct and none of them
knew about the others.

**What "one continuous document" means here** (step 2): the note **derives** the other
two rather than storing them. `read-release-history.sh` reads the records where their own
writers keep them, and the renderer emits `## Deployment Plan` → `## Releases` →
`## Deployment Verification` in that order. No third store — two exist by decision and
the derivation is the truth, so a third would drift within a week — and no second source
of truth, because nothing new is written anywhere.

**Append-only survives by not writing at all** (steps 4 and 5). The projection cannot
violate an order it never touches: `record-evidence.sh` is still the one writer of an
attempt, `confirm-release.sh` of a confirmation, and no published-release overwrite path
was added. `not_run` and `bypassed` render exactly as loudly as `pass`, and a *failed*
window renders as loudly as a confirmed one — a continuity feature that showed only the
successes would make an unverified release look verified, which is the failure the
verification section exists to prevent.

Two blurs are refused in the rendered prose rather than left to the reader: a release
window is **repository-wide** (it carries the batch, so its confirmation is not a
statement about one target), and an empty stage says so in words rather than by an absent
section.

Verification: **3158 assertions** pass, of which 13 are the new `release note: plan then
release then verification, in one document` fixture — the empty state, a cut-and-confirmed
window, a failed one, newest-first order, per-target attempts including `not_run`, the
three sections in order, that the render writes nothing, and that two renders are
byte-identical. `sh scripts/e2e/loop-drill.sh verify-cadence` passes (4/4 load-bearing),
`verify-planner` passes, and `posix-lint.sh` / `build.mjs` / `verify.mjs` /
`validate-metadata.mjs` / `layout-doctor.sh` are clean.

### Discovered Insights

- **Insight**: the two records have different **scopes**, and rendering them the same way
  would have been the bug this ticket could most easily have shipped.
  **Context**: a `release/*` window is repository-wide while a deployment attempt is
  per-target, so a batch confirmation displayed under a target's plan would tell a reader
  their target was checked when the batch containing it was. The note labels the
  difference in the section's own prose.
- **Insight**: continuity did not need any new writer, only a new **reader**.
  **Context**: every record needed already existed and had exactly one writer. Adding a
  reader keeps all three writers' invariants (append-only, never-overwrite-published,
  one-writer-two-destinations) true by construction rather than by re-checking them.
- **Insight**: `record-evidence.sh` appends its block at the **end of its section**, not
  at EOF, precisely because the generated draft ends with `## Links`.
  **Context**: the new `## Releases` section sits above `## Deployment Verification`, so
  that 2026-08-17 fix keeps holding — an attempt still lands inside its own section, and
  the join did not have to move it.
