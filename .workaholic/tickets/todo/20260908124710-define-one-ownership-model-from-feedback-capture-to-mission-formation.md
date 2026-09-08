---
created_at: 2026-09-08T12:47:10+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: restore-the-mission-as-the-planning-merge-story-and-release-boundary
merge_policy:
verification_handoff: 
---

# Define one ownership model from feedback capture to mission formation

## Overview

Redesign ingestion ownership so capture records an ask without making `/specificate` treat it as settled, and one seam alone decides mission formation, deduplication, and closure.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — inbound sweep ownership and role dispatch.
- `plugins/workaholic/skills/moderate/` — findings that currently write feedback records.
- `plugins/workaholic/skills/specificate/` — discovery exclusion and capture/specification seam.
- `plugins/workaholic/skills/feedback/` — immutable record state and issue references.

## Implementation Steps

1. Reproduce the observed collision where moderation records #1086/#1087/#1089 on `main` before `/specificate`, causing `already_captured` exclusion while the issues remain unplanned.
2. Model capture, accepted-for-judgment, planned, and settled as distinct derived facts without mutating feedback records.
3. Assign one writer and one reader to each transition and remove competing capture ownership from routine roles.
4. Test overlapping ticks, pre-existing records, open issues, unmerged proposal branches, and crash recovery.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A record can exist without falsely proving that its ask was specified or settled.
- Concurrent roles cannot capture the same issue into conflicting workflow states.

**Verification method** — the commands/tests/probes that prove them:

- Run end-to-end intake fixtures reproducing the #1086/#1087/#1089 collision and recovery.

**Gate** — what must pass before approval:

- Every issue has one explainable state and one next owner after any interruption.

## Considerations

Immutable feedback records stay intact; repair must change derived workflow ownership rather than delete or rewrite history.
