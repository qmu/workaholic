---
created_at: 2026-09-08T17:57:14+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: clear-the-residue-the-base-already-holds-and-never-stop-silently
merge_policy:
verification_handoff: 
---

# Classify checkout residue by proof, never by guess

## Overview

PROPOSED. The unattended loop stalls forever on residue it can prove the base already holds.
`branching/scripts/sync-main.sh` §2 refuses `dirty_workspace` on any unclean tree, which is correct
by its own stated rationale (*a reset would discard a developer's local commits*), and nothing above
it can tell residue that provably discards nothing from residue that does. This ticket adds the
**reading** and nothing else: one script that classifies each dirty path by proof. The act that uses
it is the next ticket, deliberately — a reader that also writes is a reader nobody can run to look.

The proof form is `superseded`'s, cited rather than re-invented (`drive/reference/claims.md`,
*Proofs and judgements*): a reading the tree established, which cannot become false when re-derived.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/classify-residue.sh` — NEW. The one reader. Pure
  read: no commit, no index write, no ref, no post.
- `plugins/workaholic/skills/branching/scripts/sync-main.sh` — read only, to compose its existing
  answers. **Not modified by this ticket**: the ask states its properties are correct.
- `plugins/workaholic/skills/branching/scripts/check-workspace.sh` — the existing cleanliness reader
  this composes rather than re-deriving.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — the generator whose outputs define the
  `regenerable` class; read to derive which paths it writes rather than hard-coding a list.
- `plugins/workaholic/skills/branching/SKILL.md` — the reader's contract.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite the new reader's rows join.

## Implementation Steps

1. **Reproduce and localize first** (`workaholic:discover`, *Diagnosis-First Rule*). In a throwaway
   repository, stage a path whose blob equals the base's, stage a regenerated index, and leave an
   untracked file; run `sync-main.sh` and record that it answers `dirty_workspace` for all three
   alike, then that `plan-units.sh` reports `current: false` and `claimable-units.sh`
   `readable: false, reason: not_current`. That chain — not the symptom — is what this mission
   repairs, and the reproduction is what proves the reader is placed correctly.
2. Write `classify-residue.sh [base-branch]`, emitting one JSON line:
   `{"ok": true, "base": "...", "paths": [{"path", "class", "reason"}], "counts": {...}}`.
3. Derive each path's class, letting **no** class be reached by inference:
   - `on_base` — the working-tree or staged blob is byte-identical to `<base>:<path>`, compared
     through `git hash-object` against `git rev-parse origin/<base>:<path>`. That equality is the
     whole proof; filenames, directories and timestamps enter it nowhere.
   - `regenerable` — the path is one the repository's own generator rewrites (`outputs/`, the OKF
     bundle indexes, `hooks/policy-index.md`), derived from the generators rather than listed by
     hand, and the base holds a version of it. Content is deliberately not compared: what this class
     asserts is that the file is restorable by running a command, which is a different proof.
   - `untracked` — its own class, always.
   - `divergent` — tracked, changed, and not equal to the base's blob. A developer's work.
   - `unanswerable` — any path where the comparison could not be made (no base blob, a fetch that
     did not run, an unreadable object, a submodule, a symlink). **An absence of a reading is never
     a proof**, so this class exists rather than collapsing into `on_base`.
4. Emit `counts` per class so a caller can decide without walking the array, and answer
   `readable: false` with a named reason when the walk could not complete — never an empty `paths`,
   which reads as a clean tree.
5. Add hermetic rows to `scripts/test-workflow-scripts.mjs` covering one path of each class, a tree
   with no origin, and a tree whose base ref is missing; assert the script writes nothing (index,
   worktree and refs byte-identical across the call).
6. Update `skills/branching/SKILL.md` and `CLAUDE.md` in the same change, per the repository's
   documentation rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every dirty path is classified into exactly one of `on_base`, `regenerable`, `untracked`,
  `divergent`, `unanswerable`, each with a reason.
- A comparison that could not be made answers `unanswerable`, never `on_base`.
- The script writes nothing: index, worktree and refs are byte-identical across a call.
- A walk that could not complete answers `readable: false` with a named reason and null counts.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new hermetic rows above.
- A manual run against the tree step 1 built, checking each class by hand.
- `git status --porcelain`, `git rev-parse HEAD` and `git for-each-ref` before and after a call,
  compared.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/build.mjs` and
  `node scripts/build-plugins/verify.mjs` clean, and `bash plugins/workaholic/hooks/layout-doctor.sh .`
  conforming.

## Considerations

- **The reporter's proposed mechanism is a hypothesis, not this ticket's design.** The ask names
  `git hash-object` against `git rev-parse origin/main:<path>`, and step 3 adopts it — but because
  step 1's reproduction confirms it, not because the report proposed it.
- **`regenerable` is the weaker of the two proofs and is kept separate for exactly that reason.**
  `on_base` is content equality; `regenerable` is *this file is derivable by a command in this
  repository*. One class holding both would let a generated file whose generator is broken read as
  proved.
- The reader is deliberately blind to *why* the residue exists. The measured case came from a
  hand-run `git reset`, but reading the reflog for provenance would be reading for a judgement, and
  the proof does not need one.
- Cost: one `git hash-object` per dirty path. The measured tree had six.
