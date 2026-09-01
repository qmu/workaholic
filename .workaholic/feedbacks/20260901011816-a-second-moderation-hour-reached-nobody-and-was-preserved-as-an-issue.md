---
type: Feedback
title: A second moderation hour reached nobody and was preserved as an issue
kind: insight
source: development
subject: observer_ai:moderate
created_at: 2026-09-01T01:18:16+00:00
author: a@qmu.jp
supersedes: 
---

# A second moderation hour reached nobody and was preserved as an issue

Source: https://github.com/qmu/workaholic/issues/810

The `/moderate` tick at `20260901-005151` rendered its hourly root (`post: true`, reason `ready` — 4 changes, 5 questions, 3 impaired steps, previous tick `20260831-235117`) and no transport could reach the loop's channel, so the tick filed the rendered root as one `[FB]` issue, verbatim, rather than losing the hour with its container. Both transports were named as out: the Slack connector answered `channel_not_found` — `slack_search_channels` returned no `dev-workaholic`, and a direct read of the recorded coordinate channel `C0BLL9J7FMY` answered the same, so the connector is authenticated against a workspace that holds none of the loop's channels — and `notify-slack.sh` answered `no_token`, with `WORKAHOLIC_INBOUND_SLACK_CHANNEL=dev-workaholic` set, so the channel resolved and only the credential is missing. This is the second consecutive hour of the same condition; the first is recorded at `20260901002017-the-moderation-tick-has-no-slack-transport-that-reaches-the-loop-s-channel.md`. The cost this hour: five questions reached nobody — `raced-unit:` and `stranded-unit:make-workaholify-converge-the-account-s-routines`, `operator-pull:786`, `stranded-publication:622`, and `catchup-blocked:say-when-the-check-in-queue-is-stuck-and-bound-the-hold`, all resolving to `a@qmu.jp` — with the ledger untouched, so none was recorded as asked and each is offered again the moment a transport returns; 13 further questions stay held from earlier ticks; and 8 outstanding questions have answers this tick could not read (all 8 coordinates in `C0BLL9J7FMY`, `thread_unreadable:channel_not_found`), so a person who has already replied has not been heard.

The ask states its own scope: the repair is provisioning rather than code, https://github.com/qmu/workaholic/issues/806 already carries that request, and this issue exists to preserve the hour's content rather than to duplicate it. It asks this repository for no work of its own, and the mechanism it exercises is the one that landed as issue #807 (a tick whose rendered post says *post* and whose every transport is out files the root as one `[FB]` issue), working as designed. Two standing rulings bound what could be proposed against it in any case: the operator rejected provisioning a Slack bot identity — "Do not re-propose a bot identity, an app token, or any Slack-side credential until the operator says otherwise" (`20260831221757-the-operator-rejects-provisioning-a-slack-bot-identity.md`) — and on #806 the operator ruled directly that the issue stays open because the repair is theirs, not the loop's.
