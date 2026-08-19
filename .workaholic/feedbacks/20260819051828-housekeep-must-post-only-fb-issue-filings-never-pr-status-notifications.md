---
type: Feedback
title: Housekeep must post only FB issue filings, never PR-status notifications
kind: instruction
source: discussion
subject: other:claude[bot] relayed ask
created_at: 2026-08-19T05:18:28+00:00
author: a@qmu.jp
supersedes: 
---

# Housekeep must post only FB issue filings, never PR-status notifications

# Housekeep must post only [FB] issue filings, never PR-status notifications

The Housekeep routine's sole responsibility should be filing "[FB] ***" issues. It is
currently also posting PR-related status and decision notifications into Slack — for
example "Needs a decision - N pull request(s) conflicting with main" and other
merge-readiness notices. That responsibility belongs to the Propose routine, not
Housekeep. Requested fix: correct the Housekeep routine so that it only ever emits
"[FB] ***" issue filings and never posts PR-status, merge-conflict, or merge-readiness
notifications; any such PR-status/decision messaging should instead be handled by the
Propose routine.

Source: https://github.com/qmu/workaholic/issues/525
