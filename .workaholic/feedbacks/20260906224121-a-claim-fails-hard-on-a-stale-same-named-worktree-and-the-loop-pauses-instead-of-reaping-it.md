---
type: Feedback
title: A claim fails hard on a stale same-named worktree, and the loop pauses instead of reaping it
kind: instruction
source: development
subject: observer_ai:tamura.yoshiya@gmail.com
created_at: 2026-09-06T22:41:21+09:00
author: a@qmu.jp
supersedes: 
---

# A claim fails hard on a stale same-named worktree, and the loop pauses instead of reaping it

# A claim fails hard on a stale same-named worktree, and the loop pauses instead of reaping it

Source: https://github.com/qmu/workaholic/issues/1046

`claim:worktree_creation_failed` has paused the `osbrjp/coop-planner` loop three times in two
days, always from the same cause: the claim protocol creates a worktree named after the mission
slug, and when a worktree of that name already exists it fails hard and reports the mission as
paused. It never asks whether the existing tree is still doing anything.

Measured in `#coop-planner` (JST):

| When | What the channel said |
| ---- | --------------------- |
| 2026-09-05 05:15 | `Blocked - claim:worktree_creation_failed`, naming `work-20260903-132925` |
| 2026-09-06 14:53 | `Blocked - claim:worktree_creation_failed`, "failing since 2026-09-05 05:15 JST, at least 4 ticks", naming `work-20260903-092958` |
| 2026-09-06 20:51 | `Paused - worktree_creation_failed` on `make-the-screens-previewable-and-tell-the-operator-what-to-open` |

Measured in the repository at 2026-09-06 21:23 JST, `git worktree list` held six trees. Five of
them were, by `git status --porcelain`, `git rev-list --count main..<branch>` and
`git merge-base --is-ancestor <branch> main`, **clean, zero commits ahead of `main`, and fully
merged** — nothing was in them and nothing was lost by removing them. Three of the five were
named after live mission slugs, so each was a future `worktree_creation_failed` waiting for that
mission's next ticket. The sixth was a genuine live claim (2 ahead, unmerged) and was left alone.
The distinction cost three `git` reads.

The failure is also self-healing in a way that hides it: the 20:51 pause resolved on its own when
a later session created `work-20260906-212534` for the same mission, so the channel shows a pause
with no matching recovery notice and a reader cannot tell a transient collision from a stuck one.

## What should happen

A claim that finds a same-named worktree should make the three reads above and reap the tree when
it is clean, zero-ahead and merged — that is the whole test, and it is the one a session performs
by hand every time this fires. A tree that is dirty, ahead, or unmerged must still refuse, loudly
and by name, because that one holds work. Failing hard on both cases together is what turns
ordinary housekeeping into a paused loop.

Failing that, the pause should at least report **which** of the three conditions held, so the
channel says whether a person needs to look at the tree or whether the loop simply tripped over
its own litter.
