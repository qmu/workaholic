---
created_at: 2026-09-03T05:37:13+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: emit-a-mission-only-when-there-is-a-mid-term-plan-to-hold
merge_policy:
verification_handoff: 
---

# Update the documents to the container scale

## Overview

The grain is described in `CLAUDE.md`, `README.md`, three skills and two command ceilings. A
change to what a mission is that leaves any of them saying the old thing is a defect here, not a
follow-up — this repository's own rule is that the documents move in the same change.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `CLAUDE.md` — *The ticket spine*, the mission floor and ceiling paragraph.
- `README.md` — the workflow overview.
- `plugins/workaholic/rules/workaholic.md` — the rule's home from the sibling ticket.
- `plugins/workaholic/skills/mission/SKILL.md` and `reference/schema.md` — the artifact's model.
- `plugins/workaholic/skills/{propose,specificate}/SKILL.md` and the two command ceilings.

## Implementation Steps

1. Update each document to the container statement, citing `rules/workaholic.md` rather than
   restating it — the repository's own convention for a rule with a story.
2. Say in `CLAUDE.md` what changed and what did not: rule 1 is a mechanical floor at every seam,
   rule 2 is a stated judgement, and no cap was added to the ingest path.
3. Record the measurement that produced the change (94 missions, the distribution, the seven
   missions in twenty-one minutes) where the rule is stated, so the next reader can argue with
   the evidence rather than the wording.
4. Regenerate `outputs/` with `node scripts/build-plugins/build.mjs` and verify.
5. Run `node scripts/test-workflow-scripts.mjs` and the byte-identical ceiling pins.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- No document describes the mission grain as a ticket count to hit.
- The rule is stated once and cited everywhere else.
- `outputs/` is regenerated and `Outputs Freshness` would pass.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Every surface named in Key Files is updated in this change.

## Considerations

- The temptation is to restate the rule in each document because each reads well alone. This
  repository has recorded twice that a restated rule drifts; the citation is the point.
