---
type: Feedback
title: Move workaholify Proposal and Implement steps to a fixed interval loop instead of immediate webhook triggers
kind: instruction
source: slack
created_at: 2026-08-10T08:50:32+00:00
author: a@qmu.jp
supersedes: 
---

# Move workaholify Proposal and Implement steps to a fixed interval loop instead of immediate webhook triggers

Previously, the expectation was that creating a GitHub Issue would immediately trigger a webhook-driven Claude Code routine with no time lag.

Returning to the core concept of "loop engineering," this should not be built as a conventional immediate-response development pipeline. Even without immediacy, the experimental, loop-based cadence matters more right now than instant reaction — it is what produces the developer experience and feedback the team wants.

Requested changes:
- Revise the /workaholify command so it no longer relies on immediate webhook-triggered execution for the Proposal and Implement steps.
- Revive /set-routines.
- Schedule the current Proposal and Implement steps to run on a fixed interval instead of firing immediately — e.g. every 30 minutes, at :00 and :30.

Source: GitHub issue #336 (https://github.com/qmu/workaholic/issues/336), filed from a Slack request.
