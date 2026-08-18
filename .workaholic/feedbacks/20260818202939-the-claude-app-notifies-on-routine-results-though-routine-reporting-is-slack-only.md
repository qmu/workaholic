---
type: Feedback
title: The Claude app notifies on routine results though routine reporting is Slack-only
kind: instruction
source: slack
subject: person:tamurayoshiya
created_at: 2026-08-18T20:29:39+00:00
author: a@qmu.jp
supersedes: 
---

# The Claude app notifies on routine results though routine reporting is Slack-only

Source: https://github.com/qmu/workaholic/issues/514

The developer, in #dev-workaholic (original in Japanese): routines are supposed to be
configured with notifications OFF, yet the Claude app keeps sending its own notifications
of routine results. The timing and content of what should be reported is already woven
into each routine's instruction and is meant to be received in Slack, so the Claude app
has no need to notify at all. Investigate the cause and prevent it.

The developer explicitly declined an answer in the thread and asked for the ask to be
filed as feedback instead — this record is that filing, not a reply.

Investigation already carried out on the affected account, recorded so whoever picks
this up does not repeat it:

- Listing the account's routines (completed ones included) showed the routines involved
  are one-shot, `send_later`-style check-ins bound directly to a persistent Claude
  session (they carry a `persistent_session_id` rather than spawning a fresh session per
  fire), and have already fired.
- Per the routine-management tool's own documentation, the `notifications` field — which
  controls push/email completion notifications — is only meaningful, and only accepted,
  for fresh-session-per-fire routines (`create_new_session_on_fire=true`). For
  self-bound / persistent-session routines the server rejects the parameter outright.
- So none of the routines inspected exposed a `notifications` setting that could have
  been misconfigured. There is currently no known routine-level "notifications off"
  control for persistent-session-bound routines, yet the notifications still arrive.

Working hypothesis stated with the ask: the notification probably does not originate
from the per-routine `notifications` field at all, since that field is not even
available for this routine type. It may come from another layer — a client/app-level
notification setting, or a notification path tied specifically to persistent-session
routine fires that has no exposed opt-out. The fix likely needs either a way to disable
notifications for persistent-session routines, or a correction to whatever default
causes the app to notify when the routine's design assumes Slack is the sole channel.
