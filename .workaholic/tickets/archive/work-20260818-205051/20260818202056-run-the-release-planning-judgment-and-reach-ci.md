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

## Final Report

Development completed as planned.

### Open Decision 1 — where the planning agent runs: **(a), in CI, beside the writer**

Recorded in `ship/SKILL.md` §7 as a table beside the three refusals it answers, and in
`CLAUDE.md`. The reasoning, not the effort:

- **(b) plan on the tick and commit the plan** is the class §7 refused twice — an
  hourly unattended writer on `main` — and it contradicts `/prepare-release`'s own
  contract ("it writes nothing, anywhere") in three documents. A plan file is not a
  release, but it is a commit, and for a target declaring no `paths:` (0 of 1 here) the
  commit storing it increments the very count the plan is about. Choosing it would have
  reversed two measured decisions to avoid one secret.
- **(c) author per unit at ship/report time** fails on its own terms twice over: it is
  not continuous (a repository whose units are all `review` refreshes it rarely), and it
  has **nowhere to put the result** — a per-unit plan must be committed for a later CI
  run to read it, which is (b) wearing a different hat. It would also stitch per-unit
  judgments rather than produce one view of the whole release.
- **(a)** puts the judgment where the permission and the defined checkout already are.
  Nothing crosses between planning and writing, so it answers all three §7 refusals by
  name: no commit to `main`, no open pull request's branch written, `/ship` never run.

Its cost — a credential in CI — is the operator's act, so it is **gated and paid
visibly**: `WORKAHOLIC_PLANNER_CMD` (default `claude -p`) must be reachable, the
workflow's planner steps are skipped when `ANTHROPIC_API_KEY` is unset, and the note
falls back to the derived list. Nothing in this change requires the secret to exist; the
repository behaves exactly as it did before until somebody sets it.

### Open Decision 2 — a plan that never arrived: **the note says so on its face**

Passing `--plan` **is** the expectation, so any non-application under it renders a line
above the list: *"No release plan was applied to this draft (`<reason>`), so the merges
below are listed as derived rather than arranged."* A render that expected no plan stays
silent, and `empty_range` says nothing either — there is nothing to arrange when nothing
is waiting. No reader has to open the JSON to tell a broken planner from a deliberate
list, which was the whole of the decision.

### What shipped

`plan-release.sh` (the planner: facts from the renderer via `--facts-out`, a prompt, a
pluggable planner command, and a validation pass that **stamps** `target` and `base_sha`
rather than trusting an agent's copy of them), `list-due-targets.sh` (the spend gate),
`--plan-dir` on the cadence, `--plan` on the sync, the visible fallback in the renderer,
the workflow's three new steps, and `loop-drill.sh verify-planner`.

**How often it refreshes, stated plainly** because the ask says *continuously*: exactly
when the cadence would write — at most once per `Asia/Tokyo` day, plus whenever the
release stage advances. The workflow asks what is due *before* it plans, so an idle base
spends no agent budget.

Verification: **3146 assertions** pass, including 19 new ones covering the gate, the
authored plan, the stamping, the arrangement, all three named failures, the visible
fallback, the spend gate, and that the planner leaves the checkout untouched.
`sh scripts/e2e/loop-drill.sh verify-planner` passes on this repository (3 load-bearing
rows; the three that need a non-empty range are reported **unexercised by name** rather
than as passes, because this base has nothing unreleased). `posix-lint.sh`, `build.mjs`,
`verify.mjs` are clean.

### Discovered Insights

- **Insight**: an agent's answer is untrusted text, and the two fields that decide
  whether the renderer applies a plan at all (`target`, `base_sha`) are exactly the two
  a planner has no business choosing.
  **Context**: `plan-release.sh` stamps both after parsing and extracts the first
  balanced JSON object from whatever prose or code fence surrounds it. A planner that
  hallucinated a base sha would otherwise have rendered its own plan as stale.
- **Insight**: a GitHub Actions step cannot gate on `env.X` for a secret referenced only
  at step level.
  **Context**: the key is declared at **job** level so `if: env.ANTHROPIC_API_KEY != ''`
  resolves; without that the gate silently never fires and the planner runs keyless.
- **Insight**: the drill runs against the live repository, where the range is often
  empty (a tag sits on the base tip right after a version bump).
  **Context**: the rows that need merges are reported `unexercised` as advisory rather
  than counted as passes — a drill that reports "pass" for a check it could not run is
  worse than one that says it could not run it.
