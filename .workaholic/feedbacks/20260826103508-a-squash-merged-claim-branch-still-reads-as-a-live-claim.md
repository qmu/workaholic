---
type: Feedback
title: A squash-merged claim branch still reads as a live claim
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T10:35:08+00:00
author: a@qmu.jp
supersedes: 
---

# A squash-merged claim branch still reads as a live claim

Tick `20260826-015129`'s `stalled-units` step reported **5 claimed units, all stale**, the oldest stopped 171 hours. Checked one by one against GitHub, three of the five are not stalled at all — their work merged days ago:

| unit | branch | pull request | state |
| --- | --- | --- | --- |
| make-the-draft-release-note-an-agent-s-release-plan | work-20260818-205051 | #521 | **merged** |
| make-workaholify-converge-the-account-s-routines | work-20260819-113836 | #537 | **merged** |
| make-a-rename-a-registry-entry-not-a-sweep | work-20260821-035855 | #546 | **merged** |
| batch-20260818215156 | work-20260818-215157 | #520 | closed unmerged |
| batch-20260819063000 | work-20260819-063001 | — | never opened one |

## Why the oracle says otherwise

The claim protocol's stated rule is that **a merge releases a claim by definition**, and `list-claims.sh` implements it by reading *unmerged remote branches*. Those two agree only under a merge that makes the branch tip an ancestor of the base. These three were **squash-merged**: `merge_commit_sha` is a single-parent commit on `main` and the branch's own commits stay unreachable, so `git branch --merged` never sees them. Each still reads `ahead=11 / ahead=10 / ahead=11` against `origin/main` with its content fully landed.

## What it costs

- The residue accumulates with nothing removing it, exactly as the eleven finished-and-open missions did before `closable-missions` shipped.
- `stalled-units` (2026-08-23, issue #584) exists to route a stuck unit to a person. Three of its first five candidates were finished work, so the step's first real outing would have asked the claim holder about three units that need nothing — and the credibility of an asked-once question is spent the first time it is wrong.
- A resumable-claim reader sees held claims that nobody holds.

## What this does not decide

Whether the repair belongs in the oracle (recognise a squash-merged branch by content — costly and not free of false positives), at the ship seam (delete the branch when the pull request merges, which is where the claim is released in principle), or in the merge convention itself (a merge commit keeps the oracle honest at no cost). Each moves a different piece and `workaholic:ship` §7's prohibitions bear on the second. Filed as a finding; the ruling is the operator's.

The tick asked nobody about these five, deliberately: three of the questions would have been wrong, and one question naming the residue is worth more than five naming its symptoms.
