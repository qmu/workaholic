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

## Final Report

Development completed as planned. `tickets/` is two-state, the seven parked tickets carry their state in frontmatter, and all three enforcement surfaces plus every reader moved with the tree.

### Open Decisions — resolved

- **Where does a ticket with no branch land? → `archive/unbranched/`, a single synthetic bucket.** The archive is keyed by *the branch that drove a ticket*; an abandoned or iceboxed one was never driven, so naming the branch of the commit that parked it would assert a drive that never happened — and a reader joining archive directories to branches would find one that never carried the work. The flat archive root was the other candidate and breaks the `archive/*/` shape every reader globs (`scan-window.sh`, `ticket-commits.sh`, `report`'s counters). One named bucket keeps the shape and states exactly what is true: archived, never driven.
- **What is the field called, and what is its vocabulary? → `status:`, over `done | abandoned | icebox`, absent means queued.** `status:` rather than a new word because a reader already knows it from missions and release records, and sharing `abandoned` across artifacts is worth more than a private vocabulary. **Absent means queued** is the same shape as an empty `assignees` meaning team-owned and an absent `merge_policy` meaning review — a ticket gains the field at the moment it stops being queued, and `promote-icebox.sh` *removes* it on the way back. Tickets keep carrying **no `type:`** (the OKF exception is untouched); `status:` is the one new axis.
- **Does the icebox survive as a state? → Yes, and folding it into `abandoned` would have been a quiet loss.** They are different decisions: iceboxed is **deferred and promotable**, abandoned is **decided against**. The distinction is load-bearing — `promote-icebox.sh` exists to bring one back, and the drive skill is explicit that the icebox is developer-curated in both directions and the run never touches it. Collapsing them would convert every deferral into a rejection with no one deciding to.

### The migration, run here

`migrated: 7` — six from `abandoned/`, one from `icebox/`. Second run: `migrated: 0`, working tree byte-identical. `.workaholic/tickets/` now holds `README.md`, `todo/` and `archive/`. Each moved file gained exactly one line (`status:` after `created_at:`); the body is byte-identical, which the suite pins by comparing everything past the frontmatter fence.

### Discovered Insights

- **Insight**: The enforcement surface was the risk, exactly as the ticket predicted — and the answer was to make every layer *tolerate* the old shape rather than switch to the new one.
  **Context**: `validate-ticket.sh` still accepts `icebox/` and `abandoned/`, `guard-ticket-structure.sh` still permits a move out of them, `list-icebox.sh` reads both the field and the directory, and `scan-window.sh` still scans all four. A layer that switched cleanly would hard-block a consuming repository whose plugin updated before its tree — turning a convergent migration into a gate, which is the class of failure this change exists to remove. The same reasoning that keeps `todo/<user>/` readable indefinitely applies unchanged.
- **Insight**: Filtering the queue on the **field** rather than on the directory is not redundancy, it is the actual invariant.
  **Context**: Nothing writes an end state into `todo/` — the archive seam moves the file in the same act — so filtering by directory would be correct today. But a ticket mid-migration, or one a human stamps by hand, would then be offered as claimable work carrying `status: abandoned`. `list-todo.sh` now reads the field, and the suite pins it with a ticket deliberately stamped while sitting in `todo/`.
- **Insight**: `[ cond ] && printf` as the last statement of a `while` loop under `set -e` makes a healthy read exit 1.
  **Context**: `list-icebox.sh` failed its own smoke run that way — the final iteration's non-match became the loop's status, and the loop's status became the script's. An `if` is not stylistic here; every one of these list scripts is consumed by a caller that reads a non-zero exit as "the queue could not be read at all", which is the opposite of "the queue is empty".
