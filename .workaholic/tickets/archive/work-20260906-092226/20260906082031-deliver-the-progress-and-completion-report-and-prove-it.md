---
created_at: 2026-09-06T08:20:31+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: work-a-recoverable-state-instead-of-handing-it-over
mission: finish-the-backlog-without-handing-it-back-to-the-operator
merge_policy:
verification_handoff: 
---

# Deliver the progress and completion report, and prove it

## Overview

A report written into a local transcript is not a delivered report. The current quiet-tick
policy and the exact-thread refusal leave the initiating user with neither the periodic
progress nor the final result the ask names — and a shell launcher cannot promise a callback
into the initiating chat without an actual return transport. A missing historical thread must
not erase the operator-facing account of current progress: an unresolvable lookup posts a new
keyed root, which is what the lookup's own not-found branch already exists for.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the loop is a running system; a degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — the tick's ceiling for what it
  posts and where.
- `plugins/workaholic/skills/notify/SKILL.md` and `reference/notifications.md` — the shapes,
  the transports, and the stateless thread lookup with its case-4 root.
- `plugins/workaholic/skills/story/scripts/record-unposted-line.sh`,
  `read-unposted-line.sh`, `clear-unposted-line.sh` — the existing carry-and-retry shape for a
  refused post; compose it rather than re-deriving it.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the relay envelope and ack paths.
- `plugins/workaholic/skills/work/reference/other-agents.md` — where the return transport per
  surface is stated.

## Implementation Steps

1. **Reproduce and localize.** Run one tick whose thread lookup resolves nothing and record
   where its report ends up. Record separately what a `codex exec` worker's report reaches and
   what the initiating chat receives.
2. Establish the supported reporting destination per entrypoint, named at startup: an absent
   delivery path is **named**, never substituted for one that delivers somewhere else.
3. Consume the worker outcomes ticket 3 made trustworthy and compose the periodic report from
   them, not from the coordinator's own guess.
4. Record delivery acknowledgement, and recover a failed delivery **without duplicate posts** —
   the unposted-line record is idempotent and clears on a landed send; use it.
5. A missing thread posts a new keyed root rather than nothing. Never a similarity match,
   never recency; the not-found branch is what makes the lookup safe.
6. State the completion report's own contract: it rests on merged work plus a fresh queue and
   pull-request reconciliation, not on the tick's own bookkeeping.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Successive tick reports and one completion report reach the selected surface, and each is
  proved delivered rather than assumed.
- A failed delivery is retried once and never duplicated; a still-refused one is reported as
  unposted.
- An unresolvable thread produces a keyed root, and a session with no delivery path says so at
  startup.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- the reproduction named in step 1, re-run, now answering differently

**Gate** — what must pass before approval:

- the suite and the classified drill set both pass, and step 1's reproduction is shown before and after

## Considerations

- **The ask's constraint**, recorded as given: a shell launcher cannot promise a callback into
  the initiating chat without an actual return transport. Step 2 must measure what each
  entrypoint really exposes rather than assume the Claude-Code shape.
- Duplicate-post risk is the real hazard here; the existing unposted-line record is the
  reason this needs no new store, cursor or timer.
- The quiet-hours and cool-down rules exist for a reason and are not swept aside — what
  changes is that the initiating user's own run reports to them, which is not the channel
  waking somebody to say nothing.

## Final Report

**Step 1 — reproduced, and the answer is that two of the three destinations were never named.**
`--dispatch <role>` printed `started pid=… log=<dir>/dispatch-<role>.log` and returned instantly; the
detached child then wrote its report to `<dir>/<stamp>-<role>.md` and its stdout to that dispatch
log. **The initiating chat received nothing at all**, and nothing anywhere said so. The
coordinator's own tick report reached `<dir>/<stamp>.md` and the supervisor's stdout; under the
desktop Scheduled task it reaches the chat the task was created in, and under Claude Code's `/loop`
it reaches the session, which *is* the chat. Separately, `show_workers` printed only `idle` /
`running` — process liveness — so the periodic report said nothing about whether the last run had
executed or what became of it.

**Step 2 — the destination is now established per entrypoint and named at startup.** The table is
`skills/work/reference/other-agents.md`, *Where a report goes, per entrypoint*, and the launcher
says it in those words: `codex loop reports: dir=<dir> chat_return=none` on `--status`, and
`codex dispatch <role>: report=<dir> chat_return=none` at the moment a child is detached. **An
absent delivery path is named, never substituted for one that delivers somewhere else** — and the
absence is structural rather than a bug: `--dispatch` returns before the work starts and the child
outlives it, which is the lifetime the port needed, so no result can come back through the process
that returned. Holding the coordinator open to collect one is the cadence failure #984/#985 named.

**Step 3 — the report is composed from what the workers reported.** `last_worker_outcome()` reads
each role's newest `loop-attempt-<role>` line — the record ticket 3 made trustworthy, which keeps
*the process terminated*, *the role executed*, *the work completed* and *the notification was
delivered* as four facts — and `--status` now carries `last_outcome=<word>` per role. A role with no
recorded attempt reads **`unrecorded`**; an unreadable log reads `unreadable:<reason>`. Neither is
ever rendered as a healthy finish.

**Steps 4 and 5 — composed, not re-derived.** The carry-and-retry shape already exists and is cited
rather than rebuilt: `record-unposted-line.sh` carries a refused line on the unit's own story (one
`## Unposted Line` section replaced rather than stacked, so it is idempotent),
`list-unposted-lines.sh` offers it to a later tick, `clear-unposted-line.sh` clears it on a landed
send, and a still-refused send leaves the record standing and is reported as unposted — one retry,
no duplicate. An unresolvable thread posts a **new keyed root**, the stateless lookup's own case 4;
never a similarity match, never recency.

**Step 6 — the completion report's contract is stated.** *Everything is done* rests on merged work,
a drained queue and a reconciled set of open pull requests — the readings `plan-units.sh`,
`list-claims.sh` and `list-stranded-publications.sh` already make — and never on the tick's own
bookkeeping. A tick that cannot make those readings reports them as unreadable and claims no
completion.

**Reproduction re-run, now answering differently**: `--status` prints
`codex worker <role>: idle last_outcome=unrecorded` for each role and
`codex loop reports: dir=… chat_return=none`. The report's destination and the absence of a chat
return are both stated where a reader meets them.

**What this ticket did NOT do, stated rather than implied.** Proving a *delivered* Slack report
end to end needs a live channel, and this run was instructed to ignore Slack entirely; the delivery
proof over a real transport belongs to the end-to-end drill ticket, which is where the acceptance
"proved delivered rather than assumed" is exercised against a running surface.

**Docs updated in the same change**: `skills/work/reference/other-agents.md` and
`commands/infinite-development.md`.

**Gate.** `node scripts/test-workflow-scripts.mjs` — 6663 passed, 0 failed.
