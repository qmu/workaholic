---
created_at: 2026-09-03T22:25:21+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: carry-claim-liveness-off-the-review-branch
merge_policy:
verification_handoff:
---

# Measure the claim liveness readers and choose the off-branch carrier

## Overview

Reproduce the current branch-tip heartbeat contract and locate every writer and freshness reader
before changing it. Choose a separate git ref as the carrier: unlike a local file it survives an
ephemeral runner, and unlike a git note it does not depend on an independently fetched notes
namespace. Define the compatibility rule for claims created before the cutover.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — liveness must remain visible to every runner

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — owns the shared claim and liveness model.
- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` — current empty-commit writer.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — derives freshness and resumption.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — exposes the derived verdict.
- `scripts/test-workflow-scripts.mjs` — hosts the hermetic claim fixtures.

## Implementation Steps

1. Reproduce a claim, beat it repeatedly, and record the work-branch commits and every reader that
   uses the branch tip as liveness; this failure report is diagnosis-first.
2. Compare a dedicated remote ref, git notes, and an untracked file against cross-run visibility,
   fetch behavior, atomic update, cleanup, and pull-request history; record the dedicated ref as
   the choice only if the measurements confirm those properties.
3. Specify one ref name, payload, freshness timestamp, and compatibility precedence. A legacy
   claim with no separate carrier continues to use its branch tip; a new carrier wins outright.
4. Add hermetic fixtures for new and legacy shapes before moving any writer or verdict.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The carrier decision names every consumer and is backed by a failing clean-history fixture.
- A legacy branch-tip claim keeps its current `resumable` and `resume_reason` answers.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The chosen carrier is remotely shared without becoming part of the pull-request branch.

## Considerations

- The carrier is operational state, not a new `.workaholic/` artifact or permanent work record.
- Do not change either stale-window default; this ticket relocates the signal, not its policy.

## Final Report

Development completed as planned.

### Discovered Insights

- **A dedicated ref is the smallest shared carrier**: `refs/workaholic/claim-liveness/<work-branch>`
  points at a versioned blob and supports compare-and-push without entering PR ancestry.
  **Context**: Git notes need a separately fetched namespace and local files disappear with an
  ephemeral runner; the dedicated ref uses the repository transport already required by claims.
- **The carrier must name the observed branch tip**: a later ordinary work commit remains valid
  progress evidence until the next explicit beat.
  **Context**: This preserves the old reader semantics without putting heartbeat commits back into
  review history.
