---
created_at: 2026-08-13T11:26:18+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260813112618-redefine-the-deployments-and-terms-areas.md
mission: revive-strategy-and-reshape-the-workaholic-artifact-set
merge_policy:
---

# Fold abandoned and icebox tickets into the archive

## Overview

PROPOSED. Issue #436 asks that `tickets/` become a two-state tree — `todo/` and `archive/` — with the abandoned and icebox states moved into the archive and tracked in YAML frontmatter instead of by directory. This is the same move `assignees` made in 2026-08-06 (P2: "ownership is a field, not a directory") applied to ticket state: a location that encodes a state cannot be read without a path parse, and every reader, guard and audit has to know the vocabulary.

The base state is small and the migration is therefore cheap: `.workaholic/tickets/` currently holds `abandoned/` (6 tickets), `icebox/` (1) and `archive/` (752 across `archive/<branch>/` directories); `todo/` is empty and therefore absent. What is not cheap is the enforcement surface — `validate-ticket.sh` hard-codes the four permitted locations, `guard-ticket-structure.sh` blocks non-canonical moves, and `layout-doctor.sh` reports "misplaced ticket states" against the same vocabulary. All three must change with the tree, and a consuming repository must converge without its next ticket write being blocked.

## Policies

- `workaholic:planning` / `policies/modeling-centric-design.md` — state the model (state is a field; the archive is a place) before moving a file
- `workaholic:design` / `policies/history-structures.md` — archived tickets are history; a migration relabels, never rewrites their content
- `workaholic:implementation` / `policies/directory-structure.md` — the ticket tree's shape is enforced in three places that must not drift
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` for the living migration, idempotent and `git mv`-aware

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` — the location floor; its error message enumerates `todo/<user>/`, `icebox/`, `abandoned/`, `archive/<branch>/` and must become the two-state vocabulary (note it currently also predates the flat `todo/`, so re-read it against the shipped layout before editing).
- `plugins/workaholic/hooks/guard-ticket-structure.sh` — blocks non-canonical ticket moves; the migration's own moves must be permitted, and the retired states blocked afterwards.
- `plugins/workaholic/hooks/layout-doctor.sh` — reports misplaced ticket states with suggested `git mv`s; its suggestions become the migration's target.
- `plugins/workaholic/rules/workaholic.md` — the `tickets/` table row and the paragraph describing the flat queue, the icebox and the archive.
- `plugins/workaholic/skills/drive/scripts/list-todo.sh` and `plan-units.sh` — the survey readers; a ticket carrying an end state must never be offered as claimable work.
- `plugins/workaholic/skills/drive/scripts/archive.sh` — the writer that moves a driven ticket into `archive/<branch>/`; it now also stamps the state.
- `plugins/workaholic/skills/catch/` and `report/` scripts — readers that count archived tickets and must not double-count the folded ones.
- A new living migration (sibling to `gather/scripts/migrate-todo-owners.sh`) invoked at the same seam, so any repository converges on its next touch.
- `.workaholic/tickets/abandoned/` (6 files) and `.workaholic/tickets/icebox/` (1 file) in this repository.

## Implementation Steps

1. Decide the frontmatter axis (field name and vocabulary — see Open Decisions) and write it into the rules table before moving anything.
2. Implement the living migration: for each ticket under `abandoned/` and `icebox/`, stamp the state into frontmatter and `git mv` it into the archive; idempotent, and a no-op in a repository that has neither directory.
3. Run it in this repository; the two directories disappear in the same commit that changes the enforcement surface.
4. Update `validate-ticket.sh`, `guard-ticket-structure.sh` and `layout-doctor.sh` to the two-state vocabulary, in lockstep with the rules table.
5. Update the readers: `list-todo.sh`/`plan-units.sh` exclude a ticket carrying an end state; `archive.sh` stamps one; the catch/report counters stay honest.
6. Add hermetic cases: a repo with both legacy directories, a repo with neither, and a second run proving idempotence.
7. Argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **Where in `archive/` does a ticket with no branch land?** The archive is keyed by branch (`archive/<branch>/`), and an abandoned or iceboxed ticket was never driven, so it has none. A synthetic bucket (`archive/abandoned/`), the flat archive root, or the branch of the commit that abandoned it are all defensible and imply different readers.
- **What is the field called and what is its vocabulary?** Tickets deliberately carry no `type:` (the OKF exception), so a `status:` field is new surface; `archived | abandoned | icebox` versus reusing the mission lifecycle's words changes what a reader can share between artifacts.
- **Does the icebox survive as a state at all**, or does an iceboxed ticket become an abandoned one? The ask folds the directory but does not say whether the distinction is worth keeping.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- `.workaholic/tickets/` holds only `todo/` and `archive/`; the 7 former abandoned/icebox tickets are in the archive with their state in frontmatter and their content byte-identical.
- `validate-ticket.sh`, `guard-ticket-structure.sh`, `layout-doctor.sh` and the rules table all state the two-state vocabulary, in one commit.
- `plan-units.sh` never offers a ticket carrying an end state; the catch/report counts are unchanged by the migration.
- The migration is idempotent and a no-op in a repository without the legacy directories.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with the three migration cases.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming.
- `git log --follow` on one migrated ticket showing the move, and a diff proving the body is unchanged.

**Gate** — what must pass before approval:

- Suite, build/verify and layout-doctor green, plus a demo: the migration run twice with the second run a no-op, and a survey that does not offer the folded tickets.

## Considerations

- 752 archived tickets already exist; the migration must not rewrite or re-index them, only the 7 that move.
- The enforcement surface is the risk, not the file moves: a repository whose plugin updates before its tree migrates will have its next ticket write blocked by the new floor. That is what the `/workaholify` step of this mission is for.
