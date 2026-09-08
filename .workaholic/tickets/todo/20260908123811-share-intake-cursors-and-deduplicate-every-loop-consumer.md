---
created_at: 2026-09-08T12:38:11+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
---

# Share intake cursors and deduplicate every loop consumer

## Overview

Give hourly, tick, and loop consumers one overlap-safe intake position and one durable processed-state model so the same Slack event is neither lost nor handled repeatedly.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/runtime/` — atomic shared loop state.
- `plugins/workaholic/skills/work/` — claim and settle inbound observations once.
- `plugins/workaholic/skills/propose/` — existing swept-reference dedup contract.

## Implementation Steps

1. Inventory current per-run cursors, overlap windows, reactions, and swept-reference ledgers.
2. Define identity as workspace, channel, message timestamp, and thread timestamp where applicable.
3. Persist received, in-progress, and settled state atomically across cadence owners.
4. Test crash replay, overlapping windows, and concurrent collectors.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Each Slack event is actionable once while overlap safely re-reads it.
- A failed run leaves enough durable state for the next run to retry.

**Verification method** — the commands/tests/probes that prove them:

- Run concurrency and crash-recovery fixtures over shared intake state.

**Gate** — what must pass before approval:

- No cadence-specific cursor can shadow or duplicate another consumer's work.

## Considerations

State must record delivery separately from interpretation so a reaction does not falsely mean the ask was fully handled.
