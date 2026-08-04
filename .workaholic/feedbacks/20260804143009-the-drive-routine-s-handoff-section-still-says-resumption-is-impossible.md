---
type: Feedback
title: The drive routine's handoff section still says resumption is impossible
kind: concern
source: discussion
created_at: 2026-08-04T14:30:09+09:00
author: a@qmu.jp
supersedes: 
---

# The drive routine's handoff section still says resumption is impossible

## Description

The `[Drive]` routine template's §5 opens: *"This routine cannot resume its own unfinished work, and neither can a developer's local /drive: a claimed unit is excluded from every later survey, and this sandbox's worktree exists nowhere else."*

That has been false since 2026-08-01. Resumption shipped: `claim.sh resume <unit-id>` re-creates the worktree at the pushed branch tip, and `plan-units.sh` offers a lapsed-heartbeat claim of the same identity back as `resumable[]`. The live routine carries the same sentence, and both were re-read during the 2026-08-04 /workaholify survey.

The §1 rule that was restored into the template on the same day cites this sentence as its reason — *"the resume gap in §5: a claim this session cannot finish is a claim nobody can resume"* — so the stale premise is currently load-bearing for a live scheduling rule.

Consequence: a tick that runs out of window hands off and leaves the claim, when it could instead be resumed by the next tick. That is the conservative direction, so nothing is lost today; what is wrong is that the routine's stated model of the system no longer matches the system, and the next person to reason from §5 will reason from a fact that stopped being true three days ago.

## How to Fix

Rewrite §5 to say what is now true: an unfinished unit is pushed and left claimed, and the **next tick resumes it** via the survey's `resumable[]` offer rather than requiring a human. Then re-derive §1's unit-limit reasoning from whatever is actually true after that — it may still hold for a different reason (a half-driven unit still costs a takeover round trip), but it should not rest on a retired gap. Refresh the live routine through /workaholify once the template is settled.
