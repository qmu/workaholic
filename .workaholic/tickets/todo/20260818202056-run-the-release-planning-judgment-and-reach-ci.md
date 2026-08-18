---
created_at: 2026-08-18T20:20:56+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-draft-release-note-an-agent-s-release-plan
merge_policy:
verification_handoff: 
---

# Run the release planning judgment and reach CI

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

This is the mission's centre and its hardest constraint. The previous ticket gives
the note a seam that renders an agent-authored plan; this one makes an agent
actually author it, continuously, and delivers the result to the writer that holds
the permission.

The constraint is measured and stands: **CI holds `contents: write` and cannot
think; a routine container can think and cannot write a release.** `gh release` is
GraphQL-backed and refused to a Claude Code Web session, and REST answers *"Creating,
editing, or deleting releases is not permitted for this session type"*. Issue #512
explicitly affirms that the 2026-08-18 move of the writer to CI is correct and
should stand. So the work is not to move the writer — it is to decide where the
judgment runs and how its result crosses to the writer, without reopening a class of
unattended write that `workaholic:ship` §7 refused twice.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/delivery.md` — the delivery path this changes
- `workaholic:safety` / `policies/operational-security.md` — any credential a CI-run agent would need

## Key Files

- `.github/workflows/release-note-draft.yml` — the current writer; holds
  `contents: write` and defines its own checkout (`fetch-depth: 0` + tags).
- `plugins/workaholic/skills/ship/scripts/run-note-cadence.sh` — the cadence and
  the `--write` boundary that makes `/prepare-release` a pure reader.
- `plugins/workaholic/skills/ship/SKILL.md` §7 — the three refused writer designs
  and their measured reasons; whatever is chosen must answer them in writing.
- `plugins/workaholic/skills/workaholify/routines/prepare-release.md` — the routine
  template; its `allowed_tools` deliberately carries no `Write`/`Edit`.
- `plugins/workaholic/commands/prepare-release.md` and its skill — the command
  contract that promises it writes nothing, anywhere.

## Open Decisions

<!-- Forks this proposal cannot recommend one side of. The driving session
     resolves each explicitly and records the resolution in its Final Report. -->

1. **Where does the planning agent run, and how does its plan reach the CI
   writer?** Three seams were visible at proposal time, each with a real cost, and
   none is recommendable without the operator's ruling:

   - **(a) The agent runs in CI.** The `Release Note Draft` workflow already holds
     the write permission and a defined checkout, so the plan and the write happen
     in one place with no crossing at all. Cost: it needs an agent invocation and
     therefore a credential in CI, which is a new secret and a new failure mode for
     a workflow that is currently one `bash` line. Also makes every push to `main`
     potentially spend agent budget unless the cadence bounds it.
   - **(b) The agent runs on the `[Prepare Release]` tick and commits the plan for
     CI to read.** The container can think, and the plan is a file rather than a
     release, so no refused transport is involved. Cost: it makes the hourly routine
     a repository writer — precisely the class refused on 2026-08-13 ("an hourly
     agent rewriting a document on `main` is a new class of unattended write for a
     tree whose conflicts are resolved append-only") and again in §7. The routine's
     own contract says it writes nothing, anywhere.
   - **(c) The plan is authored at ship/report time, per unit, and accumulates.**
     No new routine, no new credential, no unattended `main` writer — this is how
     the deployment-plan refresh already rides `[Implement]`'s tick. Cost: it is not
     *continuous* re-arrangement, which is the word the ask uses; a repository whose
     units are all `review` would see the plan refreshed rarely, and the plan would
     be a stitching of per-unit judgments rather than one agent's view of the whole.

   Do not resolve this by picking the least-effort option. Record the ruling and its
   reasoning in `ship/SKILL.md` §7 beside the three refusals it is answering.

2. **What happens when no plan has been authored yet, or the planner fails?** The
   seam falls back to the derived list — but a reader cannot tell a deliberate
   fallback from a broken planner. Decide whether the note says so on its face.

## Implementation Steps

1. Resolve Open Decision 1 explicitly and record the ruling before writing code;
   a silent choice here is the failure this section exists to prevent.
2. Read `ship/SKILL.md` §7 and the 2026-08-13 / 2026-08-17 / 2026-08-18 records in
   `CLAUDE.md` in full. Each refused design has a measured reason; the chosen seam
   must answer them by name, not step around them.
3. Implement the planner: given the derived facts (the boundary, the unreleased set,
   per-merge substance from the previous ticket), produce a plan in the schema the
   first ticket defined — grouping, order, risk/coupling, what is held back.
4. Wire the plan to the writer along the resolved seam, and bound how often it runs
   so an idle base spends nothing.
5. Make failure honest: a planner that could not run reports by name and the note
   falls back visibly, per Open Decision 2. Never a silent revert to the list.
6. Keep `/prepare-release` a pure reader whatever is chosen — its contract states it
   in three places and a change there is a documentation change too.
7. Extend `scripts/e2e/loop-drill.sh` so the chain is provable on demand rather than
   by waiting for a tick, as `verify-plan` / `verify-cadence` already are.
8. Update `CLAUDE.md`, `ship/SKILL.md`, the routine template and the command docs in
   the same change.

## Quality Gate

<!-- Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- An agent's plan reaches the draft release for at least one target, end to end.
- Open Decision 1's ruling is recorded in `ship/SKILL.md` §7 with its reasoning.
- `/prepare-release` still writes nothing, anywhere.
- A failed or absent planner is visible in the output, not silently indistinguishable
  from a deliberate fallback.
- The chain is drillable on demand from `scripts/e2e/loop-drill.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-cadence` and the new drill target.
- `node scripts/test-workflow-scripts.mjs`
- Grep the routine template's `allowed_tools` and the command docs for the
  write-nothing contract.

**Gate** — what must pass before approval:

- The drill passes, the smoke tests pass, and §7 carries the ruling.

## Considerations

- If the resolution is (a), the credential is the real work: scope it minimally,
  never echo it, and decide what happens on a fork or a pull request from outside.
- If the resolution is (b), the append-only conflict convention is the real work —
  two containers writing one plan file is not the same shape as the housekeep log's
  `(tick, step)` union.
- The ask says *continuously re-arranges*. Whatever seam is chosen, state plainly in
  the docs how often the plan actually refreshes, so nobody reads "continuous" into
  a daily or per-ship cadence.
