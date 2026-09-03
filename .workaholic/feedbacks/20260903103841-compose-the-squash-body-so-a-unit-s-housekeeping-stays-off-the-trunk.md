---
type: Feedback
title: Compose the squash body so a unit's housekeeping stays off the trunk
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T10:38:41+09:00
author: a@qmu.jp
supersedes: 
---

# Compose the squash body so a unit's housekeeping stays off the trunk

Source: https://github.com/qmu/workaholic/issues/948

A unit's internal bookkeeping commits become the base's permanent record, because the merge step
lets the forge compose the squash body instead of composing it itself.

## The ask

> この refresh heartbeat みたいなコミット、まだこのリポジトリ目立つな、こんなソフトウェアに関係ない
> クソコミット重ねないで欲しい

## Measured

In one repository running this loop, `main` carries 190 commits whose message text contains
`Refresh heartbeat`. None of them is a heartbeat commit: they are the squash merges of ordinary
units, and the heartbeats are inside the merge bodies. One example: a single unit's squash body is
267 lines, at least five of them the bullet `* Refresh heartbeat`, with the branch's real work
interleaved with the bookkeeping in whatever order the run happened to commit.

This is not the heartbeat's fault and does not go away when the heartbeat does. The squash body is
whatever the forge concatenates when the caller does not supply one, so any commit a run makes for
its own housekeeping — a heartbeat, a claim stamp, an hours record, an index refresh — reaches the
base's permanent history by the same route. The bookkeeping was meant to live on a branch that
disappears; it is landing on the trunk instead.

## Why the merge step owns this

The route's merge is an API call that accepts both a title and a body. The runs measured here pass
the title and leave the body unset, so the forge fills it with the branch's own commit messages.
Nothing else in this loop treats a commit message that casually — a unit's story is written
deliberately, its pull request body is composed, and then the thing that actually enters `main` is
assembled by a default nobody chose. The material for a good body already exists: every unit writes
a branch story before it routes, and that story is the composed statement of what the unit did.

## What would make it done

- The merge step composes the squash body rather than letting the forge concatenate. The branch
  story's summary is the obvious source; a one-line fallback naming the unit is better than the
  concatenation.
- A run's housekeeping commits are named as such, so whatever composes the body can exclude them by
  rule rather than by pattern-matching a title.
- The commits already on the trunk stay there. History is not rewritten for tidiness — this asks
  that the next merge be clean, not that the last two hundred be erased.

Stated separately so it is not conflated: the operator reports the heartbeat commit itself has
already been removed upstream. The deployment measured here runs a cached plugin that still writes
them, and it wrote one during this measurement. That is a version-propagation matter and is not
what this ask is for — even with no heartbeat at all, the next housekeeping commit lands in the
trunk's record by the same route.
