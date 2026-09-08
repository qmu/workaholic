---
created_at: 2026-09-08T12:47:10+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: restore-the-mission-as-the-planning-merge-story-and-release-boundary
merge_policy:
verification_handoff: 
---

# Version and deliver only at the completed mission boundary

## Overview

Move version allocation, release note creation, merge, deployment/delivery, and outward completion notification to the completed mission PR-unit rather than each captured feedback item.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/story/` — version and release note timing.
- `plugins/workaholic/skills/drive/` — merge boundary and completion routing.
- `plugins/workaholic/skills/ship/` — delivery of one mission-sized release.
- `plugins/workaholic/skills/notify/` — one human-facing completion per delivered unit.

## Implementation Steps

1. Trace every version bump, release note, merge, deploy, and finish notification triggered by feedback and ticket boundaries.
2. Key each effect to the completed mission unit and make duplicate or premature calls mechanically refuse.
3. Preserve feedback-level traceability in the story and release note without issuing one release per source.
4. Prove one related burst yields one version, one story, one merge, one delivery, and one completion announcement.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Related mission members never allocate separate plugin versions or release deliveries.
- The completed mission has one release note and one outward completion with all feedback refs traceable.

**Verification method** — the commands/tests/probes that prove them:

- Run end-to-end release fixtures counting versions, PRs, stories, deliveries, and notifications for a multi-feedback mission.

**Gate** — what must pass before approval:

- No effect can run before the mission acceptance set reaches its terminal unit outcome.

## Considerations

Do not conflate proposal publication with product release; only the mission's completed implementation unit is a release boundary.

## Final Report

Added `story/scripts/release-boundary.sh`, a pure reader that permits version allocation only when
the branch archives tickets belonging to exactly one mission and that mission is archived
`achieved`, fully checked and linked, with an empty queue. Story, drive and ship now consume that
verdict: ineligible proposal or loose-ticket PRs may merge normally but cannot bump a version,
draft a release note, enter ship/delivery, or claim release completion. Eligible mission branches
retain the existing collision re-bump immediately before merge.

### Discovered Insights

- A version check answers whether a number is free, not whether the branch deserves a release.
  Eligibility must be proved first from mission completion, then number allocation can run.

## Verify

The four-ticket completed-mission fixture returns one eligible boundary; changing the same mission
to active returns `mission_not_achieved`. Shell parsing, 6,830 workflow tests, bundle verification,
planning-input tests and metadata validation all passed.
