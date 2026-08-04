---
created_at: 2026-08-04T20:05:55+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission: make-the-feedback-loop-actually-propose
merge_policy:
---

# Move the proposal cursor to a shared pushed ref

## Overview

`.workaholic/proposal-cursor` is a git-ignored, runner-local file. The propose
routine runs in a fresh cloud container every time, so the cursor never exists
there: `cursor.sh read` bootstraps to `origin/main` HEAD, reports
`initialized: true`, and the command contract stops the run — every cloud tick,
forever. Two open stream concerns name exactly this
(`20260730101911`, `20260730110659`).

The repository is already this project's coordination medium (the claim
protocol reads claims from pushed branches). Store the cursor the same way: a
pushed ref on origin that any container can read, with push as the race
arbiter.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / delivery-path policies — an unattended batch must fail loudly on write and degrade readably on read, matching the claim scan's doctrine

## Key Files

- `plugins/workaholic/skills/propose/scripts/cursor.sh` — the read/advance implementation to rework
- `plugins/workaholic/skills/propose/SKILL.md` — the Cursor contract section (runner-local premise, decision C1)
- `plugins/workaholic/commands/propose.md` — step 2's "on initialized: true, report and stop"
- `docs/proposal-loop-runbook.md` — §4 cursor bootstrap and replay
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for cursor.sh against a local origin

## Implementation Steps

1. Rework `cursor.sh` to store the cursor as `refs/workaholic/proposal-cursor`
   on origin:
   - `read`: fetch the ref (`git fetch origin +refs/workaholic/proposal-cursor:refs/workaholic/proposal-cursor`);
     when absent on origin, bootstrap it to `origin/main` HEAD **and push it**,
     so initialization happens once per repository, not once per container.
     Report `{commit, initialized, fetched}` — on an unreachable origin, degrade
     to the last-fetched local copy with `fetched: false` (reader degrades;
     a stale cursor only re-reads an old window, and dedup absorbs that).
   - `advance <commit>`: push with `--force-with-lease` against the value read
     at the start of the batch, so two racing runners resolve by push, never by
     clock. A lost race is a reported no-op (`advanced: false, reason: "raced"`)
     — the winner has already covered the window. A push failure on advance is
     loud (the next tick re-reads the same window, which is the safe direction).
   - Migration: if the legacy `.workaholic/proposal-cursor` file exists and the
     remote ref is absent, seed the ref from the file, then remove the file.
2. Update `commands/propose.md` step 2: `initialized: true` now means "the
   repository's cursor was just born" — the run continues (window is empty by
   construction on the very first tick, so behavior is unchanged in effect but
   the per-container stop is gone).
3. Update the SKILL's Cursor contract: supersede decision C1's "runner-local"
   premise with the shared-ref model; keep advance-only-after-PR-open semantics
   verbatim.
4. Update runbook §4 (bootstrap = ref creation; replay = `git push --force`
   the ref to an older commit, a human act).
5. Extend the hermetic suite: bootstrap-pushes-once, read-from-second-clone
   sees the same cursor, advance race (two clones, one wins, loser reports
   `raced`), offline read degrades with `fetched: false`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A second fresh clone of a repo whose cursor exists reads that cursor without ever seeing `initialized: true`
- `advance` from a stale reader loses the race loudly instead of rewinding the ref
- The legacy local file is folded into the ref on first touch and never consulted again

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new cursor cases green; suite baseline otherwise unchanged)

**Gate** — what must pass before approval:

- Hermetic suite green; `verify.mjs` / `validate-metadata.mjs` clean; docs updated in the same change

## Considerations

- Refs outside `refs/heads/` are invisible to branch listings and the claim
  scan by construction — no interference with `list-claims.sh`.
- `--force-with-lease` on a non-branch ref needs the explicit
  `--force-with-lease=refs/workaholic/proposal-cursor:<expected>` form; verify
  against the git version on the runners.
- The cursor only ever moves forward in normal operation; a deliberate replay
  is a human `git push --force` and stays documented, not scripted.

## Final Report

Development completed as planned. `cursor.sh` now stores the cursor as
`refs/workaholic/proposal-cursor` on origin, reads it through a local ref of the
same name, bootstraps-and-pushes once per repository, advances under
`--force-with-lease`, degrades on an unreachable origin (`fetched: false`) and
fails an unpublishable advance loudly. The legacy file is folded into the ref on
first read and removed. `commands/propose.md` step 2 continues instead of
stopping, and the SKILL's Cursor contract, the runbook §4, `CLAUDE.md`,
`README.md`, `rules/workaholic.md` and `layout-doctor.sh`'s comment now describe
the shared ref.

### Discovered Insights

- **Insight**: git enforces fast-forward on refs outside `refs/heads/` too — a
  push that would rewind `refs/workaholic/proposal-cursor` is rejected
  non-fast-forward without any force flag, so the cursor cannot move backwards
  by accident even before the lease is considered.
  **Context**: the lease is therefore protecting against the *forward* skip (a
  runner advancing past a window another runner has not covered), not against a
  rewind. Both were measured against git 2.50.1 before the script was written.
- **Insight**: `--force-with-lease` is only consulted when the update actually
  changes the ref. Pushing the value the remote already holds is
  "Everything up-to-date" and succeeds with a stale lease.
  **Context**: this is why the race test advances to a *different* commit — a
  test that re-pushed the winner's own value would pass while proving nothing.
- **Insight**: `git fetch` of an absent remote ref is a fatal error, not an
  empty result, so presence and reachability are read with `ls-remote` first.
  **Context**: that single call also separates "no cursor yet" from "I could not
  look", which are opposite situations — one bootstraps, the other degrades.
