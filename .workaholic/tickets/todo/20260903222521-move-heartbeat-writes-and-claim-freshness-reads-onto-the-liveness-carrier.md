---
created_at: 2026-09-03T22:25:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: carry-claim-liveness-off-the-review-branch
merge_policy:
verification_handoff:
---

# Move heartbeat writes and claim freshness reads onto the liveness carrier

## Overview

Move the heartbeat write off the work branch and make the claim oracle read the selected carrier
through one derivation. Keep ordinary work commits as progress evidence without copying heartbeat
commits into the branch a reviewer opens.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — concurrent runners must keep one claim owner

## Key Files

- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` — advances liveness without committing on the work branch.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — one freshness derivation for every consumer.
- `plugins/workaholic/skills/drive/scripts/claim.sh` — initializes and contends for the carrier.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — reports carrier readability and verdicts.
- `plugins/workaholic/skills/drive/reference/ticket-workflow.md` — retains the bounded beat step.

## Implementation Steps

1. Implement the carrier reader in `lib/claims.sh`, including readable, absent-legacy, and degraded
   states; do not let an unreadable carrier become a stale one.
2. Change `heartbeat.sh` to advance only that carrier from the unit worktree and preserve its
   never-load-bearing JSON/refusal contract.
3. Initialize or contend for the carrier when a fresh claim or same-identity resume succeeds, using
   the same push race that already arbitrates ownership.
4. Route `list-claims.sh`, `claim.sh resume`, and every freshness consumer through the one reader;
   remove direct timestamp assumptions outside it.
5. Prove fresh, lapsed, foreign, offline, and concurrent-update cases for both new and legacy claims.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Repeated beats leave the work branch SHA and commit count unchanged.
- Freshness, ownership, and takeover verdicts remain identical for equivalent claim timelines.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- No consumer independently parses the liveness carrier or treats a failed read as expiry.

## Considerations

- Updating a separate ref must not force-push or rewrite a colleague's signal.
- Preserve the merge-in-progress safety even though the heartbeat no longer commits the worktree.

## Final Report

Development completed as planned.

### Discovered Insights

- **Unreadable carrier state must outrank the numeric timeout**: a declared carrier whose namespace
  cannot be refreshed reports `liveness_unreadable` and remains `claim_active`.
  **Context**: Even a zero-minute test window must not turn absence of a remote reading into
  permission to take over.
- **Compatibility is positive, not guessed**: fetched carrier data wins, a legacy claim with no
  carrier uses its branch tip, and ordinary commits after a beat use their own timestamp.
  **Context**: New and old claims therefore pass through the same verdict chain.
