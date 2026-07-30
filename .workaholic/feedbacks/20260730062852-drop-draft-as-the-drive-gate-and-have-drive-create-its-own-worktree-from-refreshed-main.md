---
type: Feedback
title: Drop draft as the drive gate and have /drive create its own worktree from refreshed main
kind: instruction
source: slack
created_at: 2026-07-30T06:28:52+00:00
author: noreply@anthropic.com
supersedes: 
---

# Drop draft as the drive gate and have /drive create its own worktree from refreshed main

Feedback from tamura_yoshiya in Slack (#dev-workaholic) after merging PR #105, covering two related changes to how missions and tickets become executable and how `/drive` starts work.

First, the `draft` status is the wrong gate. Right now a mission or ticket can land on `main` while still carrying `status: draft`, which keeps it invisible to `/drive` and requires a separate approval step (`/mission approve ...`) before it can be picked up. The point being made is that merging into `main` *is* the approval: review happened in the pull request, and once it is on `main` the unit is ready to be driven. So the `draft` state should be dropped as a precondition for visibility — a mission or ticket present on `main` should be drivable, and whatever approval semantics are still genuinely needed should be expressed by ownership/claim state rather than by a `draft` flag that duplicates what the merge already decided. This should be applied consistently to both missions and tickets, and any command, docs, or template text that tells the user to run an approve step after merge should be updated to match.

Second, `/drive` should own its own working environment rather than driving whatever happens to be checked out. When `/drive` starts on a unit, it should first bring the local `main` branch up to date with the remote, then create a dedicated git worktree and branch from that refreshed `main`, and carry out the work inside that worktree. This keeps each drive isolated from any other in-flight work, guarantees it starts from current `main` instead of a stale checkout, and preserves the existing one-unit / one-claim / one-branch / one-PR invariant by making the branch creation part of the drive itself instead of a manual prerequisite. Cleanup of the worktree after the drive completes (or is abandoned) should be defined as part of this change.

These two points interact: with `draft` gone, a merged unit is immediately drivable, so `/drive` becomes the single entry point that both selects the unit and sets up the isolated branch/worktree it will be delivered on. The exact command surface, status vocabulary, and cleanup policy are left open for design, to be proposed as part of implementing this, keeping consistency with the existing mission/ticket lifecycle documented in the repository.

Recorded from GitHub issue #106 (https://github.com/qmu/workaholic/issues/106).
