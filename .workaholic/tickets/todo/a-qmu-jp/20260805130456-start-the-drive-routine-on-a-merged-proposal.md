---
created_at: 2026-08-05T13:04:56+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: drive-on-a-merged-proposal-and-report-it-in-that-proposal-s-thread
merge_policy:
---

# Start the drive routine on a merged proposal

## Overview

PROPOSED. `[Drive]` is the only scheduled template — `trigger: cron`, `56 * * * *` —
and it runs `/drive auto` over whatever the survey offers, unrelated to the proposal
whose work it picks up. The reporter asks that it start on detecting a proposal's
pull request merging instead. `[Consent]` already fires on a merged pull request,
so this ticket settles which of the two owns the proposal-merge case rather than
leaving two routines watching one event.

The clock is doing work a merge event cannot cover, and deciding what happens to it
is the substance here rather than a follow-up: a `handoff` unit is resumed by "a
later run", a lapsed claim becomes `resumable` after thirty minutes and needs a tick
to take it, and a ticket written by `/ticket` rather than by a proposal has no merge
event at all — both tickets queued today are exactly that. Whether a low-frequency
cron floor is kept beside the event trigger is a decision this ticket must make and
record with its reason, not drop by omission.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/drive.md` — the template: `trigger`,
  `cron_expression`, and the prose calling it the only scheduled template
- `plugins/workaholic/skills/workaholify/routines/merged-pr.md` — `[Consent]`, already
  event-driven on a merged pull request; where the overlap is settled
- `plugins/workaholic/skills/workaholify/SKILL.md` — the routine model and the drift report
- `CLAUDE.md` — names `[Drive]` as the hourly scheduled routine in several places
- `docs/drive-loop-runbook.md` — the operator's page for the hourly loop

## Implementation Steps

1. Establish what a Claude Code Web routine trigger can actually key on — any merged
   pull request, or one identified as a proposal. If only the former, the narrowing
   belongs in the prompt, and that is what the template says.
2. Decide whether `[Consent]` or `[Drive]` owns the proposal-merge event, and write
   the reason into the template that keeps it.
3. Decide whether a low-frequency cron floor stays beside the event trigger, covering
   handoff resumption, lapsed claims and unproposed backlog. Record the reason beside
   the trigger, so the next reader does not re-open it.
4. Change `drive.md`'s frontmatter to match, and the prose that calls it the only
   scheduled template.
5. Update `CLAUDE.md`, the `workaholify` SKILL and `docs/drive-loop-runbook.md` in the
   same commit.
6. Leave the live routine alone — rolling a template change out is `/setup-routines`'
   verbatim-confirmed refresh, a human act, and an unattended run cannot do it.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `drive.md` states its trigger and, beside it, why the clock is or is not retained.
- No document still calls `[Drive]` the only scheduled template if it no longer is.
- The `[Consent]` overlap is settled in prose, so one routine owns the event.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- Search the repository for surviving "only scheduled" / "hourly" claims about `[Drive]`

**Gate** — what must pass before approval:

- The docs land in the same commit as the template change.
- No live routine is created, refreshed or disabled by this ticket.

## Considerations

- What a routine trigger can key on is a capability question about Claude Code Web
  routines, and it must be answered before the frontmatter changes. A trigger that can
  only watch merges generally pushes the proposal-narrowing into the prompt.
- Dropping the cron outright strands whatever no proposal produced — including the two
  tickets queued today — and leaves handoff resumption and lapsed claims with nothing
  to pick them up. That is why the decision is scoped into this ticket rather than
  assumed either way.
