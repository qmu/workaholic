---
type: Feedback
title: The stuck-prs ask key moves with GitHub's uncomputed mergeability so one pull request can be asked twice
kind: instruction
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T09:54:37+00:00
author: a@qmu.jp
supersedes: 
---

# The stuck-prs ask key moves with GitHub's uncomputed mergeability so one pull request can be asked twice

# The stuck-prs ask key moves with GitHub's uncomputed mergeability, so one pull request can be asked about twice

`step-stuck-prs.sh` derives its ask key from the sorted `<number>:<blocked_by>` set, and `blocked_by` is `unknown` whenever GitHub has not yet computed a pull request's mergeability. For one unchanged pull request that value flips between reads, so the key flips with it and `ask-question.sh`'s asked-once ledger — which matches the key exactly — does not recognise the second form as the same question.

Measured on tick `20260826-095103` (2026-08-26, this repository). PR #612 has been reported `612:conflict` by every `stuck-prs` line since tick `20260826-045138`, and the question about it was asked once, at 13:57 JST, under key `stuck-3306992771` — the digest of `612:unknown`. Two consecutive reads of the same step in this tick returned `612:unknown` (key `stuck-3306992771`) and then `612:conflict` (key `stuck-3236872750`); the gate answered `already_asked` for the first and `ask: true` for the second. Nothing about #612 had changed. The tick declined to post the duplicate, so no second question reached anybody, but only because the agent recognised the pull request by number rather than by key.

The key should identify the pull request and not the reading of it — for instance by excluding `unknown` from the digest, or by keying on the pull request number alone and carrying `blocked_by` in the question's wording, where a changed blocker is visible to the person without minting a new question.
