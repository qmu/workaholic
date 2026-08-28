---
type: Feedback
title: Let the moderation tick reconcile a thread's last status with the unit's real state
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-28T06:17:24+00:00
author: a@qmu.jp
supersedes: 
---

# Let the moderation tick reconcile a thread's last status with the unit's real state

Source: https://github.com/qmu/workaholic/issues/679

Companion to #674, measured the same day (2026-08-28), and the same event seen from the other side.

An operator hand-finished several handed-off units — merged the pull requests, executed the delegated decisions — outside the loop, in a terminal session. The finish lines never reached the channel, because the notify model posts a unit's single finish line only from the run that finishes the unit; a manual takeover bypasses that seam. Every affected feedback thread kept 🟡 Handoff as its last word while the work was long merged, and the operator's question was the measurement: "why can't I tell from the thread that it's done? there's no Implemented comment."

Ask: give the moderation tick a reconciliation step that closes the announcement loop when reality moved outside it. For each feedback thread whose latest status reply is 🔵 Proposed or 🟡 Handoff, read the named pull request's actual state; when the two disagree — merged with no 🟢 reply, or closed unmerged with no closing word — post the missing finish reply into that same thread through the existing exact-token lookup, marked as the tick's reconciliation rather than the run's own line (e.g. `🟢 Implemented - [#N Title](pr-url)` plus one sentence naming that it was merged outside the loop, by whom and when, per the merge commit). Idempotence comes free: the step reads the thread before writing, so "never re-announce a merge the channel already carries" is satisfied by construction, and a thread already carrying its finish is never touched.

Together with #674 this makes the pair symmetric: #674 asks the tick to keep escalating a handoff that is still waiting; this asks it to say so when the handoff was answered somewhere the loop could not see.
