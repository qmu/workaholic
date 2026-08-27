---
created_at: 2026-08-27T20:21:18+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: ask-for-the-one-act-a-declared-handoff-is-waiting-on
merge_policy:
verification_handoff: 
---

# Read a claim's declared handoff and its pull request

## Overview

PROPOSED. `list-claims.sh` already carries `declared_handoff` on every row — but only as a
**boolean**. The question a person must be asked names the declared reason *in the words the
ticket wrote* ("an API token and account id must be added as repository secrets"), and that
string is nowhere on the row: `claims_declared_handoff` computes the boolean and discards the
value. This ticket resolves the reason, plus the pull request's coordinates, for an
`awaiting_verification` row — the reading the step in the next ticket consumes.

`drive/scripts/verification-handoff.sh` stays the **one reader** of `verification_handoff:`;
this composes it, never re-parses the field. The reason must be read off the work still
**queued** on the branch tip (not the archived work), exactly as the oracle reads it, so the
two answers cannot diverge and the reading releases itself when that ticket is driven.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a degraded read is named, never rendered as a calm one

## Key Files

- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the one reader of the
  field; its `reason` is the verbatim string the question needs. Compose it; never re-parse.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_declared_handoff` (line
  ~492) and `claims_remaining_tickets` (~426): where the still-queued set is already derived,
  and the reason the value is currently dropped.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the row shape
  (`declared_handoff`, `resume_reason`, `branch`, `author`); the candidate source.
- `plugins/workaholic/skills/drive/scripts/claim-merged.sh` — the claim protocol's one
  network read; three-valued, and `unanswerable` must leave coordinates unstated.
- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the precedent for
  the per-candidate lookup loop and for what an unanswerable read does.

## Implementation Steps

1. Reproduce first: run `list-claims.sh` against a fixture holding an `awaiting_verification`
   row and confirm the reason string appears nowhere in its output — the boolean is all there
   is. Record what is and is not on the row before changing anything.
2. Decide where the resolution lives and record the choice: extending `list-claims.sh`'s row
   with the reason, or resolving it per candidate in the consuming step. Prefer the second
   unless the first can be shown not to cost every reader of the oracle an extra tip read —
   `stalled-units`, `undelivered-units` and `retire-claims` all call `list-claims.sh` and none
   of them needs the string.
3. Resolve the reason for one candidate by handing the still-queued work at the branch tip to
   `verification-handoff.sh` (the mission's own `mission.md` included, since any member
   declaring it carries the unit) and taking its `reason`. Reuse the set
   `claims_remaining_tickets` derives; do not walk the tickets a second time.
4. Resolve the pull request's coordinates with **one** `claim-merged.sh` lookup per candidate.
   An `unanswerable` read leaves them unstated and **keeps** the candidate: the finding is that
   the unit is waiting on a person, which the oracle established offline.
5. Report every degradation by name — an unreadable tip, an absent member file, a reason that
   resolved empty — rather than emitting a candidate with a blank reason.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- For an `awaiting_verification` claim, the declared reason is available verbatim as the
  ticket wrote it
- `verification_handoff.sh` remains the only reader of the field; no second parser exists
- An unanswerable pull-request lookup leaves the coordinates unstated and drops no candidate
- The reading is offline apart from the one existing `claim-merged.sh` lookup per candidate

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `grep -rn "verification_handoff" plugins/workaholic/skills/ | grep -v verification-handoff.sh`
  — proves no second parser was added

**Gate** — what must pass before approval:

- The hermetic suite passes and nothing in the claim chain gained a network call

## Considerations

- The tempting shortcut is to put the reason on the claim row for everyone. That makes every
  caller of `list-claims.sh` pay a tip read for a string three of the four never use.
- The reason is free text quoted verbatim into `## Handoff`; it can contain quotes and
  newlines. Whatever carries it must survive that without mangling the person's own words.

## Final Report

Reproduced first: `list-claims.sh` over this repository's live claims carried
`declared_handoff: true` on `work-20260827-003544` and the declared string appeared nowhere in
its output — the boolean was all there was.

**Where the resolution lives, and the choice recorded.** Per candidate, in a new reader, not on
the claim row. `stalled-units`, `undelivered-units` and `retire-claims` all call `list-claims.sh`
and none of them wants the string, so putting it on the row would cost every reader of the oracle
a value three of the four never use. `drive/scripts/declared-handoff-detail.sh <branch>
[<artifact>...]` resolves it only for the rows a consumer will ask about.

**One materialisation, one parser.** `lib/claims.sh`'s `claims_declared_handoff` was split into
`claims_declared_reading` (materialise the still-queued blobs at the tip, hand them to
`verification-handoff.sh`) with `claims_declared_handoff` and the new `claims_declared_reason`
as thin reads of that one line. `verification-handoff.sh` remains the only reader of the field;
the reason is sliced out of the reader's own JSON between the two keys it always prints in order,
never by re-reading frontmatter. The reason is read off the work still **queued**
(`claims_remaining_tickets`, reused rather than re-walked), so it releases itself.

**Pull request:** one `claim-merged.sh` lookup per candidate; `unanswerable` leaves the
coordinates unstated and keeps the candidate. `--no-lookup` makes the reading fully offline.

**Degradations named:** `no_branch`, `no_branch_ref`, `no_artifacts`, `no_handoff_reader`,
`not_declared`, `reason_empty`, `no_merged_reader`, `merged_lookup_unreadable`.

Verified: `node scripts/test-workflow-scripts.mjs` — 4111 passed, 0 failed. `list-claims.sh`
output over the live claim set is unchanged. `grep -rn "verification_handoff"
plugins/workaholic/skills/ | grep -v verification-handoff.sh` returns comments, prose and
scaffolds only — no second parser. Live read of `work-20260827-003544` returns the declared
reason verbatim and PR #647.
