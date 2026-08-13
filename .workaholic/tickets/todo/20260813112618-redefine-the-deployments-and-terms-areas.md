---
created_at: 2026-08-13T11:26:17+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260813112617-retire-the-policies-guides-and-specs-areas.md
mission: revive-strategy-and-reshape-the-workaholic-artifact-set
merge_policy:
---

# Redefine the deployments and terms areas

## Overview

PROPOSED. Issue #436 keeps `.workaholic/deployments` and `terms` but says they "need to be defined and kept updated" — the complement of the erasure in the sibling ticket: these two survive, and the price of surviving is a definition and an upkeep seam. Today both are registered in the closed layout with a one-line table description (`deployments/` — "Deployment/release procedures and their success-confirmation methods"; `terms/` — "Term definitions") and neither has a writer: `deployments/` holds `marketplace.md` plus its README and index, `terms/` holds six files including an `inconsistencies.md`, and nothing in the loop refreshes either. `/ship` reads a deployment's confirmation method when it exists, which is the only live consumer.

The work is therefore two definitions and two seams: what each area holds and does not hold, which command or hook writes and refreshes it, and what makes staleness visible the way `doc-drift.sh` does for the repository's documents.

## Policies

- `workaholic:planning` / `policies/terminology.md` — `terms/` is the vocabulary's home; its definition must say who arbitrates a term
- `workaholic:operation` / `policies/delivery.md` — `deployments/` describes real delivery paths and their confirmation, the evidence `/ship` gates on
- `workaholic:planning` / `policies/modeling-centric-design.md` — define the artifact before wiring a seam to it
- `workaholic:implementation` / `policies/objective-documentation.md` — a definition nobody can check is not a definition

## Key Files

- `plugins/workaholic/rules/workaholic.md` — the two table rows, expanded from a phrase into a definition (what the area holds, what it never holds, who writes it, when it is refreshed).
- `.workaholic/deployments/README.md` and `.workaholic/terms/README.md` — the in-repo statement a reader meets first; today they carry the old phrasing.
- `plugins/workaholic/skills/ship/` — the only live reader of a deployment record (confirmation method); the natural seam for keeping `deployments/` current at ship time.
- `plugins/workaholic/skills/report/scripts/doc-drift.sh` — the existing staleness backstop and the pattern for making an unmaintained area visible.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — both areas are OKF-indexed; a schema change must keep the indexes regenerable.
- `.workaholic/terms/inconsistencies.md` — a term ledger with no owner today; the definition must say whether it survives.
- `README.md`, `.workaholic/README.md`, `CLAUDE.md` — the docs sweep.

## Implementation Steps

1. Write the definition of `deployments/`: one record per delivery path, each naming its procedure and its success-confirmation method, with the frontmatter schema and the OKF `type:` stated.
2. Write the definition of `terms/`: what a term entry is, when a term is added, and what happens to `inconsistencies.md`.
3. Choose and wire the upkeep seam for each — the candidate for `deployments/` is `/ship` (it already reads the confirmation method), and for `terms/` a drift check at `/report` — so "kept updated" is mechanical rather than aspirational.
4. Make staleness visible: extend the drift backstop so an area whose records have not been touched while the behavior they describe changed is reported.
5. Update the rules table rows, both READMEs, and the OKF indexes in the same change.
6. Argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **Which seam owns each area's upkeep?** `/ship` is the obvious writer for `deployments/` but runs per unit, not per delivery path; `/report`'s drift check is a warning, not a writer. A seam that only warns leaves "kept updated" to a human, which may be the honest answer — but it must be the recorded one.
- **Does a redefinition rewrite the existing records?** `deployments/marketplace.md` and the six `terms/` files predate any schema; conforming them is a rewrite of content nobody has re-read, and leaving them is a documented exception.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- The rules table states, for each of the two areas, what it holds, who writes it, and when it is refreshed.
- Each area's `README.md` matches that statement, and its records carry the stated schema (or their exception is documented).
- A named seam refreshes or checks each area, and a stale record is reported by a command the loop already runs.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with a case for the new check.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming; OKF indexes regenerated.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` green with `outputs/` committed.

**Gate** — what must pass before approval:

- Suite, build/verify and layout-doctor green, plus a demo of the staleness report firing on a deliberately stale record.

## Considerations

- The failure mode to avoid is a definition with no seam: both areas already have one-line definitions and no writer, which is the state this ticket exists to leave.
- `deployments/` is the area `/ship` gates on. A schema change here must not make an existing confirmation method unreadable mid-flight.
