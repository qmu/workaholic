---
created_at: 2026-08-14T06:48:54+00:00
status: done
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

  **RESOLVED 2026-08-14, driving this ticket: (c). The command is not `/ship`, and the routine
  does not write.** See the Final Report below for the measurement behind each refusal.

## Final Report

Development completed. The Open Decision was resolved first, as the ticket required, and it
changed what got built.

### The Open Decision, resolved: reading (c), and the routine is a reader

The `## Deployment Plan` is a **branch's prospective** section, drafted inside that unit's own
pull request by whoever ships the unit (`/ship` §5 step 3). Each of the three readings was taken
as a candidate *writer* and measured against this repository:

- **(a) Refresh a merged note on `main` — refused, self-referential.** The plan's datum is the
  base sha, and for any target that declares no `paths:` in its deployment record the range is
  `attribution: whole_range` — which is what this repository's own `marketplace` record does. So
  the refresh's **own** commit increments the `unreleased_count` it just reported. Each refresh
  invalidates itself and the next tick has something to write again: an hourly writer becomes a
  commit treadmill, human-paced at best (one PR per merge of the last one) and unbounded at
  worst. This is precisely the failure `draft-deploy-plan.sh` keeps a clock out of its section to
  prevent, arriving through the base sha instead of through a timestamp.
- **(b) Push the refresh into each open PR's branch — refused, it races another writer.** Those
  branches are not this routine's to write. A `work-*` branch under a live claim is pushed by
  `archive.sh` after every archive commit and by `heartbeat.sh` on the driving session's own
  schedule, so an hourly third writer contends with the claim protocol and with the developer's
  own pushes, for a section the shipping run will redraft anyway.
- **(b′) Run `/ship` itself, hourly — refused twice over.** `/ship` **merges**; an unattended
  hourly sweep with a loose scope merges pull requests nobody expected, which is the hazard this
  ticket's own Considerations named. And a unit-less sweep mode is a second behaviour on a
  command that has exactly one.

What survives is the strongest thing a machine may honestly do to a document whose
forward-looking half is a human's decision to act on: **check it and say what it found**. The
precedent is this repository's own `report/scripts/area-freshness.sh` — *it reports, it never
writes* — adopted 2026-08-13 for the same class of problem.

**Stated rather than glossed: the release notes are not updated by any tick.** The ask said
"update the release notes"; this delivers the check, not the write. `[Implement]` still refreshes
a unit's plan inside that unit's pull request whenever it ships an `auto` unit — unchanged — and
between ships `[Release Status]` is what tells a human the plan needs their hand. The remaining
write is the operator's call, and the three refusals above are its input; nothing here forecloses
it, and no design for it is invented on a guess.

### What was built

- `ship/scripts/report-deploy-status.sh` — a pure read over `read-deploy-state.sh`. Per target:
  what is waiting, since which boundary, whether a confirmation method exists, which note joined
  it, and `needs[]` naming what a human would have to do. Plus a `digest` that hashes the
  substantive state and **deliberately not the base sha**, so a base that merely advanced is not
  news.
- `/release-status` — the thin command; `workaholic:ship` §7 owns the contract and records the
  three refusals above.
- `[Release Status]` (`routines/release-status.md`) — `scope: repository`, `45 * * * *`,
  `autofix_on_pr_create: false`, and an `allowed_tools` list carrying no `Write`/`Edit`, which is
  the reader contract stated where the product can act on it.
- `workaholic:notify` — the `📦 Release status` shape as a top-level keyed root on
  `` `deploy:<digest>` ``, with **two** gates that both have to pass before anything is posted.
- `scripts/e2e/loop-drill.sh verify-status` — three load-bearing rows, in seconds.
- `CLAUDE.md` — the *Routines* table by scope, "do not reintroduce a third routine" superseded
  with its reasoning answered rather than deleted, and the deployment-plan-refresh paragraph
  rewritten to say what still rides `[Implement]` and what the new routine does instead.

### Discovered Insights

- **Insight**: a document on `main` that reports a property of `main` cannot be kept current on
  `main` without self-reference.
  **Context**: this is the general shape behind refusal (a), and it is worth keeping because the
  next "keep X up to date automatically" ask will meet it again. The test is mechanical: does the
  refresh's own commit change any value the refreshed document reports? If yes, the writer is a
  treadmill and the answer is a reader, a different datum, or a different home for the document.

- **Insight**: an hourly routine's hardest design problem is not what it does, it is what makes
  it silent.
  **Context**: `[Release Status]` needed two independent gates — nothing waiting, and nothing new
  to say — before a recurring post could survive `workaholic:notify`'s bright line at all. The
  content-keyed `deploy:<digest>` dedup is what supplies the second, and it needed the base sha
  kept *out* of the digest to work. That is why `verify-status`'s `status_stable` row is
  load-bearing: a single read is still correct when it goes red, and only the hourly property
  breaks.

- **Insight**: the routine's read-only contract is asserted three ways, on purpose, because prose
  decays.
  **Context**: the template's `allowed_tools` omits `Write`/`Edit` (the product enforces it), the
  drill asserts the working tree is byte-identical after a run (the test enforces it), and the
  command body states it (the reader learns it). A claim like "it only reads" that lives in one
  place is the kind that quietly stops being true.
