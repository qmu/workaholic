---
type: Feedback
title: Close the units the loop already finished
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-27T01:16:38+00:00
author: a@qmu.jp
supersedes: 
---

# Close the units the loop already finished

Source: https://github.com/qmu/workaholic/issues/641

The `[Propose]` routine, reading the strategy `an-autonomous-improvement-loop-run-by-the-routines`, asks for a **contraction**: make the loop close the units it has already finished, and make a unit it could not close a named, reported, once-asked fact instead of a permanent silence.

## What it asks for

Today the `review` route merges the unit's pull request over REST the moment `/story` opens it. In a routine-fired container that call is answered `403 "Merging pull requests is not permitted for this session type"` — the refusal `branching/scripts/merge-reason.sh` already classifies as `session_type_cannot_merge`, and the one refusal `rules/shell.md` permits to be retried through `mcp__github__merge_pull_request`. That retry lives **only in prose**: a script cannot call an MCP tool, so the closing act sits in a sentence the agent may simply not take, and nothing records whether it was taken.

What happens next is invisible by construction. The unit's tickets stay in `todo/`, the claim reads `queue_drained` / `reported: true`, and every later survey excludes them `claimed_reported` — the **same** exclusion as a unit legitimately waiting on a person because a scan finding held its pull request. One is a human's business; the other is the loop's own undelivered work. Nothing tells them apart, so nothing ever comes back to it, and `/implement` still reports `ok`.

## What was measured

At 2026-08-27 00:42 UTC on this repository: four pull requests opened by the loop on 2026-08-26 (#622, #625, #633, #635) are green — `validate` and `freshness` both `success` — and all four are open and unmerged. Four tickets are excluded `claimed_reported`, the oldest (`20260818203011-turn-off-routine-completion-notifications.md`) since 2026-08-18, nine days. The survey reports `backlog_size: 11` and `backlog: []`: eleven tickets queued, none offered, hour after hour.

## The experience it demands

An hour ends and the loop has finished four units, delivered none of them, and offered none of its eleven queued tickets to anybody — and the only trace is an `ok` in a run report nobody opens.

After this, a unit the loop finishes reaches `main`, or the run says which refusal stopped it, in that refusal's own vocabulary, in the run report and once to a person by name. A survey that offers nothing distinguishes the tickets a human is legitimately sitting on from the loop's own undelivered work, and `ok` stops covering the second.

## The seams it names

`drive/SKILL.md` §6 and §7 and `drive/reference/routing.md` (the route and the terminal token), `branching/scripts/merge-reason.sh` (the refusal vocabulary, already correct), `drive/scripts/list-claims.sh` and `plan-units.sh` (the exclusion that conflates the two states), `moderate/scripts/` (the step that reaches a person), and `scripts/e2e/loop-drill.sh` (the proof).

## What it is chosen against

Enriching the direction layer — the Aim's own closing claim. It loses now on the arithmetic: a richer direction feeds asks into the same pipe, and the pipe's exit is blocked. Also refused as housekeeping: merging those four pull requests by hand, and adding the missing `.claude/git-identities` alias line.
