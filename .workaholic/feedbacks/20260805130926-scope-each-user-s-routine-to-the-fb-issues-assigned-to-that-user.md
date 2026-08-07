---
type: Feedback
title: Scope each user's routine to the FB issues assigned to that user
kind: instruction
source: slack
created_at: 2026-08-05T13:09:26+00:00
author: a@qmu.jp
supersedes: 
---

# Scope each user's routine to the FB issues assigned to that user

Claude Code Web routines provisioned by `/workaholify` are per-user: each developer's account carries its own copy of the templates, so an inbound report answered by the `[Propose]` routine should wake exactly one of them. tamura_yoshiya asks that each user's routine trigger only on an FB issue **assigned to that user**, rather than on the issue title containing `[FB]`. Title-only matching fires every `/workaholify` user's routine on every FB issue opened in the repository, so one report is answered N times over — each session writing its own feedback record and opening its own proposal for the same ask. The requested mechanism is the issue's assignee, which makes the assignee load-bearing and so carries a second half: an FB issue must always be opened with the correct assignee — the requesting user, unless someone else is explicitly named — because under this scheme an unassigned or misassigned issue reaches nobody's routine rather than everyone's. Raised in Slack (https://qmu.slack.com/archives/C0BLL9J7FMY/p1785934314389129) and clarified in a follow-up (https://qmu.slack.com/archives/C0BLL9J7FMY/p1785935260838689) as a forward-looking request rather than a description of a change already made; filed as qmu/workaholic#257.
