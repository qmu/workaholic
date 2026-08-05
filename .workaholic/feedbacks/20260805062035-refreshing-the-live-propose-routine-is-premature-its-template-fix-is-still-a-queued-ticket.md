---
type: Feedback
title: Refreshing the live [Propose] routine is premature — its template fix is still a queued ticket
kind: instruction
source: slack
created_at: 2026-08-05T06:20:35+00:00
author: noreply@anthropic.com
supersedes: 
---

# Refreshing the live [Propose] routine is premature — its template fix is still a queued ticket

The reported ask, filed as GitHub issue #247 on qmu/workaholic, is that this repository's live `[Propose]` routine still posts its announcement as a brand-new top-level Slack message instead of replying into the thread that triggered it — observed when the routine announced pull request #246 as a fresh root rather than in the developer's own thread. The ask has two parts: refresh the live routine through `/setup-routines` so it picks up the current template, and, separately, evaluate whether a feedback record should carry the originating Slack thread's permalink as an explicit field so a routine has a robust way to find the thread to reply into.

The first part rests on a premise that does not hold. It reads pull request #241 as having landed the fix, but #241 merged a *proposal*, not an implementation: what reached `main` was the feedback record and the ticket `20260805021451-reply-in-the-trigger-message-s-thread-not-a-new-root.md`, which is still sitting undriven in `.workaholic/tickets/todo/a-qmu-jp/`. The template that ticket targets, `plugins/workaholic/skills/workaholify/routines/fb.md`, still instructs an unconditional top-level post at line 48. Refreshing the live routine today would therefore reinstall exactly the behavior the report is about. The routine run that produced this record is itself executing the un-refreshed prompt, which is corroboration rather than coincidence: its own Slack instruction still reads "as a top-level message".

The correct sequence is that the queued ticket is driven first and the rollout follows as a separate human act. That ticket already says so — it scopes the rollout out explicitly, and notes that an unattended run cannot perform it at all, since `/setup-routines` confirms each routine verbatim one at a time and `authorize-routine-change.sh` refuses a headless context. So this record queues no new work: the work exists, and what was missing was the ordering between it and the rollout.

The second part is a design input to that same ticket rather than separate work. The ticket deliberately leaves the identification mechanism open — how a session identifies its triggering message is left to the implementer, with the routine's own trigger payload named as the natural source — and carrying the originating thread's permalink on the record is one concrete answer to that question. It is worth weighing when the ticket is driven, against the ticket's own caution that where no reliable identification exists the correct outcome is the unchanged `fb:<stem>` key search, because matching by recency or message content would thread unrelated items together — a worse failure than a second root.
