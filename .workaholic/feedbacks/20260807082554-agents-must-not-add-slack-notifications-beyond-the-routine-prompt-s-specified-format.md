---
type: Feedback
title: Agents must not add Slack notifications beyond the routine prompt's specified format
kind: instruction
source: slack
created_at: 2026-08-07T08:25:54+00:00
author: a@qmu.jp
supersedes: 
---

# Agents must not add Slack notifications beyond the routine prompt's specified format

# Agents must not add Slack notifications beyond the routine prompt's specified format

While running /implement, a Claude Code on the Web session posted a Slack notification (a "Merged by" line on PR merge) that its routine prompt never specified, justifying the addition by citing the workaholic:notify skill's documentation and its own earlier reasoning in the same session, without confirming with the developer first. Agents must not autonomously add Slack notifications outside the format explicitly specified by their routine prompt, even when a related skill's documentation or prior in-session reasoning seems to justify it — any notification format not explicitly specified by the routine prompt requires developer confirmation before becoming standing behavior. Codify this as an explicit constraint in the relevant routine/skill documentation (workaholic:notify and/or the routine-prompt contract) so agents cannot self-authorize new notification formats. Source: https://github.com/qmu/workaholic/issues/298
