---
type: Feedback
title: Scope the release-planning loop that decides what ships
kind: instruction
source: discussion
created_at: 2026-08-11T01:02:37+09:00
author: a@qmu.jp
supersedes: 
---

# Scope the release-planning loop that decides what ships

The release-planning loop is the second safety net behind the auto-merge policy (mission auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split). What "plan the release" means here: decide when to cut and what the batch is — read the merged-but-unreleased range on `main` (`git log <last release>..main`, the same range the release record derives), judge whether it is a coherent, shippable batch or should wait, draft the release note from the range, and cut the branch through the existing `cut-release-branch.sh` / `record-release-cut.sh` seam. It is NOT a new agent role bolted onto `/ship`: `/ship` §6 promotion confirmation stays exactly the evidence-gated act it is — planning selects and cuts, §6 proves. When it runs: on a slow clock (daily, or invoked), strictly after the QA loop's verdict on the same range. First-pass done: a session that reads the unreleased range, writes the plan (what ships, what waits, why) as the release note draft, and cuts the branch when the QA verdict passes — leaving promotion and confirmation to the existing `/ship` doctrine untouched.
