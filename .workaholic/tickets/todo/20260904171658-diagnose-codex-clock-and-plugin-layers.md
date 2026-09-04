---
created_at: 2026-09-04T17:16:58+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-codex-work-entrypoint-self-contained
merge_policy:
verification_handoff: 
---

# Diagnose Codex clock and plugin layers

## Overview

Make the work entrypoint verify the skill, command body, and external clock independently so a
missing wrapper never becomes a false plugin-reinstallation diagnosis.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — recovery names the failed layer directly

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — supported entrypoint and diagnostic contract.
- `scripts/codex-loop.sh` — launcher preflight and refusal vocabulary.
- `scripts/test-workflow-scripts.mjs` — layer-specific diagnostic fixtures.

## Implementation Steps

1. Define separate readings for skill, command body, and clock wrapper availability.
2. Emit `clock_wrapper_missing` when only the external clock is absent.
3. Recommend reinstall or update only when a plugin-owned artifact is actually absent.
4. Cover every missing-layer combination hermetically.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Each absent layer has one precise condition and a truthful recovery path.

**Verification method** — the commands/tests/probes that prove them:

- Run preflight fixtures over complete and selectively incomplete installations.

**Gate** — what must pass before approval:

- A missing repository wrapper never diagnoses the installed plugin as stale.

## Considerations

Keep the diagnostic vocabulary aligned between the shell launcher and skill prose.
