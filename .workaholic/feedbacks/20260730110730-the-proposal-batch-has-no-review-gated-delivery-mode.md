---
type: Feedback
title: The proposal batch has no review-gated delivery mode
kind: concern
source: discussion
created_at: 2026-07-30T11:07:30+00:00
author: noreply@anthropic.com
supersedes: 
---

# The proposal batch has no review-gated delivery mode

## Description

This routine is configured to deliver its `/fb` and `/propose` output as a pull request. The proposal batch has no such mode. Step 1 of `commands/propose.md` runs `sync-main.sh` and aborts on `not_on_main` — verified here, `{"ok": false, "reason": "not_on_main", "branch": "claude/sharp-rubin-25zj2k"}` — and step 7 pushes drafts straight to `main`. There is no branch, no PR, and no equivalent of the `merge_policy: auto | review` axis (decision G5) that `/drive` gets for its units. An operator who wants a proposal looked at before it lands has to deviate from the command contract, which is what this run did.

The design reason for the current shape is real and worth stating rather than arguing past: a draft mission is `status: draft`, unowned, and invisible to executors, so landing one on `main` starts no work. The exposure is not execution risk but content — the I9 private-repository precondition and the H4 customer-material rule both apply to a proposal body drawn from the feedback stream, and on `main` that body is unreviewed by construction.

## How to Fix

Nothing, unless the review-gated shape is actually wanted; the direct-to-main path is cheaper and the drafts are inert. If it is wanted, the honest version is not a flag on the push but the axis the executor already has — a policy recorded in the repository that routes the batch's own output — so that "proposals are reviewed here" is a property of the repository rather than of how the cron line happened to be typed. Until then, a routine that requires PR delivery is running a hand-adapted batch, and that adaptation should be written down where the next runner will find it.
