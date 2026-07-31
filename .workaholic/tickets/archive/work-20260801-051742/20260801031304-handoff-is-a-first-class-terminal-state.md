---
created_at: 2026-08-01T03:13:04+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 2h
commit_hash:
category: Changed
depends_on: [20260801031301-resume-a-claimed-but-unfinished-unit.md]
mission:
merge_policy: auto
claim: work-20260801-051742
---

# There is no sanctioned way for a run to hand unfinished work to a person

## Overview

`/drive`'s failure contract closes every **ticket** into one of four outcomes,
and §7 classifies every **unit** as shipped / at a PR / demoted / blocked. None
of those says *"a person, or a person's agent, must pick this up from here, and
this is where to start"*. A `blocked` unit records a named external blocker; a
unit at a PR is finished work awaiting review. A unit that was genuinely
half-driven — the run ran out of window, or hit something it decided not to
decide — falls between them and is reported only as prose in the run report,
which is a log nobody re-reads.

The branch story has no section for it either. Section 6 is Concerns (risks and
leftovers, extracted to the feedback stream at ship time) and section 9 is Notes;
neither is "here is the state of this branch and the next action for whoever
takes it". So the artifact a human actually opens — the pull request — does not
carry the one thing they need.

Measured 2026-08-01 while designing an hourly unattended runner. It matters most
there: a cloud run's worktree exists only inside its sandbox, so once the session
ends the pushed branch and its PR are the entire inheritance. Recording the
handoff in the run's stdout means recording it nowhere.

## Policies

- `workaholic:implementation` / `policies/observability.md` — an unfinished run whose remaining state lives only in a log is a masked failure; the terminal state must be legible from the durable artifact.
- `workaholic:implementation` / `policies/objective-documentation.md` — a handoff is only useful if it is concrete: the command that failed with its raw output, not "this needs a human".
- `workaholic:development` / `policies/overnight-ai.md` — the morning review is the point of an unattended window, and it reads the PR.
- `workaholic:development` / `policies/review.md` — the non-delegable looking-through happens at the PR, which is exactly where the unfinished state must be stated.
- `workaholic:implementation` / `policies/directory-structure.md`, `policies/coding-standards.md` — layout and house style.

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` - the four-outcome ticket contract and the §7 unit classification and terminal-token table
- `plugins/workaholic/skills/report/SKILL.md` - *Story Content Structure*, sections 1-9, where a handoff section must be defined
- `plugins/workaholic/skills/report/scripts/create-or-update.sh` - publishes the story as the PR body; already updates an existing PR in place
- `plugins/workaholic/skills/report/scripts/shrink-pr-body.sh` - bounds the body under GitHub's 65,536-char limit; a handoff must never be what gets dropped
- `plugins/workaholic/skills/review-sections/SKILL.md` - generates story sections 4-7 from archived tickets
- `docs/drive-loop-runbook.md` - §5 *Observability* and *Failure modes*, what an operator reads
- `outputs/workflows/` - the report and drive skills ship cross-agent; regenerate after changes

## Implementation Steps

1. Add `handoff` to the **unit** classification in `drive/SKILL.md` §7, beside shipped / at-a-PR / demoted / blocked. Define it precisely so it cannot absorb the others: the unit's queue is **not** drained, the work that exists is pushed, and continuing it requires a person or another session — as distinct from `blocked` (a named external blocker, nothing further is possible) and from a `review` unit at a PR (the work is *done* and awaiting a look).
2. Do **not** add a fifth ticket outcome. The four-outcome ticket contract is closed and reconciles to the unit's queue; `handoff` is a property of the unit, computed from its tickets, not a new per-ticket verdict.
3. Add a **Handoff** section to the story structure in `report/SKILL.md`, written only when the unit is in that state and omitted entirely otherwise (the same omit-when-empty discipline the other optional sections follow). Its content is fixed and short: what is done, what is not, the exact next step, and any command that was attempted with its raw output.
4. Place it so a reader meets it first — a handoff the reviewer finds after eight sections has failed at its one job — and make `shrink-pr-body.sh` treat it as non-droppable when it bounds the body.
5. Make `/drive` §5/§7 emit it: a unit ending in `handoff` writes the section, opens or updates its PR through the existing `create-or-update.sh` (partial work included — an unpublished handoff is not a handoff), and posts the PR URL through the same notifier the `review` route uses.
6. Put `handoff` on the `pending` side of the terminal-token table: a unit awaiting a person is claimable work outstanding, and `ok` would be the confident-incomplete report §7 forbids.
7. State the recovery in `docs/drive-loop-runbook.md` §5, next to the resumption path from `20260801031301-resume-a-claimed-but-unfinished-unit.md` — a handed-off unit is exactly the shape a later run resumes, so the two must describe one story rather than two.
8. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`).

## Quality Gate

**Acceptance criteria**

- `drive/SKILL.md` §7 defines `handoff` with a boundary test that distinguishes it from `blocked` and from a `review` unit at a PR, and the terminal-token table places it on the `pending` side.
- The ticket-outcome contract still has exactly four values; no fifth outcome is introduced.
- `report/SKILL.md` defines a Handoff story section with the four required elements (done / not done / next step / attempted command with raw output), written only for a handoff unit and omitted otherwise.
- `shrink-pr-body.sh` never drops the Handoff section when bounding an over-limit body; a fixture story that exceeds the limit still shows Handoff in the emitted body.
- A handoff unit's PR is opened or updated with the partial work pushed — verified against a story fixture through `create-or-update.sh`'s existing update path, with `gh` stubbed.
- `docs/drive-loop-runbook.md` describes handoff and its recovery in the same place as resumption.
- All of the above land in the same commit as the code.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with new cases for: the over-limit body retaining Handoff, the section being absent for a non-handoff story, and `create-or-update.sh` taking the update path for an existing PR (`gh` stubbed on `PATH`; the suite never calls the network).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the report and drive skills are regenerated with no residual `outputs/` diff, and intra-bundle links still resolve.
- Read-through of the boundary test in `drive/SKILL.md` §7 against the existing `blocked` definition, confirming no unit shape satisfies both.

**Gate**

- The suite is green including the shrink-retention case, and §7's boundary test is written — a handoff state that a run can reach by relabelling a `blocked` unit is worse than no state at all.

Decided: the PR body is the handoff artifact, not a new file under `.workaholic/` — the PR is what a person opens, `create-or-update.sh` already updates it in place, and a new artifact type would require a directory registration under the closed-layout policy for no added reach (developer may override at /drive).

Decided: a unit-level state rather than a fifth ticket outcome — the four ticket outcomes reconcile to the unit's queue and that arithmetic is load-bearing in §7; "a person continues from here" is a statement about the unit, not about any one ticket (developer may override at /drive).

Decided: hermetic suite with `gh` stubbed — the acceptance criteria are about what the emitted body contains and which code path runs, both observable without a network call (developer may override at /drive).

## Considerations

- The handoff text and the run report will overlap; the run report stays the log and the PR section stays the durable record. Say which is authoritative in `drive/SKILL.md` so a future change does not delete one as redundant (`plugins/workaholic/skills/drive/SKILL.md` §7).
- Making a section non-droppable narrows what `shrink-pr-body.sh` can shed; if both a large concern corpus and a handoff are present the body could still exceed the limit, so confirm the shedding order still terminates (`plugins/workaholic/skills/report/scripts/shrink-pr-body.sh`).
- `handoff` must not become the soft landing for work the run simply did not want to attempt. The failure contract's "attempt every ticket" rule governs first, and the boundary test in step 1 is what keeps that true (`plugins/workaholic/skills/drive/SKILL.md`, *The failure contract*).
- Depends on `20260801031301-resume-a-claimed-but-unfinished-unit.md`: the Handoff section's "next step" wording differs depending on whether a later run can resume the unit automatically or a person must check the branch out by hand.

## Final Report

Development completed as planned. `handoff` is a unit-level state with a boundary test,
the ticket-outcome contract is still four-valued, and the Handoff story section is
retained by `shrink-pr-body.sh` under every bounding path.

### Discovered Insights

- **Insight**: Placing the Handoff section first makes head-truncation preserve it *by
  accident*, and an accident is not a guarantee — one template edit that moved it below
  section 1 would have silently reintroduced the exact failure. Retention is therefore
  explicit: the block is lifted out, the remainder is bounded, and the block is put
  back. The test that proves this is the second one, which forces the *hard-truncation*
  path with an oversized section 1 rather than an oversized section 6; the first test
  would pass on positional luck alone.
  **Context**: When a rule is "X must survive", assert it on the path where X's survival
  is not already implied by the layout.

- **Insight**: The boundary between `handoff` and `blocked` reduces to one question —
  *could this be continued?* A blocked unit hit a named external blocker and nothing
  further is possible; a handoff unit could be continued by anyone who picks up the
  branch. That single question also keeps `handoff` from becoming the soft landing for
  work a run simply did not want to attempt, because "I could continue this" is exactly
  what "attempt every ticket" already obliges the run to do.
  **Context**: The three-row contrast table in `drive/SKILL.md` §7 is written so a
  future reader can apply the test without re-deriving it.

- **Insight**: `handoff` and the resumption path from `20260801031301` are one story
  told at two moments, not two mechanisms: a handoff unit is precisely the shape a later
  run resumes. Documenting them apart would have produced two recovery narratives that
  drift; the runbook now states them in the same place.
  **Context**: They landed in the same PR-unit for this reason, and the `## Handoff`
  section's "next step" wording depends on resumption existing.
