---
created_at: 2026-09-03T05:37:12+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: emit-a-mission-only-when-there-is-a-mid-term-plan-to-hold
merge_policy:
verification_handoff: 
---

# Name the missions already below the floor

## Overview

The floor is forward-only: a mission already on disk below two tickets stays there, and today
nothing names it. The corpus measured 94 missions with one at a single ticket. The loop must not
rewrite that history — which mission survives and whether it is closed, merged or extended is
the operator's ruling — but it must stop being invisible.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/hooks/layout-doctor.sh` — the read-only audit, and the precedent for an
  **advisory** that never fails the merge gate (the duplicate-slug pair).
- `plugins/workaholic/skills/mission/scripts/queue-size.sh` and `progress.sh` — the readers that
  already count a mission's tickets.
- `plugins/workaholic/skills/mission/scripts/check-floor.sh` — the one derivation of the number.

## Implementation Steps

1. Add an audit reading over `missions/active/` and `missions/archive/` that names each mission
   whose ticket count is below `check-floor.sh`'s floor, composing the existing counters rather
   than walking frontmatter again.
2. Report it as an **advisory** in `layout-doctor.sh`, never a finding: an under-floored mission
   harms nothing until somebody tries to act on it, and failing the merge gate over history is
   the shape this repository already refused for the duplicate-slug pair.
3. Delete nothing, close nothing, merge nothing and choose nothing. The reading says which
   missions are below the floor and stops.
4. An unreadable mission is named as unreadable, never counted as conforming and never omitted.
5. Add a hermetic case covering a below-floor mission, a conforming one, and an unreadable one.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- `layout-doctor.sh` names each below-floor mission as an advisory and leaves `conforming` alone.
- An unreadable mission is named as unreadable.
- Nothing is written, moved, closed or deleted by the reading.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/hooks/layout-doctor.sh .` against this repository.
- `node scripts/test-workflow-scripts.mjs` with the three hermetic cases.

**Gate** — what must pass before approval:

- The advisory does not affect the `Validate Plugins` merge gate.

## Considerations

- Which copy of a below-floor mission survives — closing it, folding it into another, or
  extending it — asserts intent, and this repository's rule is that only the operator does that.
