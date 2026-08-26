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

# Answer superseded for a mission claim

## Overview

PROPOSED. Ticket 4 of 8, and the behaviour change the mission exists for. Remove the
early-`false` in `claims_superseded` that puts every non-ticket artifact out of scope, and
let ticket 2's reader supply the verdict for a mission unit.

The existing ticket-archive test stays as the **local, network-free** path for batch units,
so an offline batch verdict is byte-identical to today's. The row keeps `resumable: false`,
stays `reported, never acted on`, and keeps not forbidding `ok` — a claim holding no work
is the opposite of outstanding work.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_superseded`: the
  `case "$_csp_p" in .workaholic/tickets/*) ;; *) ... printf 'false'; return 0` branch is
  what this ticket removes, and its comment is what this ticket rewrites.
- `plugins/workaholic/skills/drive/scripts/lib/claim-merged.sh` — ticket 2's reader.
- `plugins/workaholic/skills/drive/reference/claims.md` — the protocol's full record.
- `scripts/test-workflow-scripts.mjs` — ticket 1's fixture, whose mission-grain assertion
  flips here.

## Implementation Steps

1. Re-read `claims_superseded` and the fixture from ticket 1. The early-`false` and its
   comment are a deliberate, documented ruling; replacing them means replacing the reason,
   not just the code.
2. Remove the early-`false` for non-ticket paths and route a mission unit to ticket 2's
   reader for its verdict.
3. Keep the ticket-archive test exactly as-is for batch units, and keep it **first**: a
   batch verdict must still be reachable with no network, and must be byte-identical to
   today's.
4. Flip ticket 1's mission-grain assertion to the new expected answer, leaving the batch
   assertion untouched — that untouched assertion is the proof nothing regressed.
5. Keep `resumable: false`, keep the row reported and never acted on, and keep it from
   forbidding `ok`.
6. Update the header comment and `drive/reference/claims.md` with the reversal and the
   evidence that reversed it — three merged mission claims measured 2026-08-26.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A squash-merged mission claim reads `superseded`, `resumable: false`.
- An offline batch verdict is byte-identical to today's.
- Nothing deletes a branch, closes a pull request or releases a claim, and `superseded`
  still does not forbid `ok`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — ticket 1's fixture, both grains.
- `bash plugins/workaholic/skills/drive/scripts/list-claims.sh` on this repository names
  the three measured units.

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.
- The batch path is proved unchanged offline.

## Considerations

- The batch path stays local and the mission path becomes networked, so the two grains
  now degrade differently. Ticket 3 is what makes that safe; state the difference in the
  header rather than leaving it to be discovered.
- Diff-containment was refused when `superseded` shipped, because the measured recovery
  landed refined rather than verbatim. Do not reintroduce it here.

## Final Report

Development completed as planned, and the mission-grain answer has changed. `claims_superseded`'s
early-`false` for a non-ticket artifact is gone; a mission claim now routes to
`claims_merged_state`, which asks whether a merged pull request has this branch as its head.

**The reason was replaced, not just the code.** The early-`false` said the equivalent would need
a second parser of the many-valued `mission:` relation "for a shape nothing has measured". Both
halves are answered: the shape was measured (three of five claims here headed pull requests
#521, #537 and #546, all merged, all mission units, one offered `resumable: true` five days
after its own merged), and the relation still has exactly one parser, because the lookup reads
**no artifact at all**.

**The local test stays first and stays network-free.** The loop reaches the lookup only on an
artifact that is not a ticket, so a batch verdict is byte-identical to what it has always been —
and the fixture proves that rather than asserting it: its origin is a local directory, so no
lookup can succeed there, and the batch assertion is untouched from ticket 1.

**Ticket 1's mission-grain assertions flipped as designed**, and the fixture now covers both
sides: with no reachable lookup the row keeps its local verdict and the branch is named in
`merged_lookup_unanswered`; with a stubbed transport answering `merged`, the mission claim reads
`superseded`, `resumable: false`. The batch claim is asserted to need no lookup at all.

**Everything the row promised is unchanged**: `resumable: false`, reported and never acted on,
and it still does not forbid `ok` — a claim holding no work is the opposite of outstanding work.

**One defect found and fixed while proving this.** `claims_fetch` sets `CLAIMS_FETCH_OK`, and
every caller invokes it as `fetched=$(claims_fetch)` — a command substitution, so the assignment
happened in a subshell and never reached the parent. The lookup therefore read `offline` on
every run and was skipped unconditionally, which is exactly why the first run of the stubbed
assertion still reported `heartbeat_lapsed`. The flag is now assigned by the caller between its
two calls, and the library's header says why that is the only form that works.

### Discovered Insights

- **Insight**: In this library the subshell boundary is the design constraint, not a detail.
  `claims_fetch` and `claims_scan` are both consumed through command substitution, so nothing
  either sets can travel outward — which is why the fetch flag is set by the caller and the
  unanswered set goes to a file rather than a variable.
  **Context**: Anything added to this library that needs to communicate sideways has exactly
  three options: the TSV row (whose field count is load-bearing), a file the caller names, or a
  variable the caller sets before the call. A fourth does not exist, and reaching for one is how
  the fetch flag silently disabled the whole lookup.
- **Insight**: A gate that fails closed can look identical to a gate that is working. The
  stubbed-transport assertion is what exposed the flag defect; the offline assertions all passed
  throughout, because "skipped" and "answered not_merged" produce the same verdict.
  **Context**: For any skip-when-degraded mechanism, the test that matters is the one where the
  mechanism is supposed to *fire*. Asserting only the degraded path proves the fallback, never
  the feature.
