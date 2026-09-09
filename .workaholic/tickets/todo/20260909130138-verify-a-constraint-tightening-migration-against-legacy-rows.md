---
created_at: 2026-09-09T13:01:38+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-a-native-tick-from-reconciled-evidence-not-from-a-worker-s-word
merge_policy:
verification_handoff: 
---

# Verify a constraint-tightening migration against legacy rows

## Overview

PROPOSED. A stricter `CHECK` constraint passed local tests against an **empty** database and then
failed the existing-row copy in a production rebuild migration; the deployment failure was
reported as a healthy completion. The operator asks that this finding be carried into Workaholic's
implementation and operation verification guidance: when a change tightens a constraint over
persisted data, the evidence required is the upgrade path exercised against representative legacy
rows, not fresh schema creation.

Domain-specific data conversion belongs to the consuming application. What Workaholic owns is that
the evidence is **requested** at ticket-writing time and that the delivery outcome is **observed**
rather than assumed.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/implementation/policies/persistence.md` — where a persisted-data
  constraint change is governed.
- `plugins/workaholic/skills/implementation/policies/test.md` — what evidence a change must
  produce.
- `plugins/workaholic/skills/operation/policies/ci-cd.md` — the delivery path's own verification.
- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — the Quality Gate a ticket
  writes, where the legacy-row requirement must be asked for.
- `plugins/workaholic/skills/ship/SKILL.md` — the deployment plan and confirmation seam, where a
  failed run must stay visible.

## Implementation Steps

1. **Localize before writing guidance.** Read the three policy pages and the ticket format and
   record exactly what each says today about persisted data and about upgrade paths, so the change
   is an addition to a named gap rather than a restatement.
2. Add to the persistence and test policies the one rule the finding establishes: a change that
   **tightens** a constraint over persisted data is verified by exercising the upgrade path against
   representative legacy rows; a fresh-schema pass is not evidence.
3. Make the ticket format ask for it: when a ticket's change tightens a persisted-data constraint,
   its Verification method names the legacy fixture and the upgrade run.
4. Confirm — in `ship`'s own words — that a failed or pending deployment stays a separate visible
   state and can never be rendered as a healthy completion. Do not add a new gate; state the rule
   where the confirmation is already read.
5. Update `CLAUDE.md` and any affected `plugins/workaholic/rules/*.md` in the same change, as the
   documentation rule requires.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The persistence and test policies state the legacy-row requirement for a constraint-tightening
  change over persisted data.
- The ticket format asks for the legacy fixture and the upgrade run in the Verification method.
- A failed or pending deployment stays its own visible state and is never reported as healthy.
- The affected documents are updated in the same change.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the generated
  bundle carries the revised policy text.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- This is guidance, not a machine gate. Workaholic cannot inspect a consuming application's
  fixtures, and inventing a cross-repository check would be scope nobody asked for.
- Keep it to the rule the finding establishes. Do not generalize into a wider migration framework.
