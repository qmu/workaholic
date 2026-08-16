---
created_at: 2026-08-14T10:30:51+00:00
status: done
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

## Final Report

Development completed, with one design correction the reproduction forced. Step 1
confirmed the gap: archiving `todo/colleague-example-com/…-a.md` landed it in
`archive/<branch>/` with no `assignees:` stamped and left its sibling under the per-user
directory. Step 8's check resolved in the header's favour — `create-ticket/SKILL.md:58`
does instruct the publish step to run the migration, and `promote-icebox.sh` calls it, so
`archive.sh` was the only named seam that did not; the header now also names
`converge-layout.sh` as the manual seam and records when this one was wired.

**The correction.** Step 3 placed the call after the `mv`, which is where it was first
written. That failed eight assertions across three existing tests, and the failures were
not fixture noise: a unit's queue is listed **once** and driven ticket by ticket, so the
first archive of a legacy queue flattens every path the run still holds, and each later
`archive.sh` call died on `Ticket not found`. In `testResumeSkipsDrainedUnit` that left
the second ticket queued, so a drained unit read as `heartbeat_lapsed`-resumable and the
survey re-offered a claimed ticket — the 2026-08-04 double-pick class of failure.

The seam therefore runs the migration **before** the move and re-resolves a legacy path
whose ticket the migration just flattened. Both halves are load-bearing: running before
the move stamps the ticket being archived (precisely the file whose ownership the
measured failure lost), and the path tolerance keeps a half-driven unit from stranding on
a path that was correct when it was read. The tolerance is lexical, tried only when the
named path is absent, and a genuinely missing ticket still fails at the same check.

### Discovered Insights

- **Insight**: Wiring a tree-wide migration into a per-file seam changes paths that other
  in-flight machinery holds — and the claim protocol is one of those holders.
  **Context**: Two unrelated existing tests (`testResumeSkipsDrainedUnit`,
  `testTicketCommitsDerivation`) failed for the same reason, and the cheap reading was
  "legacy-layout fixtures, update them". They were reporting a real hazard instead: any
  caller holding a list of queue paths across an archive. The suite earned its keep here —
  the defect would have shipped as a plausible three-line addition.

- **Insight**: The `Ticket not found` recovery the subject gate was built to prevent had a
  second entrance nobody had closed.
  **Context**: `archive.sh`'s header documents that exact failure — a refused subject left
  the ticket already moved, and recovery took the hand-written `git mv` the workflow
  forbids. A migration running at the same seam re-opens it from the other side, so the
  tolerance is the same rule applied to the same recovery rather than a convenience.

- **Insight**: `TICKETS_ROOT` was already derived from the ticket's own path, so the
  scoping step 4 asked for needed no new derivation.
  **Context**: The `sed` that strips `/todo/<user>` or `/todo` from the ticket's directory
  predates this change and answers exactly the question `missions_root_from_artifact`
  answers for missions. Reaching for a second root derivation would have added a way for
  the two to disagree inside one script.
