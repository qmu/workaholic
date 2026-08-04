---
created_at: 2026-08-04T16:02:18+00:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
---

# The claim scan reads a merged branch as a live claim on a shallow clone

## Overview

`skills/drive/scripts/lib/claims.sh` decides what is claimed by enumerating the `origin/*` branches
that carry commits not on `origin/main`, and by reading each one's newest `Claim <unit-id>` subject
out of `git log origin/main..origin/<branch>`. Both steps are ancestry queries, and **ancestry is
not computable across a shallow boundary**. On a shallow clone git cannot find the merge base, so a
fully-merged branch reports a large non-empty range and the scan reads a long-released claim as
live.

`claims_fetch` runs a plain `git fetch --prune origin`, which never deepens a shallow clone, so
nothing in the run repairs the condition.

This is not a hypothetical environment. **The hourly unattended `/drive` routine runs in a Claude
Code on the web container, and that container's checkout is shallow** — which makes the cloud
runner, the one consumer with no human watching its survey, the one that gets the wrong answer.

## Measured, on the 2026-08-04T15:57Z hourly tick

The container started shallow (`git rev-parse --is-shallow-repository` → `true`, `.git/shallow`
carrying 10 grafts). Against `origin/claude/sharp-rubin-xiorxm`, a branch whose work merged as
PR #109 on 2026-07-30:

| Query | Shallow (as the tick found it) | After `git fetch --unshallow` |
| ----- | ------------------------------ | ----------------------------- |
| `git merge-base origin/main origin/claude/sharp-rubin-xiorxm` | *(empty)* | resolves |
| `git log --oneline origin/main..origin/claude/sharp-rubin-xiorxm` | 154 commits | 0 commits |
| `git merge-base --is-ancestor 67a553c5 origin/main` (the `Claim batch-20260730180927` commit) | false | true |
| `list-claims.sh` | 2 claims | 1 claim |
| `plan-units.sh` → `resumable[]` | 1 entry | `[]` |

So the tick was offered `batch-20260730180927` as a resumable unit whose branch had been merged for
five days.

## Why the offer is worse than a stray row

**It invites a takeover of merged work.** `resumable[]` is a third offer, not a report — the skill
directs a run to take it over before claiming anything fresh. `claim.sh resume` would have built a
worktree at the merged branch's tip, pushed an empty `Resume` commit onto a branch nobody owns, and
handed the run the 4 tickets sitting in that tip's `todo/` — three of which are already resolved on
`main`. The run would then have re-driven, or re-reported, work that shipped last week.

**The verdict came from the fallback that exists to be safe.** The phantom claim's artifact list was
empty, because `_cs_branch` is `claude/sharp-rubin-xiorxm` while the stamp on the claimed ticket
reads `claim: work-20260730-180928` — the real claim branch — so the stamp match at
`claims.sh:369` skipped every file. `claims_has_work` then took its documented
"no artifacts means unknown, so assume work remains" branch (`claims.sh:246`) and returned `true`.
Every guard behaved as designed; the input was wrong one layer down.

**The symmetric failure is silent and costs real work.** A phantom claim whose stamps *do* resolve
subtracts its artifacts from the survey, and those tickets leave as `claimed_reported`. That is a
queue item hidden from the only executor the project has, reported as an ordinary exclusion. This
tick's phantom happened to hold nothing, so nothing was hidden — that was luck, not the design
working.

**And it pins the terminal token.** A resumable unit left untaken forbids `ok`, so an hourly loop
that correctly declines a phantom can never report anything but `pending`.

The magnitude scales with how much history the graft cuts off: this repository has 178 remote
branches and only 7 that are genuinely unmerged, so a broken ancestry test has 171 branches to be
wrong about.

## Policies

- workaholic:implementation / directory-structure — the fix belongs in the one shared scan
  (`lib/claims.sh`), never in a caller; a reader and a writer that disagree about what is claimed is
  the one state this protocol must not have.
- workaholic:implementation / coding-standards — the shallow probe is a conditional, so it lives in
  the bundled script, not in any command or skill prose.
- workaholic:implementation / observability — a survey that cannot see the history it is reasoning
  over must say so. Reporting a released claim as live is a confident wrong answer, which is exactly
  the masked failure this policy forbids; `fetched: false` already sets the precedent that the scan
  reports the quality of its own inputs.
- workaholic:operation — the affected consumer is the unattended hourly runner, so the wrong answer
  reaches published branches and commits rather than stopping at a log line.

## Implementation Steps

1. In `claims_fetch` (`skills/drive/scripts/lib/claims.sh`), probe with
   `git rev-parse --is-shallow-repository` and, when it reports `true`, fetch with `--unshallow`
   before the ordinary `--prune` fetch. Keep the function's contract: it **never fails**, so an
   unshallow that errors falls back to the plain fetch and the run continues.
2. Report the condition rather than only repairing it. Carry a `shallow` field out of the scan into
   `list-claims.sh` and `plan-units.sh`, set when the checkout was still shallow after the fetch
   attempt — a scan over an unrepairable shallow clone has established nothing about the claim set.
3. Treat an unrepaired `shallow: true` the way `backlog_error` and `current: false` are already
   treated in the drive skill's terminal-token table: it **forbids `ok`**. Add the row.
4. Document the invariant in `lib/claims.sh`'s header comment, beside the `fetched: false`
   asymmetry it belongs with, and in `skills/drive/SKILL.md`'s *Claims* section: the unmerged set is
   an ancestry query, and ancestry needs full history.
5. Update `CLAUDE.md`'s claim-protocol section in the same commit — its **Reader** bullet describes
   the scan's degradation modes and currently names only the offline one.

## Quality Gate

**Acceptance Criteria**

1. On a shallow clone of a repository containing a merged branch that carries a `Claim <unit-id>`
   commit, `list-claims.sh` does **not** report that unit, and `plan-units.sh` reports
   `resumable: []` for it.
2. `claims_fetch` still echoes `true`/`false` and never exits non-zero, including when `--unshallow`
   fails and when the clone is not shallow (where `--unshallow` errors by design).
3. A clone that remains shallow after the fetch attempt surfaces `shallow: true`, and a `/drive` run
   over such a survey terminates `pending`, never `ok`.
4. A full clone's scan output is byte-identical to today's — the repair is a no-op off the shallow
   path.

**Verification Method**

- Extend `scripts/test-workflow-scripts.mjs` with a hermetic case: build a throwaway repo, create
  and merge a claim branch, `git clone --depth=1` it into a second directory, and assert
  `list-claims.sh` reports no claim there. The existing claim-scan cases in that file are the
  pattern; the suite must stay network-free.
- `node scripts/test-workflow-scripts.mjs` passes.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — `lib/claims.sh`
  is in the `outputs/workflows` closure, so the bundle must be rebuilt in the same commit.

**Gate**

All four acceptance criteria hold, the smoke suite passes, and `git status --porcelain` is clean
after the rebuild (no `outputs/` diff left uncommitted).

## Considerations

- Deepening on every tick is not the proposal. The probe fires only when the checkout is actually
  shallow, and the repair is once per container — the unshallow measured a couple of seconds on this
  repository.
- Refusing to scan on a shallow clone was considered and rejected as the *primary* fix: it would
  make the hourly runner report `pending` forever without doing any work. It survives as step 3,
  the honest fallback for when the deepening cannot happen.
- Do not "fix" this by matching the stamp more loosely, or by making an empty artifact list mean
  "drained". Both would paper over the wrong-input problem and would break the two cases those
  branches were written for — a genuine stamp removal, and the artifact-list recovery measured
  on 2026-08-04.
- Found by the hourly unattended `/drive` runner, which hit the phantom offer and declined it. It is
  filed rather than fixed in place because it is outside any claimed unit's scope — the tick had
  nothing claimable.
