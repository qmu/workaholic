---
created_at: 2026-08-26T02:23:47+00:00
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
