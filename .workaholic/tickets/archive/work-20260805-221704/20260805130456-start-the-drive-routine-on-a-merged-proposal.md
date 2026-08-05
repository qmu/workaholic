---
created_at: 2026-08-05T13:04:56+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash:
category: Changed
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

## Final Report

Development completed as planned. All three decisions the ticket scoped were made and
recorded beside the trigger they govern, and the first one turned out to be a capability
finding rather than a judgement call.

### Discovered Insights

- **Insight**: A Claude Code Web routine record has **no event-subscription field at
  all**. Read back over the whole live account (`RemoteTrigger list`, 20 routines), the
  entire trigger surface is `cron_expression`, `run_once_at`, and an API token
  (`api_token_hint` / `api_token_created_at`) that lets an external caller POST
  `/v1/code/triggers/<id>/run`. Nothing names a repository, a pull request, a merge or a
  webhook.
  **Context**: `trigger: event` in the templates never described a subscription — it
  described a routine with no schedule waiting to be invoked. Every design that assumed a
  routine could key on a repository event was assuming a field that does not exist, which
  is why the frontmatter now reads `trigger: invoked` and the word is pinned by a test.

- **Insight**: **No `[Propose]` or `[Consent]` routine has ever fired.** All 8 `[Consent]`
  and 7 `[Propose]` routines carry an empty cron, no `run_once_at`, no API token, and no
  `last_fired_at` key at all, the oldest created 2026-07-31. The only routines in the
  account that have ever run are the two cron ones and four one-off `run_once_at`
  diagnostics.
  **Context**: Two runbooks and three templates describe what happens "when the merge
  fires this routine", and that path has never executed once. `last_fired_at` being
  *absent* rather than null is the cheap tell, and `RemoteTrigger list` answers it in one
  call — worth running before trusting any prose about what a routine does.

- **Insight**: The ask behind this ticket ("start the run on a merged proposal") decomposes
  into a trigger question that has no answer and an **invoker** question that does. The
  invoker — a token plus something that POSTs `/run` — is a standing outward-facing
  process, so it is a human act under *What may be applied unattended*, not a change an
  agent lands.
  **Context**: This is why the clock stays and why `[Consent]` keeps the merge event
  rather than `[Drive]` growing a second watcher of it. The invoker is queued as its own
  ticket rather than attempted here.
