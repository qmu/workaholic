---
created_at: 2026-09-03T05:29:15+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread
merge_policy:
verification_handoff: 
---

# Pin the finish-line shape and update the documents

## Overview

The shape lives in two files and the bounds live in three; nothing mechanical stops them
drifting. This ticket pins what can be pinned and updates every document the change makes
untrue, in the same change — an outdated document is a defect here, not a follow-up.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite, where the byte-identical pinning of
  post shapes across the catalog and the command ceilings already lives.
- `plugins/workaholic/skills/notify/reference/notifications.md` and
  `plugins/workaholic/commands/infinite-development.md` — the two copies.
- `CLAUDE.md`, `README.md`, `plugins/workaholic/skills/loops/SKILL.md` — the documents that
  describe the tick.

## Implementation Steps

1. Extend the existing byte-identical post-shape assertion to cover the new finish line across
   the catalog and `commands/infinite-development.md`.
2. Assert the reader emits no unclassified outcome word, following the pattern the claim
   vocabularies already use.
3. Update `skills/loops/SKILL.md` to state the announce step as part of the tick's Slack turn.
4. Update `CLAUDE.md`'s *Loops* section and `README.md` so the tick's described behaviour matches
   what it does.
5. Regenerate `outputs/` with `node scripts/build-plugins/build.mjs` and verify with
   `verify.mjs`, since a workflow skill's script closure changed.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- The suite fails when the two copies of the shape diverge by one byte.
- `CLAUDE.md`, `README.md` and `skills/loops/SKILL.md` describe the announce step.
- `outputs/` is regenerated and `Outputs Freshness` would pass.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No document left describing the tick as it was before this mission.

## Considerations

- The pinning reaches the shape and not the behaviour; whether a run actually posts is checkable
  by nothing, and this repository already says so about the Japanese rule.
