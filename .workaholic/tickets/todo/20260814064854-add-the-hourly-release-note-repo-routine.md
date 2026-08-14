---
created_at: 2026-08-14T06:48:54+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: split-routine-setup-into-developer-and-repository-scopes
merge_policy:
---

# Add the hourly release-note repo routine

## Overview

PROPOSED. The trial routine the ask names for `/setup-repo-routines`: one that runs
`/ship` hourly to keep the release notes current. It is the first repository-scoped
routine, so it is also the proof that the scope split from the first ticket buys
something. Note what it revisits: `CLAUDE.md` currently records "Do not reintroduce a
third routine", and rules that the deployment-plan refresh rides `[Implement]`'s tick
precisely because a third routine "costs every consuming repository a setup step".
The repository scope is the operator's answer to that objection — one account
configures it, not every member — so this ticket must rewrite that reasoning rather
than quietly contradict it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/` — the new repository-scoped template lands beside `fb.md` and `implement.md`.
- `plugins/workaholic/skills/ship/SKILL.md` §5 + `scripts/draft-deploy-plan.sh`, `read-deploy-state.sh` — what `/ship` actually refreshes, and the idempotence (`changed: false`) the routine depends on.
- `plugins/workaholic/skills/write-release-note/SKILL.md` — the note's structure the routine keeps current.
- `CLAUDE.md` — *Routines* ("Do not reintroduce a third routine") and the deployment-plan-refresh paragraph both have to be rewritten, not left standing.
- `plugins/workaholic/skills/notify/SKILL.md` — a new routine that posts needs its postable events named; the prompt is the ceiling.

## Implementation Steps

1. Resolve the Open Decision below first — the template cannot be written until what "run `/ship` to update the release notes" means with no claim and no unit in hand is decided.
2. Write the template as a thin pointer, exactly like the existing two: the command, the post formats it is authorized to emit, the environment. Every rule stays in the skill that owns it.
3. Give it `scope: repository` (first ticket's field), an explicit non-`:00` cron minute (a bare `:00` is rewritten to server jitter), and `autofix_on_pr_create` set the same way the other templates set it.
4. Make the no-op path silent and cheap: a tick with nothing to refresh writes nothing and posts nothing — `draft-deploy-plan.sh` is already idempotent, and the bright line says a tie goes to silence.
5. Rewrite `CLAUDE.md`'s two paragraphs to state the new arrangement and why the earlier objection no longer holds, keeping the earlier reasoning visible as history rather than deleting it.
6. Extend `scripts/e2e/loop-drill.sh` so this routine is drillable on demand like the other two, rather than verified by waiting an hour.
7. Regenerate `outputs/` and run the local verification set.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A repository-scoped routine template exists and is configured only by `/setup-repo-routines`.
- A tick with nothing to refresh writes nothing, commits nothing and posts nothing.
- `CLAUDE.md` states the current arrangement, with the superseded "no third routine" reasoning kept as history.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-plan` (extended to cover this routine)
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && git diff --exit-code outputs/`

**Gate** — what must pass before approval:

- The commands above pass, the Open Decision is resolved in writing, and the routine demonstrably writes nothing on an idle tick.

## Considerations

- The standing objection to an hourly agent rewriting a document on `main` is that it is a new class of unattended write for a tree whose conflicts are resolved append-only. Whatever this routine does, keep it inside a pull request rather than committing to `main` directly.
- `/ship` merges pull requests. An unattended hourly `/ship` with a loose scope could merge something nobody expected — bound its scope explicitly and never let it override a gate.
- Depends on the first ticket for the scope field; drive them in order.

## Open Decisions

- **What does "run `/ship` once per hour to update the release notes" do when the session holds no claim and no unit?** `/ship` is context-aware: it drafts the deployment plan for the unit it is shipping and merges that unit's PR. Standalone and hourly, there is no unit. Three readings this session cannot choose between: **(a)** refresh the `## Deployment Plan` of the release note for the current `release/*` window, writing inside a pull request; **(b)** sweep open pull requests and refresh each one's plan, which is closer to what `[Implement]`'s tick already does per shipped unit; **(c)** something narrower the operator has in mind that is not `/ship`'s current contract at all, in which case the routine's command is not `/ship`. The driving session must resolve this explicitly and record the resolution in its Final Report — the choice decides whether `/ship` gains a new mode, which the one-behaviour-per-command rule constrains.
