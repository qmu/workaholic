---
created_at: 2026-09-08T12:44:19+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-acknowledgements-informative-without-becoming-notification-noise
merge_policy:
verification_handoff: 
---

# Group burst receipts while preserving per-message durable state

## Overview

Recognize a rapid related feedback burst, react to each source for durable state, and emit one compact acknowledgement mapping every subject to its issue.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — burst collection, relation judgment, and grouped receipt.
- `plugins/workaholic/skills/propose/` — inbound sweep dedup and per-message receipt state.
- `plugins/workaholic/skills/runtime/` — shared settlement state across overlapping ticks.

## Implementation Steps

1. Measure the existing sweep boundary and where each source message becomes durably filed and reacted to.
2. Define a bounded burst window and relatedness judgment whose uncertain case keeps receipts separate and informative.
3. Compose one short subject-to-issue list for a related burst while retaining per-message reaction and reference state.
4. Prove overlapping runs do not repeat the group or drop an item that arrived during composition.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Five related rapid asks do not produce five indistinguishable messages.
- Unrelated concurrent asks remain separately understandable.

**Verification method** — the commands/tests/probes that prove them:

- Run fixtures for one ask, one related burst, unrelated simultaneous asks, and overlap replay.

**Gate** — what must pass before approval:

- Every filed source has durable state even when visible acknowledgement is grouped.

## Considerations

The grouping threshold must be derived from the intake batch/window, not an arbitrary global delay that slows normal replies.
