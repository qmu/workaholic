---
created_at: 2026-08-14T10:30:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-the-runner-from-taking-path-owned-legacy-tickets
merge_policy:
verification_handoff: 
---

# Converge the todo layout at the archive seam

## Overview

PROPOSED. `gather/scripts/migrate-todo-owners.sh` names its own call sites in its
header — "create-ticket's publish step, promote-icebox.sh, and drive's
archive.sh" — and in the current tree only `promote-icebox.sh` actually calls it.
`workaholify/scripts/converge-layout.sh` calls it too, but that is a command a
human types, not a seam an active queue passes through. `archive.sh` runs
`missions_migrate_layout` and nothing else, and it runs even that only inside the
`MISSION_SLUGS` branch — so an un-missioned ticket triggers no migration at all.

The consequence measured overnight 2026-08-13→14: tickets moved straight from
`todo/<another-user-slug>/…` into `archive/` without ever being stamped. A queue
that predates P2 never converges through ordinary use, which is what makes the
sibling ticket's tolerance tier permanent rather than transitional. Wire the
migration into the seam its own header already claims.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` — the seam to wire; note
  `missions_root_from_artifact` at ~line 182, the pattern for deriving a root
  from the ticket rather than from the process cwd.
- `plugins/workaholic/skills/gather/scripts/migrate-todo-owners.sh` — the
  migration; its header is the contract this ticket makes true.
- `plugins/workaholic/skills/drive/scripts/promote-icebox.sh` — the one existing
  call site and the boundary pattern to copy (`>/dev/null 2>&1 || true`).
- `plugins/workaholic/skills/create-ticket/SKILL.md` — the publish step the header
  also names; confirm whether it invokes the script or only describes it.
- `plugins/workaholic/skills/workaholify/scripts/converge-layout.sh` — the manual
  seam; must stay idempotent alongside the new automatic one.
- `scripts/test-workflow-scripts.mjs` — hermetic archive coverage.

## Implementation Steps

1. **Reproduce and localize first.** In a throwaway repository, seed a ticket at
   `todo/<slug>/X.md` and archive it through `archive.sh`; confirm it lands in
   `archive/<branch>/` with no `assignees:` stamped and the sibling tickets still
   sitting under `todo/<slug>/`. Measure it — do not infer it from this ticket.
2. Read `migrate-todo-owners.sh`'s header before wiring it: it is idempotent, it
   never overwrites a non-empty `assignees`, it git-stages both paths, and it
   deliberately does NOT run in `plan-units.sh` (side-effect-free, runs inside
   claim worktrees). Nothing here may weaken any of those.
3. Call it from `archive.sh` **outside** the `MISSION_SLUGS` branch, so an
   un-missioned ticket converges too, and **before** the `git add -A`, so the
   moves ride the archive commit already being made.
4. Scope the tickets root to the **archived ticket's own tree**, the same way
   `missions_root_from_artifact` derives the mission root — `archive.sh` runs in
   a claim worktree, and defaulting to the process cwd would migrate the wrong
   tree. Pass the derived root as the script's positional argument.
5. Keep the failure boundary the seam already uses: a migration problem must not
   strand an archive. Non-blocking, but report the outcome rather than discarding
   it — the same rule the OKF index refresh and the mission roll follow here.
6. Verify the archive-time move is byte-identical to what `converge-layout.sh`
   produces for the same input, so the manual and automatic seams cannot drift.
7. Add hermetic cases to `scripts/test-workflow-scripts.mjs`: archiving an
   un-missioned legacy ticket converges the queue; archiving in a repo with no
   legacy directories changes nothing; a second archive is a no-op.
8. If step 1 confirms `create-ticket`'s publish step only describes the call
   rather than making it, either wire it or correct the migration's header — the
   header must not claim a seam that does not exist.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Archiving any ticket — missioned or not — converges the tree's `todo/<slug>/`
  directories into flat `todo/` with `assignees:` stamped, in the archive commit.
- The migration is scoped to the archived ticket's own tree, not the process cwd.
- A repository with no legacy directories archives byte-identically to today, and
  a second archive migrates nothing.
- A failing migration reports itself and does not strand the archive.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new hermetic archive cases).
- Manual replay of step 1's reproduction against the patched seam.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green, and the migration's header
  agrees with its actual call sites after the change.

## Considerations

- **Order matters against the sibling ticket.** The tolerance tier resolves a
  path-owned ticket to its owner; this migration stamps the field and removes the
  path. They must agree on the same owner for the same ticket, or a ticket could
  change hands mid-convergence. The migration already derives the owner from
  `author:` when its slug matches the directory, and the bare slug otherwise —
  the new tier should resolve to the same slug for the same input.
- Archiving is a **write seam inside a claim worktree**, so this migration will
  now run under `/implement`. Moves are git-staged, which is why they must be
  emitted before `git add -A` and not after.
- `plan-units.sh` stays side-effect-free. Do not "fix" convergence by migrating
  in the survey; that is the boundary the migration's header already refuses.
