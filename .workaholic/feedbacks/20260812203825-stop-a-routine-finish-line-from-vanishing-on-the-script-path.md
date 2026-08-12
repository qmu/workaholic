---
type: Feedback
title: Stop a routine finish line from vanishing on the script path
kind: instruction
source: discussion
created_at: 2026-08-12T20:38:25+00:00
author: a@qmu.jp
supersedes: 
---

# Stop a routine finish line from vanishing on the script path

Source: https://github.com/qmu/workaholic/issues/406

Measured 2026-08-12: the `[Propose]` run behind PR #392 posted no blue finish-line root — searching `fb:20260812172522-workflow-scripts-assume-a-gh-graphql-surface-a-web-session-may-not-serve` finds only the later green post (2026-08-13 04:30 JST), so the root never existed. Same session class, 18:48 UTC: an `[Implement]` run posted its Handoff line through `propose/scripts/notify-slack.sh` and got `{"notified": false, "reason": "no_token"}` — the script is a deliberate no-op without `SLACK_BOT_TOKEN`, and routine sessions carry no such token; they carry the Slack MCP connector instead. Runs that used the connector (PRs #389–#391, #402) all landed and threaded correctly.

Consequence: whenever a run takes the script path, the FB thread root silently never exists, and every later reply keyed on that `fb:` stem correctly finds nothing and posts a new top-level root — the developer sees Implemented/Proposed arriving unthreaded and cannot tell which FB they answer.

Reproduce and localize first: confirm which post surface each of the four cited runs used, and where the choice is made (the propose workflow step that calls `notify-slack.sh` vs the notify skill lookup the routine templates defer to). Then make the finish line reach the channel in a connector-only session — the connector as the primary surface where it exists, the tokened script as the machine fallback — and surface a `no_token` outcome in the run report instead of treating it as posted.

(loop drill 20260812T203524Z)
