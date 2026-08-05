---
type: Feedback
title: The [Propose] thread-reply fix is merged; only the live routine refresh is left
kind: instruction
source: slack
created_at: 2026-08-05T12:34:52+00:00
author: noreply@anthropic.com
supersedes: 20260805062035-refreshing-the-live-propose-routine-is-premature-its-template-fix-is-still-a-queued-ticket.md
---

# The [Propose] thread-reply fix is merged; only the live routine refresh is left

Reported by tamura_yoshiya in #dev-workaholic and filed as GitHub issue #254 on qmu/workaholic: the `[Propose]` routine still announces its pull request as a fresh top-level Slack message instead of replying into the thread that triggered it, seen again on 2026-08-05 after the same complaint earlier that day. The ask is that a routine triggered by a message living inside an existing thread reply into that thread — explicitly including the case where no `fb:`-keyed record exists yet, since the routine mints that key itself and a search for it can never find the requester's own message.

That behavior is already written and merged. Commit `0bbec3e` ("Reply in the trigger message's own thread") added Case 1 to the `workaholify` SKILL's *One thread per feedback item* — reply into the session's own trigger message when it can be identified, ahead of the `fb:<stem>` search and the new-root fallback — and rewrote the `[Propose]` template's Slack step to route by those three ordered cases, noting that a Slack report is exactly Case 1 and that its message predates the key. The ticket behind it, `20260805021451-reply-in-the-trigger-message-s-thread-not-a-new-root.md`, is archived under `work-20260805-180653`, and the record the issue restates, `20260805021414`, is already carried in that ticket's `feedback:` refs.

What the report is actually observing is the rollout, not the fix: the live routine in the account still runs the pre-fix prompt. The session that received this issue is direct evidence — its own stored instruction reads "Post the thread root to Slack channel `dev-[repo name]` ... as a top-level message", with no three-ordered-cases routing and no `<@U…>` mention token, both of which the current template carries. Refreshing a live routine is a human act by design: `/setup-routines` confirms each one verbatim, one at a time, and `authorize-routine-change.sh` refuses a headless context outright, so no unattended run can perform it and no ticket written for it would be driveable.

This supersedes `20260805062035`, whose conclusion was that refreshing the live routine was premature because its template fix was still an undriven ticket. That held when it was written at 06:20 and stopped holding when the ticket was driven later the same day; the refresh is now due rather than premature, and it is the whole of the remaining work.
