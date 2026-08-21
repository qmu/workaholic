---
created_at: 2026-08-21T15:15:50+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: refuse-a-commit-that-splits-a-rename
merge_policy:
verification_handoff: 
---

# Refuse a commit that splits a rename

## Overview

PROPOSED. `commit.sh`'s default staging runs `git add -u`, which stages tracked
modifications and deletions and leaves untracked files out. A convergent migration writes its
additions untracked and deletes the originals, so default staging takes exactly half of it.
The result merged: 50 concern records lost their content on `main`, and a story body written
the same run was dropped while its index entry landed.

`commit.sh` already **warns** about untracked files. The warning fired and the commit went
through, because a warning's enforcement is a human reading it. This ticket makes the
split-rename shape a refusal.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/commit/scripts/commit.sh` — the staging step (`git add -u`) and the untracked-file warning beside it.
- `plugins/workaholic/skills/feedback/scripts/migrate-concerns.sh` — the migration whose "stages nothing" contract is half-protective; its header states why it stages nothing.
- `plugins/workaholic/skills/drive/scripts/archive.sh` — another `commit.sh` caller, so a new refusal reaches it too.
- `scripts/test-workflow-scripts.mjs` — pins `commit.sh`'s behaviour.


## Implementation Steps

1. Reproduce the shape in a throwaway repository before changing anything: write a rename as
   an untracked addition plus a tracked deletion, call `commit.sh` with default staging, and
   confirm a deletion-only commit is produced. The fix must fire on that state and on no other.
2. Resolve Open Decision 1 — refuse in `commit.sh`, or stop the migration staging its deletion
   half. The two put the guarantee in different places and only one should be built.
3. Implement the chosen mechanism. If it is the refusal: detect a staged deletion co-existing
   with an untracked addition and **refuse**, in the style of the off-policy-subject refusal,
   leaving the tree byte-identical.
4. Make the message name the actual repair — which files to pass as `files...`, or which
   migration to complete — rather than restating the rule.
5. Cover it in `test-workflow-scripts.mjs`: the split shape refuses; an ordinary commit with
   unrelated untracked files still succeeds, since that is the common case and must not break.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A commit whose staged set is a deletion whose counterpart is untracked is refused.
- The refusal leaves the tree byte-identical and names the concrete repair.
- An ordinary commit alongside unrelated untracked files still succeeds.

**Verification method** — the commands/tests/probes that prove them:

- Reproduce the split shape in a throwaway repository and assert the refusal.
- Assert the ordinary case is unaffected.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- Open Decision 1 is resolved explicitly in the driving session's Final Report.
- The reproduction from step 1 is recorded before the fix is written.


## Considerations

- Untracked files are routine and harmless on their own. A refusal keyed on untracked-files
  alone would fire constantly and be disabled within a day; the co-existence with a staged
  deletion is what makes the signal specific, and the reproduction is what proves it is.
- `migrate-concerns.sh`'s "the index is the caller's shared state" contract is sound and was
  measured (a read that staged its writes once enlarged a two-file commit to 154). Do not
  reverse it casually — Open Decision 1 is exactly the question of whether option (2) can be
  had without paying that cost again.

## Open Decisions

1. **Refuse in `commit.sh`, or leave the deletions unstaged in the migration?** The report
   offers both and picks neither. (1) `commit.sh` refuses when a staged deletion co-exists with
   an untracked addition: one place, catches every migration including ones not yet written,
   and risks a false positive on a legitimate delete-here-add-there commit. (2)
   `migrate-concerns.sh` leaves its deletion half unstaged so both halves can only move
   together: precise and local, but it is one migration's fix and every future migration must
   remember it — and it edges against the "never touch the caller's index" contract that script
   holds for a measured reason. Resolve in the Final Report; do not build both.

