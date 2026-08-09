---
created_at: 2026-08-09T02:58:34+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260809025755-proposal-pr-descriptions-should-summarize-artifacts-by-count-not-list-full-file-paths.md]
merge_policy:
---

# Summarize proposal PR Artifacts section by count instead of listing full file paths

## Overview

<!-- PROPOSED. What this ticket would implement and why, from the feedback and
     repository state the proposal grew from. Merging the pull request this was
     published on is what turns it from a proposal into queued work. -->

`branching/scripts/publish-tree-pr.sh`'s `## Artifacts` section currently lists every
touched file as a full-path bullet (`git show --stat --oneline --name-only --format=''`
piped straight into the body). For a proposal pull request this reads as noise rather
than signal: a reviewer wants to know roughly what shape the change is (how many
feedback records, missions, tickets were added or touched), not the literal path of
each one. Replace the enumerated file-path listing with a concise counts summary —
e.g. "3 feedbacks added, 1 mission added, 2 tickets added" — derived from the same
`git show --stat --oneline --name-only` output, classified by which `.workaholic/`
artifact area each path falls under (added vs. modified, per the diff's own status
column).

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

<!-- The files this ticket would touch, each with why it is relevant. -->

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — owns the `## Artifacts` section this ticket replaces
- `plugins/workaholic/skills/branching/SKILL.md` — documents the publish-tree PR body shape; update alongside the script
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests over `branching/scripts`; extend to cover the new summary shape

## Implementation Steps

<!-- The ordered steps. A proposal is judged on these, so they are the point. -->

1. In `publish-tree-pr.sh`, replace the raw `git show --stat --oneline --name-only --format=''` bullet list with a small counts tally: use `git show --stat --oneline --name-status --format=''` (or equivalent) to get each changed path with its status (added/modified/deleted), classify each path by its top-level `.workaholic/` artifact area (`feedbacks`, `missions`, `tickets`, other), and render one line per (area, status) combination present, e.g. `- 3 feedbacks added`, `- 1 mission added`, `- 2 tickets added`.
2. Keep a fallback for paths outside `.workaholic/` (e.g. plugin source touched by a non-proposal publish) — group them as a generic `N files changed` line rather than dropping them silently.
3. Update `branching/SKILL.md`'s description of the publish-tree PR body to describe the counts summary instead of the file-path listing.
4. Extend `scripts/test-workflow-scripts.mjs`'s `publish-tree-pr.sh` coverage to assert the `## Artifacts` section renders counts, not full paths, for a multi-artifact publish.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A proposal pull request's `## Artifacts` section shows counts per artifact area and status (e.g. "3 feedbacks added, 1 mission added, 2 tickets added") instead of an enumerated list of full file paths.
- A publish that touches files outside `.workaholic/` still reports something (no silent drop), summarized rather than enumerated.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic test asserting the rendered `## Artifacts` body for a multi-artifact publish tree
- Manual: run `/propose` against a real feedback item and inspect the opened pull request's body

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green
- `node scripts/build-plugins/verify.mjs` green (the workflow skill ships into `outputs/workflows`, so its bundle stays self-contained)

## Considerations

<!-- Risks and open questions the proposal already sees. -->

- `publish-tree-pr.sh` is shared by every publish-tree writer (`/ticket`, `/mission`, `/propose`, ship-time concern extraction), not just the propose pipeline — the counts summary should read sensibly for all of them, not only a proposal's feedback+mission+ticket shape.
- Deleted/renamed paths (e.g. `archive.sh` renaming a driven ticket) need a status bucket too, or an explicit decision to fold them into "modified".
