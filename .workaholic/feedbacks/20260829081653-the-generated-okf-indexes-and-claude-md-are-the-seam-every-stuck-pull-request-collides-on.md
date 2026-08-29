---
type: Feedback
title: The generated OKF indexes and CLAUDE.md are the seam every stuck pull request collides on
kind: instruction
source: discussion
subject: observer_ai:tamurayoshiya
created_at: 2026-08-29T08:16:53+00:00
author: a@qmu.jp
supersedes: 
---

# The generated OKF indexes and CLAUDE.md are the seam every stuck pull request collides on

Source: https://github.com/qmu/workaholic/issues/707

The `[Moderate]` tick's `merge-conflicts` step (tick `20260829-075114`) reports that 2 of
7 open pull requests cannot merge into `main`, and that both collide on the same surface:
the generated OKF `index.md` files and `CLAUDE.md`.

## What the tick found

- #633 (`work-20260826-134108`, *Deploy the docs site to a Cloudflare Worker on merge to
  main*, opened 2026-08-26) touches `CLAUDE.md`, `.claude-plugin/marketplace.json`, the
  three version files, `.workaholic/missions/index.md`, `.workaholic/stories/index.md`
  and `.workaholic/deployments/index.md`.
- #622 (`work-20260826-103318`, *Validate the moderation tick's window, and report what
  each step found*, opened 2026-08-26) touches `CLAUDE.md`,
  `plugins/workaholic/skills/moderate/**` and `scripts/test-workflow-scripts.mjs`.
- The `stuck-prs` step names two more in the same state — #625 and #688 — and every one
  of those four carries edits to `CLAUDE.md` or to a generated `.workaholic/*/index.md`.

## Why this is the loop's own debt

`main` is the continuously auto-merged development branch and the loop lands work onto it
roughly every half hour. Two files are touched by nearly every unit the loop produces:
`CLAUDE.md`, which this repository's own rule requires every behaviour-changing unit to
update in the same commit, and the per-area `index.md` files, which
`okf/scripts/refresh-index.sh` regenerates before every knowledge commit. So a branch that
stays open for more than an hour or two is close to guaranteed to conflict on a file no
human wrote, and the conflict is mechanical rather than semantic — two regenerated
indexes, or two appended paragraphs.

## What the ask is, and what it is not

Not a push onto a claimed branch: `workaholic:drive` and `moderate/reference/workflow.md`
§4 both refuse that, and a `work-*` branch is a claim whose heartbeat is its own tip. The
ask is for a change to how these two surfaces are written or merged, so that the collision
stops being the default outcome of a branch living longer than one tick. Three options are
named, none pre-decided:

- regenerate the OKF indexes at the merge seam rather than carrying them in the branch
  diff, so a regenerated index is never part of a conflict;
- give the generated `index.md` files a `.gitattributes` merge strategy that resolves them
  by regeneration;
- have the driving run bring the base into its own branch before it opens the pull
  request, narrowing the window in which a long-lived branch can drift.

The four pull requests above are evidence, not the thing to be edited; the unit that comes
out of this takes a fresh claim under `review` policy.
