---
created_at: 2026-08-01T00:30:34+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 4h
commit_hash:
category: Added
depends_on:
mission:
claim: work-20260801-023444
---

# Worktrees are created by the workflow but never reclaimed, so a machine running it fills its disk until unrelated work breaks

## Overview

A machine driving this workflow across four repositories reached **100% disk**
(150 GB, 945 MB free). The failure surfaced somewhere unrelated — a container
build died mid-layer with "no space left on device" — and only then did anyone
look at why.

The cause is that **this workflow creates worktrees and nothing removes them.**
Measured at that moment:

| | |
| --- | --- |
| Total held in `.worktrees/` across four repositories | **~53 GB** |
| Of that, fully merged and clean (`ahead=0`, `dirty=0`) | **~31 GB** |
| Worst repository | **29 worktrees**, 22 of them merged — 24 GB |
| Another repository | **6 worktrees, all 6 merged** — 8.3 GB, i.e. 100% garbage |

Removing every merged-and-clean worktree with `git worktree remove`, plus two
stale build-output directories, took the machine from 3.5 GB free to 51 GB free.
**Nothing was lost** — every removed worktree's commits were already on the base
branch. That is the point: this was 31 GB of work the workflow had already
finished with and simply never let go of.

### Why it accumulates

Teardown exists in the design but is conditioned on an event that often never
arrives. `/ship` explicitly disclaims it ("Teardown belongs to the caller, not
here"), the unified drive run tears down the unit it just merged, and a mission
worktree is removed at mission close. Each is reasonable alone, and together they
leave a large gap:

- a mission that stays open for weeks keeps its desk the whole time, including
  long after the desk's branch merged;
- anything driven outside those exact paths — a hand-driven branch, an
  interrupted run, a batch whose caller died — is never anybody's teardown;
- a batch-style flow that mints a worktree per run accumulates fastest of all
  (14 such worktrees in one repository, all merged, 183 MB–1.6 GB each).

**No step in the workflow ever reports the cost**, either. A worktree is created
silently and its several hundred MB never appear in any output, so the growth is
invisible until a disk fills.

### Two multipliers worth naming

- **Each worktree carries its own dependency install.** Observed: 250–620 MB of
  `node_modules` per worktree. N worktrees means N copies of the same tree, and
  that is the bulk of the "merged and clean" 31 GB above.
- **Build output inside a worktree is unbounded and invisible.** One single
  worktree held **13 GB** of Rust build output; another held 3 GB. Both belonged
  to already-merged branches. Nothing prunes it, and it is not what anyone means
  by "keep the worktree around in case I need it".

### A structural side effect

`.worktrees/` lives **inside the repository root**, so anything that treats the
repo root as an input silently swallows every worktree. This is how the container
build actually failed: with no ignore file, its build context was the repository
root — 6.2 GB, of which 5.7 GB was `.worktrees/` — and it tried to copy all of it
into an image layer. Backups, indexers, and any tool that walks the tree have the
same exposure. The layout choice is defensible, but its consequences are not
currently stated anywhere a project author would see them.

## What the change should provide

- **A reclaim command that is safe by construction.** List every worktree whose
  branch is fully merged into the base **and** whose tree is clean, with its size,
  and remove the confirmed set. The two conditions together are what made the
  cleanup above provably lossless; either alone is not enough. It must skip
  anything with unmerged commits or uncommitted changes and **say which and why** —
  six worktrees were correctly skipped on that basis, and a reaper that silently
  took them would have destroyed real work.
- **Teardown that does not depend on one caller surviving.** Whatever removes a
  worktree today should be complemented by a sweep that runs on a schedule or at a
  natural checkpoint, so an interrupted run or a long-lived mission does not pin
  storage indefinitely.
- **Report the cost at creation and in status.** Worktree creation should say how
  much the tree occupies once populated, and whatever lists worktrees should show
  size and merged state, so growth is visible before it is a disk-full incident.
- **Reclaim build output separately from the worktree.** A merged worktree someone
  wants to keep still does not need 13 GB of build artifacts; pruning those should
  be possible without removing the worktree.
- **Warn project authors about the in-repo location.** Document that `.worktrees/`
  sits inside the repository and therefore lands in any build context, archive, or
  index rooted there, and recommend the corresponding ignore entry.

## Policies

- `workaholic:operation` — storage exhaustion on the machine the workflow runs on
  is an operational failure of the workflow itself; a tool that allocates without
  ever reclaiming is not finished.
- `workaholic:implementation` / `policies/objective-documentation.md` — the growth
  is invisible because nothing reports it. Creation and listing should state the
  cost as an observable fact rather than leaving it to be discovered by `du`.
- `workaholic:development` / `policies/overnight-ai.md` — unattended runs are what
  multiply this: a flow minting a worktree per run accumulates fastest, and nobody
  is watching while it happens.

## Key Files

- `plugins/workaholic/skills/branching/scripts/` — the worktree creators and
  `cleanup-mission-worktree.sh`; the natural home for a reaper and for size
  reporting at creation.
- `plugins/workaholic/skills/branching/scripts/list-worktrees.sh` — extend with
  size and merged state so status output shows what is reclaimable.
- `plugins/workaholic/skills/ship/SKILL.md` and `plugins/workaholic/skills/drive/`
  — the two places that own teardown today; reconcile them with a sweep that does
  not depend on a specific caller completing.
- `plugins/workaholic/skills/mission/` — mission-close teardown, which is correct
  but too late for a long-lived mission whose desk merged weeks earlier.

## Quality Gate

Decided: script-level verification with fixture repositories — the reaper's
safety rule is a predicate over git state, which is exactly testable without
touching a real tree.

**Acceptance criteria:**

- [ ] A read-only listing reports every worktree with its size, its commits ahead
      of the base, and whether its tree is clean.
- [ ] The reaper removes only worktrees that are both fully merged and clean, and
      names every skipped worktree with the reason it was skipped.
- [ ] Fixtures cover each skip reason independently: unmerged commits with a clean
      tree, a merged branch with uncommitted changes, and both together.
- [ ] A worktree's build output can be pruned without removing the worktree.
- [ ] Worktree creation reports the storage the new tree will occupy.
- [ ] Documentation states that the worktree directory lives inside the repository
      and therefore enters any build context or archive rooted there, with the
      recommended ignore entry.
