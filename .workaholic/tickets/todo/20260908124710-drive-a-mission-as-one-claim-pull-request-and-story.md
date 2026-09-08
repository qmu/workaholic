---
created_at: 2026-09-08T12:47:10+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: restore-the-mission-as-the-planning-merge-story-and-release-boundary
merge_policy:
verification_handoff: 
---

# Drive a mission as one claim, pull request, and story

## Overview

Carry a formed mission as exactly one executable unit from claim through implementation, review, and story, even when its tickets are small and independently buildable.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/` — mission partition, claim, execution, and merge route.
- `plugins/workaholic/skills/story/` — one branch narrative for the whole mission.
- `plugins/workaholic/skills/branching/` — one branch, worktree, and pull request per unit.

## Implementation Steps

1. Reproduce a mission whose members currently cause separate implementation or publication boundaries.
2. Assert one mission maps to one claim, branch, worktree, and pull request while preserving per-ticket completion evidence.
3. Generate one story whose outcome and concerns cover the full acceptance set.
4. Test partial failure, resume, mixed verification handoffs, and completion without splitting the release unit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A mission's tickets produce one implementation pull request and one story.
- Per-ticket evidence survives inside the unit without creating separate merge boundaries.

**Verification method** — the commands/tests/probes that prove them:

- Run drive and story fixtures over multi-ticket success, resume, and mixed-member routes.

**Gate** — what must pass before approval:

- The unit cannot report complete until mission acceptance is accounted for.

## Considerations

Mixed handoff members must not force executable members into separate releases; their one-PR semantics need an explicit coherent route.
