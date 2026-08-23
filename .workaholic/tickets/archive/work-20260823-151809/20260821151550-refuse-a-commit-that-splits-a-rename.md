---
created_at: 2026-08-21T15:15:50+09:00
status: done
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


## Final Report

### The reproduction, recorded before the fix (step 1)

In a throwaway repository, with `old/x.md` tracked: write `new/y.md` **untracked** and `rm
old/x.md`, leaving `git status --porcelain` at ` D old/x.md` + `?? new/`. `commit.sh` with default
staging then produced a **deletion-only commit** — the warning about untracked files printed, and
the commit went through. That is the shape, and the fix fires on it and on no other.

(The first attempt at the reproduction used `git mv`, which stages **both** halves and commits
correctly — recorded because it is the easy way to convince yourself the defect is not there.)

### Open Decision 1, ruled: refuse in `commit.sh`

**(2) — leave the deletions unstaged in `migrate-concerns.sh` — is refused.** It is precise and
local, and it is *one migration's* fix that every future migration must remember; a rule that must
be re-remembered per writer is exactly what this repository keeps replacing with one gate. It also
edges against that script's measured *never touch the caller's index* contract (a read that staged
its writes once enlarged a two-file commit to 154), and paying that cost again to fix one caller is
the wrong trade.

**(1) is taken**: `commit.sh` refuses when a staged deletion co-exists with an untracked file under
default staging. One place, and it catches every migration including the ones not yet written.

**The false positive is real and has a one-step, explicit escape.** A legitimate
delete-here-add-there commit is refused too, and the repair is to name the files — which is the
caller stating its set rather than inheriting it. That is the outcome the guard wants in *both*
cases, so the "false" positive still ends somewhere better than the silent half-commit did. It
never fires when the caller already named `files...`, and never on untracked files alone: the
co-existence is the signal, and a guard that fired on routine untracked files would be disabled
within a day.

**No `git reset`.** The working tree is untouched either way, and unstaging would discard whatever
the caller had staged *before* invoking the script — which this branch cannot distinguish from what
`git add -u` just added. Leaving the index as it stands is also more useful: `git status` shows the
caller exactly the halves the message names.

**The message names the repair, not the rule**: both halves listed, then three concrete lines — the
`commit.sh` invocation with both paths already filled in, the narrower one for an unrelated
untracked file, and "finish the migration" for an incomplete one.

Two defects were caught by running it rather than reading it: the repair line concatenated the
paths (`old/x.mdnew/y.md`) with no separator, and the test's own assertion read a rename-detected
`git show --name-only` as half a commit.

**Verification**: `node scripts/test-workflow-scripts.mjs` — 3408 passed, 0 failed, with four
cases: the split shape refused with nothing committed and the tree untouched; naming both halves
commits them; an ordinary edit beside an unrelated untracked file still commits and leaves it out;
a plain deletion with no untracked file commits. `build.mjs` + `verify.mjs` clean.
