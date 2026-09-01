---
type: Feedback
title: A fifth moderation hour reached nobody and its held questions went stale
kind: insight
source: development
subject: observer_ai:tamurayoshiya
created_at: 2026-09-01T04:26:23+00:00
author: a@qmu.jp
supersedes: 
---

# A fifth moderation hour reached nobody and its held questions went stale

Source: https://github.com/qmu/workaholic/issues/818

The `20260901-035125` moderation tick rendered its hourly root — 8 change lines, 3 impairment lines, 5 questions, and the JST-morning per-strategy digest that would have led it — and no transport reached the loop's channel, so the tick filed the rendered root as one `[FB]` issue rather than losing the hour with its container. This is the **fifth consecutive hour** of the same condition (`20260831-235117`; `20260901-005151` → #810; `20260901-015055` → #812; `20260901-025208` → #815; and this one). The ledger is untouched: no question was recorded as asked, so all five stay held and are offered again the moment a transport returns.

Both transports were named as out, and this session reproduces both from an interactive container: the Slack connector is authenticated against a workspace holding none of the loop's channels (`slack_search_channels` for `dev-workaholic` across public and private returns no result), and `notify-slack.sh` answers `no_token`, with `WORKAHOLIC_INBOUND_SLACK_CHANNEL=dev-workaholic` set — so the channel resolves and only the credential is missing.

The cost this hour: the morning digest (140 commits, 1 strategy, 1 day past its target date) reached nobody; five questions reached nobody — `direction-overdue:an-autonomous-improvement-loop-run-by-the-routines`, `operator-pull:786`, `raced-unit:` and `stranded-unit:make-workaholify-converge-the-account-s-routines`, and `stranded-publication:622`, all addressed to `a@qmu.jp`; eighteen further questions stay held from earlier ticks; eight outstanding questions have answers this tick could not read (`thread_unreadable:channel_not_found` on all eight recorded coordinates), so a person who has already replied has still not been heard; `thread-reconcile` held five candidates; and `unanswered-asks` reached `channel_unreadable:channel_not_visible_to_connector`, never an honest quiet hour.

**This asks this repository for no work of its own, and the ask says so on its face**: "The repair is provisioning, not code — nothing here can be fixed by a change to this repository." https://github.com/qmu/workaholic/issues/806 already carries the request, and two standing rulings bound what could be proposed against it in any case: the operator rejected provisioning a Slack bot identity — "Do not re-propose a bot identity, an app token, or any Slack-side credential until the operator says otherwise" (`20260831221757-the-operator-rejects-provisioning-a-slack-bot-identity.md`) — and on #806 the operator ruled directly that the issue stays open because the repair is theirs, not the loop's. The mechanism this hour exercises, a tick filing its undeliverable root as one issue (issue #807), is working exactly as designed.

Two observations the hour records that are worth carrying forward, neither proposed as work here.

**Held questions go stale while they wait.** The tick names two of its own eighteen held keys as no longer describing a live condition: `base-red:96adf8ef…` — the base read green at `8147a091` that same tick — and `direction-dormant`, overtaken by `direction-overdue` on the same direction. `question-liveness.sh` re-derives liveness for a question already **asked**, before re-asking it; nothing stated here says the same re-derivation reaches a question that is merely **held**. A silence long enough to accumulate eighteen held questions is what makes the difference observable, and it will be observable again the next time a transport is out for hours. Whether that gap is real is a question for a discovery pass, not a conclusion this record draws.

**The compounding condition was repaired this hour.** Issue #812 was re-offered to this `[Specificate]` tick although pull request #813 already carried its record and `Closes #812`, because the discovery excludes only issues a record on the **base** names. That is now queued as its own ticket (`20260901042313-exclude-an-ask-whose-capture-waits-on-a-branch.md`, published on pull request #819), recorded at `20260901042106-a-captured-ask-is-re-offered-while-its-proposal-waits-on-a-branch.md`.
