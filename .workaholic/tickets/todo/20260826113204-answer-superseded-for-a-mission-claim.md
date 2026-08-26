---
created_at: 2026-08-26T11:32:04+00:00
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
