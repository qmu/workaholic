# The nine-step contract — reference

Companion to [`../SKILL.md`](../SKILL.md). One section per step: what it reads, **what it may
write**, what it returns in `needs_agent`, and the reasons it aborts with. The step ids are the
tick log's keys and `run.sh`'s step list — they are stable, and a step is renamed only with its
log history in mind.

Every step returns one JSON line:

```json
{"step": "<id>", "status": "ok|filed|skipped|degraded|blocked", "reason": "<stable cause>",
 "summary": "<one line for the log>", "needs_agent": []}
```

`status` is the tick log's closed vocabulary. `reason` is free-form but **stable per cause**, so a
report can be read by grep: `not_implemented`, `budget`, `requested`, `step_missing`, `step_error`,
`no_output`, `bad_output`, `no_connector`, `no_credentials`, `no_strategies`, `unreadable_inbox`,
`quiet_hours`, `already_filed`.

**`needs_agent` is the seam between the script and the model.** A step script is non-interactive
and composes no prose: it probes, it decides, and where the action is mechanical it files through
an existing seam itself. Anything that needs *composition* (an issue body, a question, a proposal)
or a *human surface* (Slack) is returned here, and the agent acts on it afterwards through the
seam this file names for that step — recording what it actually did under the step id `<step>-filed`.

---

## 1. `open-log` — open the tick's log

- **Reads**: the layout allowlist; `.workaholic/housekeeping/`.
- **Writes**: nothing. The log line `run.sh` writes for it *is* the open.
- **Aborts**: `no_workaholic_dir` (nothing here to keep), `area_unregistered` (this checkout's
  plugin predates the area — the tick still runs, its log does not), `unwritable`.
- **Never**: creates the area behind the layout gate's back. A step that made its own directory
  would be routing around the gate rather than reporting it.

## 2. `inbound-sweep` — Gmail, Drive, Slack and GitHub

- **Reads**: whichever connectors this session actually has, plus the repository's GitHub inbox
  through `gather/scripts/gh-rest.sh`.
- **Writes**: nothing directly. Candidates go to `needs_agent`; the agent files each one as a
  **feedback record** (`feedback/scripts/create.sh`, `--subject` naming *whose* opinion it is —
  never defaulted to the runner) and, when the ask names another repository, through `/fb`'s
  cross-repository mode with its verbatim confirmation.
- **Aborts**: `no_connector` per surface (named individually — three of four working is not
  "nothing found"), `unreadable_inbox`.
- **Dedup**: `log-read.sh --step inbound-sweep --contains "<id>"` before proposing anything, so
  the same message is not re-filed every hour.
- Ticket: `20260817113751`.

## 3. `workload-logs` — environments whose credentials are here

- **Reads**: the deployment targets that declare a readable log source, only where the credentials
  are actually present in this environment.
- **Writes**: nothing directly; a finding becomes a feedback record like step 2's.
- **Aborts**: `no_credentials` (named per target — a missing credential is a checked claim, never
  a forecast), `no_targets`.
- Ticket: `20260817113751`.

## 4. `merge-conflicts` — pull requests whose merge is blocked

- **Reads**: open pull requests over REST.
- **Writes**: **nothing to any branch.** It reports conflict state and returns the affected units
  in `needs_agent` for a Slack line. Pushing into an open pull request's branch was measured and
  refused (`workaholic:ship` §7): the branch belongs to whoever holds its claim, and this tick
  holds none of them.
- **Aborts**: `gh_unavailable`.
- Ticket: `20260817113752`.

## 5. `issue-triage` — stale issues, and GitHub↔`.workaholic/` drift

- **Reads**: open issues and pull requests; `.workaholic/tickets/`, `stories/`, `feedbacks/`.
- **Writes**: nothing directly. Consolidation and closure are **proposals**, not acts — an issue
  is somebody's words, and a machine that closed them hourly would be deciding what the project
  heard. The agent files each as a comment or a ticket through the existing seam.
- **Aborts**: `gh_unavailable`, `unreadable_inbox`.
- Ticket: `20260817113752`.

## 6. `stuck-prs` — what failed to auto-merge, and what it needs

- **Reads**: open pull requests, their mergeability and check state.
- **Writes**: nothing directly; the reminder is a Slack post, composed by the agent, naming **what
  needs a human decision** rather than that something is red.
- **Aborts**: `gh_unavailable`. **Dedup** against earlier ticks by `log-read.sh`, so one stuck pull
  request is not announced twenty-four times a day.
- Ticket: `20260817113752`.

## 7. `doc-drift` — the documentation against the current concept

- **Reads**: `README.md` first, then the documents the loop's own drift check already covers
  (`report/scripts/doc-drift.sh`, `area-freshness.sh`).
- **Writes**: nothing directly. Drift becomes a **ticket**, because fixing documentation is work
  and work has a queue; an hourly agent rewriting `main`'s documents is the unattended-write class
  this project has refused twice.
- **Aborts**: `no_docs`.
- Ticket: `20260817113752`.

## 8. `strategy-proposals` — expansion and consolidation for a strategy

- **Reads**: `strategy/scripts/list.sh`; the base state a proposal is constrained by
  (`propose/scripts/survey-state.sh`, `list-proposed-refs.sh`).
- **Writes**: nothing directly. Everything goes through `/propose`'s own publish path, so a
  proposal from this tick is the same artifact, with the same dedup and the same pull request, as
  a proposal from any other input.
- **Aborts**: `no_strategies` — the honest and, today, the *actual* outcome: the repository holds
  zero strategies, so this step has no data until the operator authors one.
- **The ruling it carries**: proposing from a strategy inverts `workaholic:propose`'s standing bar
  that feedback is the only input which can originate a proposal. That reversal is decided in the
  step's own ticket, with the retired `[Propose Batch]` design's reasoning answered rather than
  dropped.
- Ticket: `20260817113753`.

## 9. `human-checkin` — up to five questions, never late at night

- **Reads**: what the earlier steps returned; the clock, in the workspace's timezone.
- **Writes**: nothing to the repository. Questions are **Slack posts** — a routine-fired session
  has no `AskUserQuestion`, and this skill's standing rule forbids one anyway.
- **Aborts**: `quiet_hours` (with the boundary and timezone named), `no_surface`, `nothing_to_ask`.
- **Bounded**: at most five questions per tick, and the bound is enforced in the step, not left to
  the model's judgment.
- Ticket: `20260817113754`.

---

## What `run.sh` guarantees around the steps

- **Every step is invoked and every step reports.** Missing script → `degraded`/`step_missing`;
  non-zero exit → `degraded`/`step_error`; empty or unparseable output → `degraded`/`no_output` or
  `bad_output`; a status outside the log vocabulary → `degraded`/`bad_output`. A step never
  disappears from the report.
- **One writer.** Step scripts write no log line; `run.sh` does. Two writers would race on
  `(tick, step)` and make idempotence a property of caller discipline instead of of the code.
- **`--only` / `--skip` are for the operator and the tests**, and a skipped step is still a
  reported line (`skipped`/`requested`) — an unreported skip is the failure this whole design is
  built against.
