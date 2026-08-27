---
created_at: 2026-08-27T16:20:01+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827161955-name-the-merge-that-turned-the-base-red.md
mission: read-whether-the-base-survived-what-the-loop-merged
merge_policy:
verification_handoff: 
---

# Name the base's health in the driving run's report

## Overview

<!-- PROPOSED. -->

`/implement` drives on top of the base every half hour and has no idea what state
it is in. This ticket has the driving run **name the reading** in its run report,
beside the per-unit outcomes it already carries — so the run that drove onto a red
base says so in the record of that run.

The **terminal token deliberately does not move**. A red base is not a fact about
the unit this run drove, and §7's table belongs to one mission at a time — the same
reason `backlog_all_excluded` moves no token. A run that drove its unit cleanly onto
a base somebody else broke still reports `ok`, and names the red base while doing it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — degrade by name, never silently

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §7's run-report contract and its terminal
  token table. Read §7 whole before touching it; the token rules there are load-bearing
  and each row has a measured reason.
- `plugins/workaholic/skills/drive/scripts/read-base-checks.sh` — ticket 1's reader.
- `plugins/workaholic/skills/drive/scripts/attribute-base-red.sh` — ticket 2's walk,
  for naming the merge when the answer is red.
- `plugins/workaholic/commands/implement.md` — if the report's shape is named there.

## Implementation Steps

1. Read `drive/SKILL.md` §7 in full, including the rows that state which readings move
   the token and which do not, and why each does what it does.
2. Read the base's health once per run — not once per unit. It is one fact about the
   repository, and a per-unit read would spend N times the calls to say the same thing.
3. Name it in the run report in the three words the reader already uses: `green`, `red`
   (with the attributed merge and the failing checks), or `unanswerable` with its reason.
   A degraded read is reported as degraded, never as green.
4. **Change no token rule.** State explicitly in §7 that the base reading moves no token,
   and why — so a later reader does not "fix" the apparent omission. `ok` stays reachable
   on a red base.
5. Decide where in the report it sits and state it: recommended is once, near the run's
   opening, before the per-unit outcomes — it is context for everything that follows
   rather than an outcome of any one unit.
6. Do **not** gate driving on it. `/implement` keeps driving onto a red base; quality is
   gated at the `release/*` QA window, and giving an unattended runner a new way to stop
   is the fork this mission's own ask rejected.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- every driving run's report names the base reading in one of the three words
- a red reading names the attributed merge and the failing checks
- an `unanswerable` reading is reported as such, never as green
- the terminal token is byte-identical to today's for every reading, `red` included
- the run drives exactly as it did before — nothing is gated, skipped or stopped

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-base-health` (ticket 7) asserting the token is unmoved
- `sh scripts/e2e/loop-drill.sh verify-implement` — the existing drill still passes unchanged

**Gate** — what must pass before approval:

- a simulated run over a red base reports `ok` and names the red base
- no new stopping condition exists anywhere in the driving run

## Considerations

- The reading is **one network read per run**, at most. If the ticket-2 walk is only
  needed to name a culprit, call it only when the answer is red.
- The tempting next request is to gate on this. Refuse it deliberately: the standing
  decision is that `main` is the continuously auto-merged development branch and quality
  is gated at the QA window. Read and say; never gate.
- An `/implement` run report is read by nobody on the day it matters — which is why
  ticket 3's question exists and this ticket is not a substitute for it.
