---
created_at: 2026-08-09T01:06:47+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260809010644-design-a-right-sized-report-for-single-ticket-per-pr-granularity.md
mission: right-size-report-to-single-ticket-per-pr-granularity
merge_policy:
---

# Implement the right-sized /report and verify linking survives

## Overview

Implements the design from the companion ticket
(`design-a-right-sized-report-for-single-ticket-per-pr-granularity`):
right-size `/report`'s unit of work and/or trim its per-run procedure to
match single-ticket-per-PR granularity, while keeping the result record
and the FB → Proposal → Implementation → Report relations intact. This
ticket does not re-decide the shape — it builds what the design ticket
specified and verifies the two preserved properties still hold afterward.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the delivered command must keep serving its callers (`/drive`'s route step, the `[Implement]` routine) without regressing their contract

## Key Files

- `plugins/workaholic/skills/report/` — the skill to right-size per the design ticket's output
- `plugins/workaholic/skills/review-sections/` — likely needs its section-generation scope adjusted alongside `/report`
- `plugins/workaholic/commands/report.md` — update if the entry-point contract changes
- `CLAUDE.md` (`/report` row, Development Workflow) — update in the same change per the "update the docs in the same change" rule
- `plugins/workaholic/rules/workaholic.md` — update if `/report`'s described scope changes

## Implementation Steps

1. Apply the design from the companion design ticket to `/report`'s skill and scripts.
2. Preserve the recording of results: confirm what `/report` currently persists about outcomes still gets written under the new shape.
3. Preserve cross-document relations: confirm the FB → Proposal → Implementation → Report chain (`feedback:`/`mission:` relations, the stories index, the PR body links) still resolves after the change.
4. Update `CLAUDE.md` and any other docs describing `/report`'s scope in the same change.
5. Run the repository's local verification commands (`node scripts/build-plugins/build.mjs` / `verify.mjs` if `/report`'s skill or its script closure changed) and the workflow smoke tests.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/report`'s per-run scope/output on a single-ticket branch is visibly lighter than before this change.
- A result record equivalent to what `/report` previously persisted is still written.
- The FB/Proposal/Ticket/Report relations are still navigable end to end after the change.
- Docs describing `/report`'s scope (`CLAUDE.md` and any touched skill docs) are updated in the same change.

**Verification method** — the commands/tests/probes that prove them:

- Run `/report` on a single-ticket branch and inspect the generated story/PR body against the design's stated shape.
- Follow the FB → Proposal → Implementation → Report chain manually for that run's artifacts and confirm every link resolves.
- `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs` if applicable.

**Gate** — what must pass before approval:

- All acceptance criteria above verified; no regression to result recording or cross-document traceability.

## Considerations

- Do not silently drop either preserved property in pursuit of a lighter run — the source feedback is explicit that both must survive.
- If the design ticket's output changes the shape of what `/report` records, make sure downstream readers of that record (e.g. `/catch`, mission changelog rolling) still work.
