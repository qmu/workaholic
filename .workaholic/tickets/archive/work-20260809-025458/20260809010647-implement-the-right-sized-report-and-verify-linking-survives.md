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

## Final Report

Applied the companion ticket's scale-gate design to `/report`'s Phase 2:

- `plugins/workaholic/skills/report/reference/orchestration.md` — Phase 2 now branches on `archived_tickets` count from Phase 0's `git-context.sh`: **≤2** spawns one combined `general-purpose` opus worker (release-readiness + review-sections + Overview/Highlights/Motivation, no Journey); **>2** keeps the original 3-worker parallel fan-out with Journey, unchanged. Updated the Worker Output Mapping table and the Overview Generation detail intro to name both callers of fields 1-3.
- `plugins/workaholic/skills/report/reference/story-structure.md` — the Changes section template now marks the mermaid Journey fence as full-path-only (omitted outright on the lite path, straight to the per-ticket subsections); the per-section line-budget table's Journey row notes the same.
- `plugins/workaholic/skills/report/SKILL.md` — Phase 2 summary bullet states the scale gate and points to the reference for detail.
- `CLAUDE.md` — `/report` row now states the right-sizing and what stays identical on both paths.
- Regenerated `outputs/workflows/` (`node scripts/build-plugins/build.mjs`) so the report/catch/mission/ship bundle picks up the source edits.

**Result record preserved**: Phase 3 (per-ticket Changes section from archived tickets + `ticket-commits.sh`) and Phase 4 (the story-file commit) are untouched by the Phase 2 split — neither path skips or reshapes them.

**Cross-document relations preserved**: frontmatter `tickets:`/`mission:` (Phase 3), the stories index update (Phase 3), the mission changelog/acceptance roll (Phase 4), and the PR body's commit links (Phase 5's unchanged PR-creator worker) all run identically regardless of which Phase 2 path fired.

### Verification

- `node scripts/build-plugins/build.mjs` — regenerated `outputs/workflows` and `hooks/policy-index.md` cleanly.
- `node scripts/build-plugins/verify.mjs` — all built skills self-contained, policy index in sync, OKF bundle fresh (no manual doc-drift introduced).
- `node scripts/build-plugins/validate-metadata.mjs` — Codex manifests valid and version-aligned.
- `node scripts/test-workflow-scripts.mjs` — 2441 assertions passed, 0 failed (hermetic smoke suite unaffected — this change touches only markdown skill content, no scripts).
- `bash plugins/workaholic/hooks/layout-doctor.sh .` — `conforming: true`.
- This ticket and its companion were themselves driven by `/implement` as a 2-ticket mission unit and reported by this very `/report` run once the branch reaches the Report step — the lite path (2 archived tickets) is its own first live exercise.

### Discovered Insights

- **Insight**: The disproportionate cost was never the branch-safety scan or doc-drift check (both script-only, already cheap) — it was three LLM subagent spawns plus mermaid-flowchart synthesis for a change that, at single-ticket granularity, the ticket file's own Overview and Final Report already describe adequately.
  **Context**: Future right-sizing work on this loop should look for the same pattern — a fixed multi-subagent fan-out sized for the old Story-batch granularity — rather than assuming every per-run cost scales with content size.
