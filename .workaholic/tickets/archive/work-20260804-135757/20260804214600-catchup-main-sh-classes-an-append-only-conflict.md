---
created_at: 2026-08-04T21:46:00+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
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

## Final Report

Development completed as planned.

`catchup-main.sh` gained a pass that reconciles append-only `.workaholic/` conflicts in
place and completes the merge when nothing is left unmerged; the classifier then runs over
what *remains*, so an index or changelog no longer drags a manifest-only catch-up to
`content`. The recognizer and resolver live in the new
`skills/ship/scripts/lib/append-only.sh`. Four scenarios are pinned in
`test-workflow-scripts.mjs` (append-only index, mission changelog with date ordering, a
rewritten line refused, and the mixed index+manifest case).

**Step 2's scope ruling — both tests, and why.** The ticket offered path *or* shape. Neither
alone satisfies both quality gates, so the implementation uses **path for scope, shape for
resolution**: gate 1 wants an append-only conflict reconciled, gate 2 wants a modified or
removed line in *those same files* still reported `content` — which a pure path test cannot
do. Pure shape would satisfy both but widens insertion-only union merging to every path in
the repository, silently concatenating two independently added functions in implementation
code. The path set (`.workaholic/` indexes at any depth, and `missions/*/mission.md`) bounds
where auto-reconciliation is permitted at all; the shape test decides whether this
particular conflict earned it. The rationale is recorded in the library header rather than
here, so the next reader finds it where the code is.

The shape test is exact rather than heuristic: it compares merge stages 1/2/3 with `git
diff --numstat` and requires **zero deletions on both sides**, since git counts a modified
line as one addition plus one deletion and a reorder as both. Resolution is `git merge-file
--union`, which keeps both sides by construction once the shape has been established.

### Discovered Insights

- **Insight**: A shape test written against the *conflicted working file* cannot answer the
  question at all — the markers show what each side has, not whether those lines are new.
  The merge index's three stages (`:1:`/`:2:`/`:3:`) are what make "no existing line was
  modified or removed" decidable, and they are only available while the merge is unresolved.
  **Context**: This is why the pass has to run before `git merge --abort` rather than as a
  separate script the ship flow calls afterwards.
- **Insight**: A missing stage 1 (add/add — both sides created the file) is *not* an append
  and is deliberately refused. There is no ancestor to prove the shape against, and
  concatenating two independently created files is a different reconciliation from
  extending a shared tail.
  **Context**: Plausible for a newly created area's `index.md`, so the refusal is a decision
  rather than an oversight, recorded in the library header.
- **Insight**: The obvious test for the gate-2 case does not actually exercise the
  classifier. Ticking an acceptance box in `## Acceptance` while the other side appends to
  `## Changelog` is two edits far apart in the file, which git merges cleanly — no conflict
  ever reaches the classifier. The test had to rewrite the line the other side appends
  *next to*.
  **Context**: Any future test of a refused shape must make the two edits overlap, or it
  will pass while asserting nothing.
- **Insight**: `hooks/posix-lint.sh` reads a literal `<<<` as a here-string bashism wherever
  it appears, including inside a single-quoted grep pattern. A conflict-marker sweep has to
  be written as a repetition (`<{7}`) instead.
  **Context**: The same trap waits for any script that greps for conflict markers.
