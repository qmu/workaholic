---
created_at: 2026-08-04T21:46:00+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260804-135757
---

# catchup-main.sh classes an append-only .workaholic/ conflict as content, halting a ship it could reconcile

## Overview

`skills/ship/scripts/catchup-main.sh` classifies a catch-up conflict as `mechanical` or `content` by
**path**: version/lockstep manifests and `outputs/` are mechanical, everything else is content. The
Ship Flow then treats `content` as needing human judgement — it halts an interactive ship, and
`workaholic:drive`'s unattended routing demotes an `auto` unit to the PR path.

But the `.workaholic/` tree is full of **append-only** files that both sides routinely extend:

- a mission's `## Changelog` (every ticket-archived, story-reported and run-recorded line appends)
- `.workaholic/stories/index.md`
- `.workaholic/feedbacks/index.md`
- `.workaholic/release-notes/index.md`

When two branches each land work, both append their own line to the same tail, and git reports a
conflict whose resolution is unambiguous: **keep both sides**. There is no behavioural judgement to
make — but because those paths are not on the mechanical list, the ship stops.

## Measured

Observed on a ship where the base had advanced by one merged unit. Seven files conflicted: five were
version manifests, already classed mechanical, and two were `.workaholic/` append-only files. Those
two alone forced the entire catch-up to be classed `content`. Both were resolved by keeping both
sides, and neither required judging anything about either side's content.

## Why it matters more unattended than interactively

Interactively it costs one prompt. In the unified `/drive` run it costs the merge: an `auto` unit is
demoted to the PR path and waits for a human. And it recurs on **every** concurrent pair of units,
because both sides always append to the mission changelog and to the story index.

## Policies

- workaholic:implementation / observability — a classifier that reports "needs human judgement" for a
  case it could decide trains the reader to override it on sight, which is how a genuine content
  conflict eventually gets waved through.
- workaholic:operation — reconciliation is stated to be what ship does rather than an optional
  choice; a classifier that cannot recognise a routine reconciliation undercuts that rule.

## Implementation Steps

1. Extend the mechanical classification to the `.workaholic/` append-only set: the OKF `index.md`
   files under `stories/`, `feedbacks/`, `release-notes/` and `tickets/`, and a mission's
   `## Changelog` section.
2. Rule the scope deliberately — by **path** (the listed index files) or by **conflict shape** (both
   sides appended distinct lines at the tail; no existing line was modified or removed). The shape
   test is stronger and covers files added later; the path test is simpler to reason about. Pick one
   and record why.
3. When resolving, keep both sides. For a changelog, order the merged lines by their leading date so
   the result reads chronologically rather than in merge order.
4. Anything that is not a pure append — a modified or removed line — stays classed `content`.

## Quality Gate

1. A catch-up whose only non-manifest conflicts are append-only `.workaholic/` files no longer
   reports `conflict_class: "content"`, and the resolved file contains **both** sides' lines.
2. A conflict where one side modifies or removes an existing line in those same files is still
   reported `content`.
3. The unified `/drive` run merges an `auto` unit whose only catch-up conflicts are of the
   append-only shape, instead of demoting it to the PR path.

## Considerations

- Ordering a merged changelog by date is only well-defined while every line starts with one. If that
  is not guaranteed, append-in-merge-order is the honest fallback and should be stated as such rather
  than silently assumed.
