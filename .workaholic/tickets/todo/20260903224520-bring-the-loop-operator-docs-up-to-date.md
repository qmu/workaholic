---
created_at: 2026-09-03T22:45:20+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
---

# Bring the loop operator docs up to date

## Overview

Since commit `24c3f1245fb21101093017f4f32ad4b7c5aa7bd6`, the loop gained a `/work` orchestrator,
machine-load-aware allocation work, permission-prompt handling, and broader claim/publication
recovery. The executable contracts and generated workflow bundles changed, while nothing under
`docs/` changed with them. The operator runbooks therefore no longer describe the system an
unattended tick actually runs or the failure states an operator must diagnose.

This ticket reconciles the durable operator documentation with those shipped structural changes.
It records design history only where a new ruling belongs in the append-only decision log, and puts
current operating instructions in the runbook rather than treating the decision log as live docs.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — keep operator-facing behavior current and testable
- `workaholic:implementation` / `policies/observability.md` — document the readings and refusal words used to diagnose a tick
- `workaholic:development` / `policies/overnight-ai.md` — make unattended execution and its human handoffs explicit

## Key Files

- `docs/drive-loop-runbook.md` — current operator procedure and failure-mode reference
- `docs/loop-engineering-workflow.md` — append-only history for genuinely new design rulings
- `plugins/workaholic/commands/work.md` — current orchestration surface
- `plugins/workaholic/skills/work/SKILL.md` — one-tick sequencing and capability substitutions
- `plugins/workaholic/skills/drive/reference/claims.md` — current claim catch-up and publication recovery rules

## Implementation Steps

1. Compare the current `/work`, `/implement`, and claim contracts with the operator runbook and list
   every stale or absent operator-visible behavior introduced since the baseline commit.
2. Update `docs/drive-loop-runbook.md` to describe the one-tick orchestration boundary, allocation
   readings, permission-prompt refusal/handoff, and the current conflict/publication recovery path.
3. Keep status and reason vocabulary byte-identical to the executable contracts, while writing the
   surrounding operator guidance in plain language.
4. Append only genuinely new decisions to `docs/loop-engineering-workflow.md`; do not rewrite old
   rulings to make history look current.
5. Verify links, command names, and failure-reason ownership against the live plugin sources and the
   generated workflow bundle.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An operator can identify what one `/work` tick runs and where repetition is provided.
- The runbook explains how load/capability readings affect allocation without promising a decision
  the executable contract does not make.
- Permission-prompt and conflict outcomes name the actor and seam that can actually resolve them.
- The decision log remains append-only and current-behavior guidance lives in the runbook.

**Verification method** — the commands/tests/probes that prove them:

- Cross-check every changed statement against the owning command, skill, script, or claims reference.
- Run the repository's Markdown link check and render changed diagrams, if any.
- Run `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- No executable behavior changes in this documentation-only ticket.
- No retired command, namespace, or recovery promise is reintroduced.

## Considerations

The baseline includes generated copies under `outputs/workflows/`; those demonstrate distribution
drift but should not be documented separately. The canonical plugin source is the authority and the
generated bundle must remain derived from it.
