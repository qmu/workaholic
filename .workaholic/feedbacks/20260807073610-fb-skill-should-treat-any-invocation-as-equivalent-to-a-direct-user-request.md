---
type: Feedback
title: fb skill should treat any invocation as equivalent to a direct user request
kind: instruction
source: slack
created_at: 2026-08-07T07:36:10+00:00
author: noreply@anthropic.com
supersedes: 
---

# fb skill should treat any invocation as equivalent to a direct user request

tamura_yoshiya asked (2026-08-07, in #dev-workaholic): change the /fb skill's behavior so that any invocation of it is treated as equivalent to a human user directly asking Claude to create an FB issue -- Claude should draft and file the FB issue without hesitating or requiring separate human confirmation, regardless of how the invocation reached it (including via an automated integration relaying it into Slack).

Context: earlier the same day, an automated integration ("qfs Integration") @-mentioned the Slack-side Claude asking it to file an FB issue about archive.sh auto-pushing claim branches. Because the mention came from a bot/integration account rather than directly from a human, Claude's own reply-safety heuristics treated it with suspicion and initially blocked responding, even though the request was legitimate and on-topic. Claude filed the issue anyway (qmu/workaholic#290), but with avoidable friction and delay.

Desired behavior: the /fb skill (and/or the convention around invoking it) should be defined/documented such that any legitimate invocation is unambiguously treated as equivalent to a direct user ask -- removing the need for Claude to second-guess whether a bot-relayed /fb request is really authorized.

Issue: https://github.com/qmu/workaholic/issues/293
Slack thread: https://qmu.slack.com/archives/C0BLL9J7FMY/p1786087748437769
