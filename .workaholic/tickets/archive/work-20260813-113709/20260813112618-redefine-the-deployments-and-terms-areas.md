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

## Final Report

Development completed as planned. Both areas now carry a definition that says what they hold, what they never hold, who writes them and when they are refreshed — and a seam that makes staleness visible instead of aspirational.

### Open Decisions — resolved

- **Which seam owns each area's upkeep? → A checking seam, not a writing one, and that is the recorded answer rather than a fallback.** The ticket allowed for it ("a seam that only warns leaves 'kept updated' to a human, which may be the honest answer — but it must be the recorded one"), and it is the honest answer for a specific reason in each area. A **deployment record describes a procedure a human authored**; a machine that rewrote it from a run would record what happened rather than what should happen, and the next `/ship` would gate on its own last behaviour instead of on an intention. A **glossary a machine maintained would define the words the machine already uses**, which is the opposite of what a glossary is for. So `/ship` stays the only live *reader* of a deployment record and never a writer, and the upkeep seam is `report/scripts/area-freshness.sh`, read by `/report` beside `doc-drift.sh` — facts, never verdicts, never an edit. It emits two mechanical facts per record: **`retired_terms`** (the record still names a de-listed `.workaholic/` area or a retired plugin namespace — that is not "possibly stale", it is wrong) and **`stale_days`** (reported for every record and thresholded by nobody, because the right interval differs per project and a number baked into the script would be a guess dressed as a rule).
- **Does a redefinition rewrite the existing records? → Frontmatter yes, prose no.** Conforming frontmatter is mechanical and lossless: `type: Deployment` on `marketplace.md`, `type: Term` on the five `terms/` records, satisfying the OKF floor without touching a sentence. Re-reading prose nobody has looked at since 2026-03-10 is a **content audit** — different work, different judgment, and doing it inside a definition ticket would have buried it. It is minted as `20260813125500-re-read-the-stale-terms-glossary-content.md` with the seam's own output as its evidence. `deployments/marketplace.md` needed nothing beyond `type:` — it already conforms to the format its README documents, which is what an area with a live reader looks like.

### The seam, run against this repository

`bash plugins/workaholic/skills/report/scripts/area-freshness.sh` → `flagged: 5, total: 6`. `deployments/marketplace.md` is clean (56 days, no retired names). All five `terms/` records are flagged: 156 days each, still defining `drivin`, `trippin`, `specs`, `guides`, `policies`. That is the required demo of the staleness report firing on a genuinely stale record — no fixture needed, the repository supplied one.

### Discovered Insights

- **Insight**: The two surviving areas were in opposite conditions, and the difference is entirely explained by whether anything reads them.
  **Context**: `deployments/` has one live reader (`/ship` gates on its `## Confirmation`), and its README was already a real definition with a worked example, its one record already conformant — 56 days old and correct. `terms/` has no reader, and five of its six records name things retired months ago. Same closed layout, same "hand-maintained" label, opposite outcomes. That is the same mechanism that retired `guides`/`policies`/`specs`, observed on a survivor: **a reader is what keeps a document honest**, and where there is no reader the seam has to supply the pressure.
- **Insight**: The retired-name check is a genuinely computable staleness signal, where "has this been edited recently" is not.
  **Context**: A record untouched for a year may be perfectly correct. A record that names `drivin` cannot be — that plugin does not exist. Checking for *names the project has retired* turns a soft heuristic into a fact, costs one word-bounded grep per record, and grows naturally: the script's `RETIRED` list is the vocabulary of "no longer exists here" and gains an entry whenever something else is retired. Word boundaries matter — `policies` had to not match "the pillar policy skills", `specs` had to not match "specification".
- **Insight**: The bound plugin's hooks are a *different* version from the scripts the run executes, and the difference is observable.
  **Context**: Minting this run's ticket was blocked by `validate-ticket.sh` demanding `todo/<user>/` — the pre-2026-08-06 layout, from the v1.0.133 binding — while the v1.0.176 validator in this checkout accepts the flat path with exit 0. The run resolved `src` to 1.0.176 at §1 and drives from it, so its scripts are current; the *hooks* stay whatever the harness registered. `workaholic:drive` §1 says exactly this ("hooks and the Skill/Command bindings stay whatever the harness bound"), and this is that sentence happening: the file was written, the guard's refusal was stale, and the current floor passes it.
