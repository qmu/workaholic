---
type: Feedback
title: The loop fast-forwards its own coordinator checkout while subagents run
kind: concern
source: development
subject: observer_ai:workaholic-loop
created_at: 2026-09-06T11:37:30+09:00
author: a@qmu.jp
supersedes: 
---

# The loop fast-forwards its own coordinator checkout while subagents run

Source: https://github.com/qmu/workaholic/issues/1012

`commands/infinite-development.md` §0 states an invariant:

> `/implement` writes in a claim worktree and `/specificate` through a publish tree, and both
> leave the caller's checkout **byte-identical by design** — which is exactly why nothing else
> in the loop will ever notice this.

That invariant does not hold. The Unified Run's freshen step (`sync-main.sh`) runs in the **main
checkout** and moves it.

## Measured, 2026-09-06

The coordinator session held `b4a59298a` for its first sixteen ticks and deliberately did not
pull, precisely to avoid changing the plugin tree under a running subagent. Its reflog shows the
checkout was moved anyway, twice, from inside the loop, while that subagent was still running:

```
6ac9c0f27 HEAD@{2026-09-06 11:22:00 +0900}: merge origin/main: Fast-forward
2134d8ba6 HEAD@{2026-09-06 11:20:26 +0900}: merge origin/main: Fast-forward
b4a59298a HEAD@{2026-09-06 09:20:13 +0900}: merge origin/main: Fast-forward
```

The 11:20 and 11:22 entries land inside one five-minute tick, with the `implement` run 56
minutes into its unit and a `moderate` run 8 minutes into its own.

## Why it matters

A subagent reads the plugin out of this working tree — that is the stated reason §0 asks the tick
to look at the checkout at all. A fast-forward here swaps the behaviour a running agent is
executing underneath it: the skill files, reference files and command bodies it has not yet read
become a different version from the ones it already read, so a run can straddle two versions of
its own contract with nothing recording that it did.

Nothing detects it. `git status` stays clean throughout, because a fast-forward is not a dirty
tree — so §0's own check, which exists to catch *the loop is running behaviour that is not what
you think*, answers `clean` for the whole event.

## What this corrects, and what it does not

This record **partially corrects** `20260906110736-tick-progress-sh-reads-a-working-tree-the-loop-never-freshens.md`.
That record got the consequence right and the mechanism wrong: it stated that nothing in the loop
ever freshens the coordinator's checkout. The tree **is** freshened — by an unrelated concurrent
run, at an unpredictable moment, which is worse than never, because the reading is then neither
current nor stably stale.

It is deliberately **not** recorded as `supersedes`. The earlier concern's ask — that the tick
read the base explicitly rather than whatever state a concurrent run left the checkout in — is
still open and unrepaired, and superseding would close it. Both records want the same repair; only
the mechanism sentence in the earlier one is wrong.

## The fork this opens, which is a person's to settle

Either the invariant is true and `sync-main.sh` must freshen somewhere that is not the caller's
checkout, or the invariant is false and §0 must say so — at which point the tick's
`checkout_dirty` check needs a companion that notices the checkout **moving**, not only becoming
dirty. Choosing between those is a design decision the loop has no standing to take, and it is
recorded here rather than taken.

## What must not be done

Do not repair this by having the coordinator tick pull as well. Two writers of one checkout is the
failure described here, not the cure.
