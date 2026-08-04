---
type: Feedback
title: Make /workaholify record the FB-to-merge lifecycle as one semantic Slack thread
kind: instruction
source: slack
created_at: 2026-08-04T10:18:47+00:00
author: a@qmu.jp
supersedes: 
---

# Make /workaholify record the FB-to-merge lifecycle as one semantic Slack thread

Update the /workaholify routine templates to record a feedback item's whole life - from the original ask through to merge - as ONE semantic Slack thread, replacing the current per-step, non-semantic "PR opened" / "PR merged" posts that carry no meaning and thread to nothing.

The illustrated flow, in the reporter's own terms:

- The developer mentions Claude with an FB ask. Claude creates the FB issue **without asking permission**, and only asks for confirmation when it is genuinely necessary.
- The Claude Code web routine triggered by that FB issue's creation posts "Proposed to @developer" (green circle) as the **thread root**, having opened a pull request whose title carries a "[Proposal]" prefix - or "[提案]" in Japanese - so the developer can see at a glance that the PR contains design only, not implementation.
- The developer reviews the proposal in that pull request and asks for merge (or changes) **inside that same "Proposed" thread**.
- After merge the developer is notified "Proposal merged by @developer" (purple circle) **in the same thread**, not as a new top-level post.
- [Drive] also notifies into that thread. Because one proposal can cover more work than a single drivable unit, the proposal needs splitting by drivable unit - and the FB itself is possibly better split for the same reason.
- When a drive completes, the thread receives exactly one of: "Merge Requested for @developer" (green circle); "Merged by @developer" (purple circle), where the developer mentions Claude in the thread to carry the merge out; "Auto Merge by Claude" (rocket), only when the FB asked for that; or "Handoff @developer" (yellow circle).

Notes from the reporter:

- Every such notification must include the **session URL of the Claude Code web routine session that opened the PR**, so the developer can jump straight from Slack into that session.
- No more non-semantic "PR opened" (green circle) and "PR merged" (purple circle) posts from the routines.

Scope: this changes /workaholify's notification and threading behavior only. It does not change how drive or survey picks or implements work.

Reported as qmu/workaholic#192.
