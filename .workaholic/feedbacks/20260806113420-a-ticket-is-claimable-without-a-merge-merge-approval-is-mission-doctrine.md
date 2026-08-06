---
type: Feedback
title: A ticket is claimable without a merge — merge-approval is mission doctrine
kind: instruction
source: discussion
created_at: 2026-08-06T11:34:20+09:00
author: a@qmu.jp
supersedes: 
---

# A ticket is claimable without a merge — merge-approval is mission doctrine

The developer's ruling, 2026-08-06: "a ticket cannot be claimed until its pull request merges" is wrong as doctrine — that gate belongs to missions (K1: merging the mission's pull request is the approval). A ticket's approval is its creation: writing a ticket is the instruction to implement it, and the ticket records its own merge_policy. The J4 publication path currently makes an unmerged ticket invisible to the survey as a side effect of where artifacts are published; that is mechanics, not approval, and must not be described as approval anywhere. How queued tickets become claimable without waiting on a human merge (for example, publishing loose tickets direct to the base) is left open — this record is the ruling, not the design.
