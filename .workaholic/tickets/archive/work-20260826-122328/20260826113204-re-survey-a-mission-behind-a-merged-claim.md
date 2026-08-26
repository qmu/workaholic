---
created_at: 2026-08-26T11:32:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Re-survey a mission behind a merged claim

## Overview

PROPOSED. Ticket 6 of 8. A mission whose claim is `superseded` must stop excluding its
queued tickets, so `plan-units.sh` offers them again and a run can drive them on a fresh
claim. Measured: `make-workaholify-converge-the-account-s-routines` is still `active` at
2/3 acceptance with queued tickets behind it, all excluded behind a claim whose pull
request merged five days ago.

Report the re-surveyed unit **by name** in the run report, so a mission that came back is
never mistaken for one that was never claimed.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the exclusion logic and the
  `claimed_reported` / `claimed_superseded` reasons.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the verdict this reads.
- `plugins/workaholic/skills/drive/SKILL.md` — the survey's contract and the run report's
  shape.
- `scripts/test-workflow-scripts.mjs` — a fixture mission with queued tickets behind a
  superseded claim.

## Implementation Steps

1. Read `plan-units.sh`'s exclusion block whole, including the comment explaining
   `claimed_superseded` as the fifth reason. The distinction between excluding the *unit*
   and excluding its *queued tickets* is the thing to get right.
2. Stop excluding the queued tickets of a mission whose claim is `superseded` — the claim
   holds no work, so the tickets are ordinary backlog.
3. Keep the claim row itself reported as `superseded` and still not resumable: this ticket
   frees the tickets, it does not revive the branch.
4. Name the re-surveyed unit in the run report, distinctly from a never-claimed one.
5. Cover it: a mission with a superseded claim and two queued tickets is offered, with the
   report naming it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Queued tickets of a mission behind a superseded claim are offered again.
- The claim row stays `superseded` and `resumable: false`.
- The run report names the re-surveyed unit distinctly.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the fixture above.
- `bash plugins/workaholic/skills/drive/scripts/plan-units.sh` on this repository offers
  the measured mission's remaining tickets.

**Gate** — what must pass before approval:

- A mission behind a genuinely live claim is still excluded — the change must not free
  every claimed mission.

## Considerations

- Freeing the tickets while the old branch still exists means two branches could carry
  work for one mission. That is correct and already the protocol's shape: the superseded
  branch holds nothing, and a fresh claim is how the remaining tickets get driven.

## Final Report

Development completed as planned. A mission whose claim is `superseded` — and the tickets queued
behind it — are offered again, and the survey names what it stepped over.

**The distinction step 1 asks about is the whole change.** Excluding the *unit* is right for
every other claim reason; excluding its *queued tickets* is right for every reason except this
one, because `superseded` means the claim holds no work at all. `is_superseded` is the one
predicate, applied at both loops, and everything else still excludes: `claimed_active` is being
driven now, `claimed_by_other` is not this runner's, `claimed_reported` waits on a human,
`claimed_resumable` is taken over rather than re-claimed.

**`resurveyed[]` is its own field, not an exclusion reason.** `excluded[]` names what the survey
saw and *dropped*, so a freed unit reported there would say the opposite of what happened — the
same reasoning that put a repaired ticket's `mission_closed` on its offered row. Each entry is
`{kind, id, claim}` and carries the **dead claim branch**, so a unit that came back is never
mistaken for one that was never claimed.

**It frees the work; it does not revive the branch.** The claim row stays `superseded`,
`resumable: false`, `resumable[]` stays empty, and nothing deletes the branch or closes its pull
request. A run takes the freed tickets on a **fresh** claim — the only correct route, because
the old branch cannot land.

**Two existing assertions flipped, and they are the same measurement.** The test that shipped
with `superseded` asserted its tickets were excluded `claimed_superseded` and offered nowhere.
That was the defect this ticket names, so both now assert the opposite and the comment records
why. The guard that keeps this from freeing every claimed mission is asserted last, on a claim
made live again.

**Measured on this repository after the change**: `make-workaholify-converge-the-account-s-routines`
— `active` at 2/3 acceptance, behind a claim whose pull request merged five days ago — is
offered again and reported `resurveyed` with `work-20260819-113836` named as its dead claim.

### Discovered Insights

- **Insight**: The survey's claim bookkeeping was keyed by reason but not by branch, so naming
  the dead claim in the report needed one more parallel accumulator (`CLAIM_BRANCHES`) rather
  than a lookup.
  **Context**: The claim rows are consumed in a `while read` loop whose output is a set of
  newline-delimited tables; anything a later stage needs about a claim has to be recorded during
  that pass. Adding a table is cheap and local — re-parsing the scan later would give the survey
  a second reading of the same rows.
- **Insight**: A verdict added to a ladder needs a second decision nobody asks for — not only
  *what does the row say*, but *what does the survey do with the work behind it*. `superseded`
  shipped with the first answered and the second inherited from the reasons beside it, and the
  inherited answer was wrong.
  **Context**: The two questions are genuinely independent: `claimed_reported` and
  `claimed_superseded` agree that the unit is not resumable and disagree completely about
  whether its tickets are free. Any future claim verdict should be asked both questions
  explicitly.
