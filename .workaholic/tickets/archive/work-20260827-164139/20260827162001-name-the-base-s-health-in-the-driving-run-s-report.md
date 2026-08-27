---
created_at: 2026-08-27T16:20:01+00:00
status: done
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

## Final Report

Development completed as planned. The driving run now reads the base's health **once**, in §1 of
the Unified Run, and names it at the **top** of the run report, before the per-unit outcomes.

- **The three words are the reader's own** — `green`, `red` (with the attributed merge and the
  failing checks, or `unattributable` with its reason), `unanswerable` with the reader's reason.
  A degraded read is reported as degraded and never as green.
- **Once per run, not once per unit.** It is one fact about the repository; the attribution walk
  is called **only** when the reader answers `red`, so a green base costs one call.
- **No token rule changed, and §7 says so explicitly** with the reason — a red base is not a fact
  about the unit this run drove, so `ok` stays reachable and a run that drove cleanly onto a base
  somebody else broke reports `ok` while naming it. The new table row states this rather than
  leaving the omission to be "fixed" later.
- **Nothing is gated.** §1's own paragraph says the run keeps driving onto a red base: no stop,
  no skip, no hold, no revert, no re-run, no different merge. `main` stays the continuously
  auto-merged development branch and the `release/*` window still owns quality.

Documents updated: `drive/SKILL.md` (§1's read and its gates-nothing paragraph, §7's report
opening and its token-table row) and `drive/reference/routing.md` (the run report's field list).
`commands/implement.md` is deliberately untouched — it is a thin pointer naming the skill and the
§7 contract, and the report's shape has never been stated there.

### Discovered Insights

- **Insight**: the attribution walk is called **conditionally**, on `red` only, which is what
  keeps this reading at one network call on the overwhelmingly common path.
  **Context**: `attribute-base-red.sh` reads the tip itself before deciding whether to walk, so
  calling it unconditionally would be correct but would double the cost of every green tick. The
  reader answers the question the report needs; the walk answers the question only a red base
  raises.

- **Insight**: §7's token table now carries a row for a reading that **never** moves the token.
  **Context**: every other row states a condition and its token. This one exists precisely because
  the absence of a row reads as an oversight — the table is the contract a caller-side loop waits
  on, and a later reader finding a reported reading with no row would reasonably add one.
