---
created_at: 2026-08-27T16:20:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827162003-drill-the-base-reading-with-no-network.md
mission: read-whether-the-base-survived-what-the-loop-merged
merge_policy:
verification_handoff: 
---

# Write the base reading into the documents

## Overview

<!-- PROPOSED. -->

This repository's own rule: **update the docs in the same change**, and outdated
documentation is a defect rather than a backlog item. This mission adds a reader, a
walk, a `/moderate` step, a root event, a line in the driving run's report and a drill
verb — every one of which is described somewhere that must now say so.

The ticket exists as the mission's last unit because the documents can only be written
once the behaviour is settled. It is **not** a licence for the earlier tickets to skip
the documents they own: each of tickets 1–7 updates the skill it changes, and this one
carries the repository-level documents and reconciles the whole.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `CLAUDE.md` — the `/moderate` row (its **step count moves from nineteen to twenty**,
  and the new step is named beside its siblings), the `/implement` row (the base reading
  named, and that it **moves no token**), the loop-drill verb list, and the claim
  protocol's proofs-and-judgements paragraph.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step list, the step's contract,
  and the event rule.
- `plugins/workaholic/skills/drive/SKILL.md` — §7's run-report contract and the token
  statement.
- `plugins/workaholic/skills/drive/reference/claims.md` — the classification (ticket 6
  writes it; confirm it reads correctly against everything that shipped).
- `docs/loop-drill-runbook.md` — the drill verb, its procedure and its blame rows.
- `README.md`, `.workaholic/README.md`, `plugins/workaholic/rules/*.md` — check each; the
  repository's rule names them, and a change that touches none of them says so explicitly.

## Implementation Steps

1. Re-read what actually shipped in tickets 1–7 before writing a word. The documents
   describe **current behaviour only** — a document written from this ticket's plan
   rather than from the shipped code is the defect it exists to prevent.
2. Update `CLAUDE.md`'s `/moderate` row: the step count, the new step named where the
   recent ones are named, and what it asks, keyed on and addressed to.
3. Update `CLAUDE.md`'s `/implement` row: the base reading is named in the run report,
   and it **moves no token** — state the reason (a red base is not a fact about the unit
   this run drove) so a later reader does not read the omission as an oversight.
4. Add `verify-base-health` to `CLAUDE.md`'s loop-drill verb list and to the runbook.
5. Reconcile the proofs-and-judgements paragraph in `CLAUDE.md` with what ticket 6 wrote,
   so the two do not drift on the day they are written.
6. Run `bash plugins/workaholic/hooks/layout-doctor.sh .` and the build/verify chain —
   a documentation change that leaves `outputs/` stale fails CI's `Outputs Freshness`.
7. State plainly, in each place, what this reading does **not** do: it gates nothing, the
   merge is untouched, `/ship` is untouched, and quality stays gated at the `release/*`
   QA window. That sentence is the one a later reader most needs and most likely to lose.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `CLAUDE.md`'s `/moderate` step count reads twenty and names the new step
- `CLAUDE.md`'s `/implement` row names the reading and states that it moves no token
- the drill verb appears in `CLAUDE.md` and in `docs/loop-drill-runbook.md`
- every document describes what shipped, not what was planned
- each document states that the reading gates nothing

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `/story`'s `doc-drift.sh` reports no drift — the backstop, never the primary check

**Gate** — what must pass before approval:

- the full local verification chain passes
- no document names a behaviour that did not ship

## Considerations

- `doc-drift.sh` and `area-freshness.sh` are **backstops**. Do not treat a clean drift
  report as evidence the documents are right; they check mechanical facts, not accuracy.
- `CLAUDE.md` states current behaviour only. Reasoning belongs in the skill's header, the
  reference document or this mission's story — resist writing the decision history there.
- If any earlier ticket shipped without its own document update, fix it here and say so;
  do not silently absorb it.
