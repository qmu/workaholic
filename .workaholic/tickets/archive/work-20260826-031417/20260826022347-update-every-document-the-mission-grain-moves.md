---
created_at: 2026-08-26T02:23:47+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826022347-bound-the-brake-to-one-mission-per-strategy.md
mission: turn-the-loop-at-mission-granularity
merge_policy:
verification_handoff: 
---

# Update every document the mission grain moves

## Overview

The ask ends "ドキュメントのアップデートも忘れず" — update the documentation too. This
repository already treats outdated documentation as a defect and requires every affected
document to move in the same change, so each earlier ticket updates the skill it touches.
What this ticket owns is the **repository-level** surfaces no single ticket owns: the loop's
own description in `CLAUDE.md`, the runbooks under `docs/`, the routine templates' prompts,
and the drill that proves the chain. Left alone, those keep describing a loop that turns one
change at a time.

## Policies

- `workaholic:development` / `policies/change-history.md` — behaviour and its record move together
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `CLAUDE.md` — the `/propose` and `/specificate` rows, the ticket-spine section, and the
  `.workaholic/` attribution paragraph
- `README.md` and `.workaholic/README.md` — the loop as a reader first meets it
- `docs/loop-engineering-workflow.md`, `docs/proposal-loop-runbook.md`,
  `docs/drive-loop-runbook.md`, `docs/loop-drill-runbook.md` — the decision record and the
  operator procedures
- `plugins/workaholic/skills/workaholify/routines/propose.md` and `specificate.md` — the
  templates' prompts, pinned byte-identical against `notify/reference/notifications.md`
- `plugins/workaholic/rules/workaholic.md` — the artifact rules that mention the loop's grain
- `scripts/e2e/loop-drill.sh` — the end-to-end drill

## Implementation Steps

1. Rewrite the `/propose` and `/specificate` rows in `CLAUDE.md` to state the mission grain,
   the mission-shaped ask, and the re-expressed brake — stating **current behaviour only**,
   with the superseded reasoning answered rather than deleted, as that file's own convention
   requires.
2. Update the loop's description in `README.md` and `.workaholic/README.md`, and record the
   decision and the rejected forks in `docs/loop-engineering-workflow.md` and
   `docs/proposal-loop-runbook.md`.
3. Update the routine templates only where the prompt's named post formats or environment
   actually move. If nothing in a template's prompt changes, say so rather than touching it —
   the templates are pinned byte-identical by the test suite.
4. Extend `scripts/e2e/loop-drill.sh` so the mission-grain chain is drillable on demand:
   `verify-propose` and `verify-specificate` together prove a mission-shaped ask is proposed,
   ingested and emitted, with no network.
5. Run the full local verification and regenerate `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `CLAUDE.md`, both READMEs, the runbooks and `rules/workaholic.md` describe the mission grain
  and no document still describes the change grain as current
- The routine templates match `notify/reference/notifications.md` byte for byte
- The drill proves the mission-grain chain with no network
- `outputs/` is regenerated and clean

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose && sh scripts/e2e/loop-drill.sh verify-specificate`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `git diff --exit-code outputs/`

**Gate** — what must pass before approval:

- Every command above passes and no document contradicts another

## Considerations

- This ticket is deliberately **last** and deliberately not a catch-all: each earlier ticket
  still updates the skill it changes in its own commit. What is collected here is only what no
  single skill owns.
- The per-commit changed-lines ceiling (500 additions) is a real constraint on a documentation
  sweep. Split by surface — `CLAUDE.md`, the READMEs, the runbooks, the drill — rather than
  taking one `override`-tier finding for the whole thing.

## Final Report

Development completed as planned, split by surface into four commits so the documentation sweep
does not take one `override`-tier finding for the whole thing:

- `CLAUDE.md` — the `/propose` and `/specificate` rows and the `.workaholic/` attribution
  paragraph state the mission grain, the re-expressed brake, the named-plan rule and the inverse
  strategy read.
- `README.md` and `.workaholic/README.md` — the loop as a reader first meets it.
- `docs/loop-engineering-workflow.md` (a **fourteenth round**, S1–S6, recording the ruling and
  every rejected fork), `docs/proposal-loop-runbook.md` (§4's form step) and
  `docs/loop-drill-runbook.md` (§5g and five new row entries).
- `plugins/workaholic/rules/workaholic.md` — the strategy↔mission link is derived, never stored.

Two surfaces were checked and deliberately **not** touched, which is what the ticket asked for
rather than a silent omission:

- **The routine templates.** `workaholify/routines/propose.md` and `specificate.md` name post
  formats and an environment; `/propose` posts nothing and neither template's prompt shape or
  environment moved, and the templates are pinned byte-identical against
  `notify/reference/notifications.md` by the suite. Touching them would have been churn.
- **`docs/drive-loop-runbook.md`** — it does not mention `/propose` at all, and the drive loop's
  mechanics did not move.

`scripts/e2e/loop-drill.sh` was extended in the two earlier tickets of this mission
(`verify-propose` gained the mission-shape floor, the two-ticket floor, the refusal's
alternative, the drained-queue gate and its release — 15 load-bearing rows, all passing, no
network). The chain's second half, `verify-specificate`, requires a seeded issue number and a
live loop, so *the mission-grain chain end to end* is drillable only with a seed; the runbook now
says so in §5g rather than implying otherwise.

R4 of the thirteenth round was **answered in place rather than rewritten**: its `over_cap` and
"one proposal per strategy" clauses are superseded, and the paragraph now says so and points at
S5, as that document's convention requires.

### Discovered Insights

- **Insight**: One prose reference expanded the generated bundle by ~40,000 lines.
  **Context**: Naming `${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/mission-strategy.sh` in
  `mission/reference/command-flows.md` pulled strategy's whole transitive script closure — and
  through it drive, ship, story, specificate, check-deps and system-safety — into the `mission`
  and `catch` bundles. The build is correct (a portable bundle must be self-contained) and
  idempotent, but a reference in a reference document is not a cheap edit here.
- **Insight**: A superseded decision row is answered in place, not deleted.
  **Context**: `docs/loop-engineering-workflow.md` is a record of rulings, so R4 keeps its own
  words and gains a parenthetical naming what moved and where. Deleting it would erase the
  reasoning the new round is arguing with.
