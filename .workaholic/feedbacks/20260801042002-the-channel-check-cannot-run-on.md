---
type: Feedback
title: The channel check cannot run on a locked credential store
kind: concern
source: development
created_at: 2026-08-01T04:20:02+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-channel-check-cannot-run-on
owner: 
mission: []
tickets: [20260801030421-workaholify-provisions-the-loop-engineering-environment.md]
origin_pr: 138
origin_pr_url: https://github.com/qmu/workaholic/pull/138
origin_branch: work-20260801-033154
origin_commit: 2c2db915
last_seen: 2026-08-01T04:20:02+09:00
---

# The channel check cannot run on a locked credential store

## Description

`check-slack-channel.sh` returns `checked: false, reason: "slack_locked"` whenever qfs's store is locked — which is every non-interactive session, and any interactive one where the developer has not run `qfs auth`. The precondition is therefore unverified in exactly the automated contexts where a mistake would go unnoticed.

## How to Fix

Correct as-is: reporting honestly beats guessing, and the check is advisory by design. If channel verification becomes load-bearing, the fix is a check that does not depend on the developer's local credential store — reading the channel through the same Slack connector the routines already use.
