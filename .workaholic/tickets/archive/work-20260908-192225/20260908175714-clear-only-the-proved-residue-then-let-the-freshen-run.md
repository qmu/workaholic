---
created_at: 2026-09-08T17:57:14+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: clear-the-residue-the-base-already-holds-and-never-stop-silently
merge_policy:
verification_handoff: 
---

# Clear only the proved residue, then let the freshen run

## Overview

PROPOSED. With the residue classified, add the **act** the ask asks for: a layer above
`sync-main.sh` that clears only residue a proof covers, then lets the existing freshen run
unchanged. `sync-main.sh` is not loosened — the ask is explicit that its properties are correct, and
this ticket must leave it byte-identical.

Measured 2026-09-08: 21 ticks over ~100 minutes reporting `claimable_units_unreadable: not_current`,
`/implement` never reaching its survey, over 6 staged paths of which 4 were blob-identical to
`origin/main` and 2 were regenerable indexes. Clearing exactly those by hand made
`claimable-units.sh` answer `{"claimable":2,"missions":2}` in the same second.

The act inherits the repository's standing discipline for a bounded act on a proof
(`drive/reference/claims.md`, *When a bounded act may read a judgement*): re-derive the proof at the
moment of the act, be idempotent, write nothing on a refusal, and refuse each bound by its own word.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/clear-proved-residue.sh` — NEW. The one act.
- `plugins/workaholic/skills/branching/scripts/classify-residue.sh` — the previous ticket's reader,
  composed and never re-implemented.
- `plugins/workaholic/skills/branching/scripts/sync-main.sh` — read and re-run; **unmodified**.
- `plugins/workaholic/skills/drive/SKILL.md` — §1's freshen step, where the retry is wired.
- `plugins/workaholic/skills/drive/reference/survey.md` — the `dirty_workspace` row, which gains the
  retry and its refusals.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — run to restore a `regenerable` path
  rather than checking it out blind.
- `scripts/test-workflow-scripts.mjs`, `scripts/e2e/loop-drill.sh` — the hermetic suite and the drill
  set.

## Implementation Steps

1. **Reproduce the deadlock end to end before writing the act.** Build the tree from the previous
   ticket's step 1 and drive a full `/implement` freshen against it, recording the refusal chain and
   that no survey is reached. Keep that tree as the drill's fixture.
2. Write `clear-proved-residue.sh [base-branch]`. It calls `classify-residue.sh`, **re-derives every
   path's class itself immediately before touching it**, and then, per class:
   - `on_base` — `git restore --staged --worktree -- <path>` (or the equivalent checkout from the
     base), because the base already holds byte-identical content.
   - `regenerable` — restore to `HEAD` and re-run the repository's own generator, never a blind
     checkout of the base's copy.
   - `untracked` — **left alone, always.** The act deletes nothing it did not itself derive from a
     tracked object. The measured tree had zero untracked files, so this bound costs nothing
     measured and removes the one irreversible act available here.
   - `divergent` / `unanswerable` — untouched; the run refuses.
3. Make the refusals named and total, with nothing written on any of them: `divergent_residue`
   (naming each path), `unanswerable_residue` (naming each path and its reason), `untracked_present`
   when untracked paths remain after the clear and the caller asked for a clean tree, `not_on_main`,
   `no_origin`, `origin_unreachable`, `classify_unreadable`, `generator_failed`. Report
   `cleared: []` per path with the class that licensed it.
4. Make it idempotent: a second call on an already-clean tree answers `already_clean` and writes
   nothing.
5. Wire it into `/drive` §1: on `sync-main.sh` answering `dirty_workspace`, call this act **once**,
   and on `cleared` re-run `sync-main.sh` **once**. A still-refusing freshen terminates `pending`
   exactly as it does today, now naming what was cleared and what was refused. `/implement` inherits
   this through the same one code path; an attended `/drive` reports it identically.
6. Add hermetic rows for each refusal word, for the idempotent re-run, and for the wired retry
   reaching a survey; add the fixture from step 1 to `scripts/e2e/loop-drill.sh`.
7. Update `drive/SKILL.md`, `drive/reference/survey.md`, `branching/SKILL.md` and `CLAUDE.md` in the
   same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tree dirty only with `on_base` and `regenerable` paths is cleared, freshened and surveyed in one
  pass, with no prompt at any step.
- A tree carrying one `divergent` or `unanswerable` path is refused by that word, with the tree
  byte-identical afterwards.
- No untracked file is ever removed.
- `sync-main.sh` is byte-identical to its pre-change form.
- A second call on a clean tree writes nothing and answers `already_clean`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new rows above.
- `sh scripts/e2e/loop-drill.sh verify-all` — the step 1 fixture driven end to end.
- `git diff --stat` over `sync-main.sh` across the branch, expected empty.
- `git status --porcelain` before and after each refusal case, compared.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs`, the drill's hermetic part, `build.mjs` + `verify.mjs`
  clean, and `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming.

## Considerations

- **The act is bounded to tracked residue, and that bound is stated rather than assumed.** Deleting
  an untracked file is the one irreversible act available at this seam and no proof covers it: an
  untracked file is by definition on no ref. The measured tree had none, so the bound costs nothing
  that was measured. If a later ask wants untracked residue cleared, it is a separate decision with
  its own evidence.
- **Widening `sync-main.sh` instead was refused by the ask itself**, in those terms. Keeping the act
  above it also keeps the refusal contract intact for every other caller of that script, including
  the ones that run inside claim worktrees.
- **The retry is once, not a loop.** A freshen that still refuses after a successful clear is
  reporting something the proof does not cover, and retrying would turn a report into a spin.
- `regenerable` restoration runs a generator, which is the one place this act executes repository
  code. A failing generator is `generator_failed` and leaves the path alone rather than falling back
  to the base's copy — the fallback would be a guess wearing a proof's clothes.
- Risk: a path that is both `on_base` and generated. Classifying `on_base` first makes the stronger
  proof win, and the outcome is identical either way.

## Final Report

Development completed as planned. `sync-main.sh` is byte-identical to its pre-change form —
`git diff origin/main..HEAD -- .../sync-main.sh` is empty — and the whole judgement lives in the
layer above it, exactly as the ask required.

The end-to-end chain is proved twice, in the hermetic suite and in `scripts/e2e/loop-drill.sh`'s
new `verify-checkout-residue`: the measured tree refuses `dirty_workspace`, the act clears it,
the **existing** freshen fast-forwards, and the bytes the act discarded come back — which is what
makes "the base already holds it" a proof rather than a hope. The drill carries a real breaker:
a copy of the reader with the blob comparison removed discards a developer's edit, so the drill
fails on that copy and its passing verdict means something.

Two deliberate departures from the ticket's own wording, both narrowing:

- **`untracked_present` refuses up front rather than after the clear.** The ticket placed it
  after ("when untracked paths remain after the clear"). An untracked file keeps
  `check-workspace.sh` dirty however much else is cleared, so the end state is identical either
  way — and refusing first keeps the stronger invariant that a refusal leaves the tree
  byte-identical. `--allow-untracked` exists for a caller that does not need a clean tree.
- **`origin_unreachable` is not one of the act's words.** The reader never fetches (a fetch
  writes remote-tracking refs), so no call can reach that state; its neighbour `no_base_ref` is
  what an absent remote-tracking ref actually answers, and it is passed through verbatim.

### Discovered Insights

- **Insight**: `git restore --source=HEAD --staged --worktree` has nothing to restore from when
  `HEAD` does not carry the path — which is precisely the measured shape, a staged **add** of
  content the base already holds. That case needs `git rm --cached` plus removing the file.
  **Context**: The 2026-09-08 tree was four staged paths blob-identical to `origin/main`, and a
  restore-only implementation would have cleared the modifies and left every add behind, so the
  freshen would still have refused and the deadlock would have looked half-fixed.

- **Insight**: `regenerable` restoration is safe only because restoring to `HEAD` and re-running
  the generator against `HEAD`'s sources reproduces `HEAD`'s committed output — which holds
  because CI already fails on generated drift.
  **Context**: The generator is derived from which paths were restored (`refresh-index.sh` for a
  `.workaholic/` path, `build.mjs` otherwise), so a tree with no regenerable residue runs
  nothing. A generator that fails is `generator_failed` and the path is left where the restore
  put it — never filled in from the base's copy, which would be a guess wearing a proof's
  clothes.

- **Insight**: the per-path re-derivation is a `--path` flag on the reader rather than an inlined
  comparison in the act.
  **Context**: *Re-derive the proof at the moment of the act* and *one home for one rule* pull
  against each other unless the re-derivation goes back through the same reader. The flag costs
  one process per cleared path (the measured tree had six) and keeps the act with no copy of the
  proof in it at all.
