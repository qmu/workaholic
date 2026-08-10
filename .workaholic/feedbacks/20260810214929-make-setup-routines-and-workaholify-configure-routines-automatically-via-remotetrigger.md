---
type: Feedback
title: Make setup-routines and workaholify configure routines automatically via RemoteTrigger
kind: instruction
source: discussion
created_at: 2026-08-10T21:49:29+09:00
author: a@qmu.jp
supersedes: 
---

# Make setup-routines and workaholify configure routines automatically via RemoteTrigger

The `/setup-routines` and `/workaholify` commands must configure the repository's routines automatically instead of rendering copy-paste setup sheets. The "manages nothing" ruling (2026-08-06, re-verified 2026-08-10 in ticket `20260810085351`) rested on the finding that no `RemoteTrigger`-family tool is exposed to a session — that finding is now stale for the session class that matters: a developer's interactive Claude Code session exposes a `RemoteTrigger` tool (list/get/create/update/run, plus `create_webhook_trigger`), and on 2026-08-10 it listed this repository's two routines, revealed that both had an empty `cron_expression` (the sheet-only approach had no way to see this — the fleet sat unscheduled and nothing fired), and successfully wrote schedules onto both. The commands should therefore read the account's routines, diff them against the templates, and apply name/prompt/model/schedule/connector wiring directly, keeping the sheet only as the fallback for session classes without the tool. Two API facts the templates must also absorb: the minimum schedule interval is one hour, so the templates' `cron_expression: 0,30 * * * *` is unrealizable and should become an hourly pair (measured: `[Propose]` at :15, `[Implement]` at :30), and a `:00` minute is silently rewritten to a server-chosen jitter minute, so an explicit non-zero minute is what actually sticks.
