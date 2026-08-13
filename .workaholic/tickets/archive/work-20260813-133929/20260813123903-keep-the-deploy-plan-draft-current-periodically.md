---
created_at: 2026-08-13T12:39:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-deployment-plans-in-the-release-note-before-deploying
merge_policy:
---

# Keep the deploy plan draft current periodically

## Overview

PROPOSED. Issue #438's step 5: "this will be run periodically by managed agents". The ask's word for the plan is *maintained* — "ensure that a draft … is maintained in the Release Note, kept up to date by managed agents" — so a drafting phase nobody invokes satisfies the letter of the mission and not its point: a plan is only useful if it reflects `main` as of now.

The constraint is that this repository has already ruled on its standing processes. `CLAUDE.md` fixes **two** routines per repository — `[Propose]` (`15 * * * *`) and `[Implement]` (`30 * * * *`) — and states plainly: "Do not reintroduce a third routine." The API's minimum interval is one hour and its trigger surface is `cron_expression` / `run_once_at` / API token only. So the periodic refresh has to be carried by an existing surface, or the two-routine rule has to be amended deliberately — which is the developer's call, not this ticket's.

This ticket is last because it can only carry a refresh that already exists: the drafting phase, the idempotent writer, and the reader must all be in place before anything schedules them.

## Policies

- `workaholic:operation` / `policies/ci-cd.md` — a periodic delivery-path process and what it may do unattended
- `workaholic:development` / `policies/overnight-ai.md` — the standing-process stance for unattended runs
- `workaholic:development` / `policies/parallel-long-running-agents.md` — what a long-lived managed agent may own
- `workaholic:implementation` / `policies/operational-planning.md` — a scheduled job needs a stated owner, cadence and failure mode
- `workaholic:design` / `policies/modeless-design.md` — the refresh must not become a second behaviour of an existing command

## Key Files

- `plugins/workaholic/skills/workaholify/routines/implement.md` — the `[Implement]` template, the candidate carrier: a thin pointer whose prompt names only the command, the finish-post formats, and the environment.
- `plugins/workaholic/skills/workaholify/routines/fb.md` — the `[Propose]` template, the other existing tick.
- `plugins/workaholic/skills/setup-routines/` and `plugins/workaholic/commands/setup-routines.md` — what converges an account's routines against the templates; any cadence change lands here or it never reaches a fleet.
- `CLAUDE.md` (the `### Routines` section) and `plugins/workaholic/rules/workaholic.md` — where the two-routine rule is written; an amendment is a documentation change in the same commit.
- `docs/loop-drill-runbook.md` and `scripts/e2e/loop-drill.sh` — the operator's drill for the existing loops; a third periodic behaviour needs a drill step or it is unverifiable in practice.
- `plugins/workaholic/skills/drive/SKILL.md` — if `[Implement]`'s tick carries the refresh, the Unified Run is where the step is stated.

## Implementation Steps

1. Confirm the refresh is genuinely idempotent as built by the sibling tickets: two runs against an unchanged base leave the tree byte-identical and commit nothing. Without that, a periodic carrier produces one empty commit per hour, and this ticket must stop rather than schedule it.
2. Resolve the Open Decision below and record the resolution before touching a template.
3. Wire the chosen carrier: state the refresh as a step of the surface that owns it, with what it does when there is nothing to change (report and stop, never commit).
4. State the failure mode: what the tick does when the reader degrades (`unresolvable` range, unreadable base) — reported and skipped, never a half-written plan.
5. Keep the artifact path honest: a refresh that changes the plan publishes through the publish tree like every other artifact writer, and it must not create a branch of its own outside the two sanctioned patterns.
6. Add a drill step to `scripts/e2e/loop-drill.sh` (or the runbook's procedure) so the refresh can be verified on demand rather than by waiting an hour.
7. Update `CLAUDE.md`'s `### Routines` section, the rules docs, and `docs/` in the same commit; regenerate `outputs/` with argument-less `node scripts/build-plugins/build.mjs`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **Which surface runs the refresh periodically?** The ask says managed agents run it periodically; `CLAUDE.md` says do not add a third routine. Options: (i) fold the refresh into `[Implement]`'s existing hourly tick, which couples plan upkeep to the executor and runs it even when nothing was implemented; (ii) leave it operator-invoked and drop "periodically", which contradicts the ask; (iii) amend the two-routine rule and add a `[Ship]`-style routine, which reverses a written decision and multiplies per-repository setup. This session cannot recommend one — the rule and the instruction are both the developer's.
- **Does the refresh commit to `main` unattended?** The plan is a tracked artifact, so keeping it current means committing. A routine that pushes a document every hour is a new class of unattended write for this repository; a plan refreshed only inside a pull request is current only when something merges.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- One named surface refreshes the plan on a stated cadence, recorded in `CLAUDE.md`'s `### Routines` section and in the rules docs.
- A refresh with nothing to change commits nothing and reports that it found nothing.
- A degraded read is reported and skipped; no partially-written plan is ever committed.
- The refresh is verifiable on demand through the drill, not only by waiting for a tick.

**Verification method** — the commands/tests/probes that prove them:

- The drill's new step run twice in a row: the first may write, the second leaves `git status --porcelain` empty.
- A forced degraded read (a truncated clone) shows the tick reporting and skipping.
- `node scripts/test-workflow-scripts.mjs`, `build.mjs`, `verify.mjs` green; `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming.

**Gate** — what must pass before approval:

- The Open Decision resolved in writing, the twice-run idempotence demo, the degraded-read demo, and the suites green.

## Considerations

- The honest failure to avoid is scheduling a churn machine: an hourly agent that rewrites a plan document produces a commit stream nobody reads and conflicts with the append-only handling `catchup-main.sh` applies to `.workaholic/`.
- If the answer to the Open Decision is "operator-invoked", say so in the mission's own record. "Kept up to date by managed agents" would then be unimplemented by choice, which is a legitimate outcome only if it is written down rather than quietly dropped.
- A third routine costs every consuming repository a setup step and every operator a drill path; the two-routine rule exists because that cost was measured, not for tidiness.

## Final Report

Development completed as planned.

### Step 1 — the idempotence precondition, checked before scheduling anything

The ticket's first step makes scheduling conditional on the refresh genuinely being a
no-op against an unchanged base. Verified three ways before a template was touched:
`draft-deploy-plan.sh` returns `changed: false` on the second and third run; the note is
byte-identical; and with the first draft committed, `git status --porcelain` is empty after
a re-run. The hermetic suite pins all three, and `loop-drill.sh verify-plan` re-proves them
on demand against this repository's real targets.

### Open Decisions — resolved

- **Which surface runs the refresh periodically?** Resolved as **(i), `[Implement]`'s
  existing hourly tick (`30 * * * *`), through `/ship`'s drafting phase** — no third
  routine, and no unattended commit to `main`. Reasoning: option (iii) reverses a written
  decision ("Do not reintroduce a third routine") whose cost was measured, not assumed —
  every consuming repository gains a setup step and every operator a drill path. Option
  (ii) contradicts the ask outright. Option (i) costs nothing new: the plan lands inside
  the unit's own pull request, which is already how every artifact reaches `main`, and the
  refresh is idempotent so a tick with nothing to change writes nothing.
  **The limit is stated rather than glossed**: a repository whose units are all `review`
  never reaches `/ship`, so its plan refreshes only when an `auto` unit ships. "Kept up to
  date by managed agents" therefore holds to exactly that extent — recorded in `CLAUDE.md`'s
  `### Routines` section in those words, because the ticket is right that dropping it
  quietly would be the dishonest outcome.

- **Does the refresh commit to `main` unattended?** **No.** The plan is written on the
  unit's branch and reaches `main` when that unit's pull request merges — the same path
  every other artifact takes. An hourly agent pushing a rewritten document straight to
  `main` would be a new class of unattended write for a tree whose conflicts are resolved
  append-only, and the ticket's own Considerations name it as the failure to avoid.

### What was built for verifiability

`loop-drill.sh verify-plan` — no seed, no fire, no issue number. It drafts a plan into a
scratch note in the temp directory using this repository's real targets and real commit
range, so it writes nothing under `.workaholic/` and can run at any moment. Three
load-bearing rows: `plan_drafted`, `plan_idempotent`, `plan_degraded`. Run on this
checkout: **3 passed, 0 failed**. `docs/loop-drill-runbook.md` §5b carries the row→file
blame table, and notes that a red `plan_idempotent` is the one to act on first — it breaks
the *periodic* property the whole arrangement rests on rather than any single ship.

### Discovered Insights

- **Insight**: "verifiable on demand" was cheap to build only because the writer takes an
  arbitrary note path and the reader is a pure read.
  **Context**: The drill needs no fixture repository and no network: it points the writer
  at a temp file while the reader still sees the real repository. Had the writer resolved
  its own note (e.g. "the newest note"), the drill would have had to fabricate a whole
  checkout or write under `.workaholic/` — the two things it is built not to do.

- **Insight**: the two-routine rule survived contact with an ask that appeared to require
  breaking it, because the ask's *cadence* requirement and the rule's *count* requirement
  were never actually in conflict — only the assumed implementation was.
  **Context**: "Run periodically by managed agents" was satisfiable by an existing tick the
  moment the refresh became idempotent and branch-scoped. The general shape: before adding
  a scheduled surface, check whether the work can ride one that already fires.
