---
created_at: 2026-08-05T22:35:14+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission: drive-on-a-merged-proposal-and-report-it-in-that-proposal-s-thread
feedback: [20260805130407-trigger-the-drive-routine-on-a-merged-proposal-and-report-start-and-completion-in-its-thread.md]
merge_policy:
---

# Stand up an invoker for the unscheduled routines

## Overview

Minted mid-run on 2026-08-05 while driving *Start the drive routine on a merged proposal*,
which needed to establish what a routine trigger can key on and measured this instead.

**`[Propose]` and `[Consent]` have never fired — in any repository.** Read back over the
whole live account (`RemoteTrigger list`, 20 routines), all 8 `[Consent]` and all 7
`[Propose]` routines carry an empty `cron_expression`, no `run_once_at`, **no API token**,
and **no `last_fired_at` key at all**, the oldest created 2026-07-31. The only routines
that have ever run are the two cron ones and four one-off `run_once_at` diagnostics.

They cannot fire, and the reason is structural rather than a misconfiguration: a routine
record has **no event-subscription field**. Its entire trigger surface is
`cron_expression`, `run_once_at`, and an API token letting an external caller POST
`/v1/code/triggers/<id>/run` (`skills/workaholify/SKILL.md`, *What a routine can be
triggered by*). "Event-driven" has always meant "waits to be invoked", and nothing holds a
token to invoke them.

So two loops the project believes it runs do not run: an inbound Slack report becomes a
proposal only when a developer runs `/propose` by hand, and a merge is announced only by
whichever drive session happened to make it. The templates, the prompts, the drift report
and both runbooks are all correct about what these routines *would* do — the trigger is
simply absent, which is why the failure has been invisible: a routine that never fires
looks identical to a healthy idle one from the routines list.

This ticket stands the invoker up. It is deliberately **not** the sibling ticket's work:
that one decided `[Drive]`'s trigger and recorded why the clock stays; this one restores
the two routines the measurement found inert.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a failure must be graspable from outside
- `workaholic:operation` / `policies/ci-cd.md` — how a standing delivery process is wired and operated
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — *What a routine can be triggered by*
  (the measurement) and *What may be applied unattended* (the human-act bar this must respect)
- `plugins/workaholic/skills/workaholify/routines/fb.md` — `[Propose]`, `trigger: invoked`
- `plugins/workaholic/skills/workaholify/routines/merged-pr.md` — `[Consent]`, and the
  reason it owns the merged-pull-request event
- `plugins/workaholic/skills/workaholify/scripts/lib/list_routines.py` — where a routine's
  reported state is assembled; a never-fired routine is not surfaced today
- `docs/proposal-loop-runbook.md` — §3, which describes provisioning the routine

## Implementation Steps

1. Decide the invoker for each routine and record the reason. The natural candidate is a
   GitHub Actions workflow in the target repository (`pull_request: closed` for
   `[Consent]`, an issue or Slack-sourced event for `[Propose]`) POSTing `/run` with a
   token held as a repository secret. Name what is rejected too — a self-hosted webhook
   relay adds a component nobody operates.
2. Establish how a routine gets an API token at all, and where the token lives. It is a
   credential for a standing outward-facing process, so its storage is part of the design,
   not a detail.
3. **Surface "never fired" in the reader.** `list-routines.sh` reports a routine's
   trigger, schedule and template status; it does not report that the routine has never
   run. A routine that cannot fire must not read as healthy — that is what let this go
   unnoticed for five days across fifteen routines.
4. Carry the invoker's existence into the drift report's preconditions, beside the Slack
   connector: an unscheduled routine with no invoker is as inert as one with no connector.
5. Do **not** create, refresh or re-point any live routine from an agent session. Standing
   up an outward-facing process is a human act, mediated by `/setup-routines`' verbatim
   confirmation. This ticket may write code and documentation; the rollout is separate.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A reader can answer "has this routine ever fired?" from `/setup-routines` output alone,
  and a never-fired routine is visibly distinct from a healthy idle one.
- The invoker's design is recorded with the rejected alternatives, in the `workaholify`
  SKILL beside the trigger-surface measurement.
- No live routine is created, refreshed, disabled or re-pointed by this ticket.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` for the reader's new field
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs`
- `RemoteTrigger list` read back, confirming the account is unchanged by the ticket

**Gate** — what must pass before approval:

- The docs land in the same commit as the code.
- Reading stays unattended-safe; every mutation stays behind the verbatim confirmation.

## Considerations

- The token is a credential for a process that can start cloud sessions against the
  repository. Where it lives and who can read it is a security-design question, not
  plumbing — the design step must answer it rather than assume a repository secret.
- `last_fired_at` is **absent**, not null, on a routine that has never run. Any reader
  added here must treat a missing key as the condition, the same way `check-deps` treats a
  missing `loaded_version_behind_registry`.
- Four one-off diagnostics in the account fired via `run_once_at` and are not a model for
  this: they were scheduled, not invoked.
