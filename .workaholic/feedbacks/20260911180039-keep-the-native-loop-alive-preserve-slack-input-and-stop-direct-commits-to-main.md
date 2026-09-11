---
type: Feedback
title: Keep the native loop alive, preserve Slack input, and stop direct commits to main
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-11T18:00:39+09:00
author: a@qmu.jp
supersedes: 
---

# Keep the native loop alive, preserve Slack input, and stop direct commits to main

Source: https://github.com/qmu/workaholic/issues/1151

The operator reports three failures observed on one native work session and asks for three
repairs, each with regression coverage. It is related to issue #1147 (record
`20260911142410-resume-the-native-work-loop-after-ordinary-mid-loop-comments.md`, landed
through pull request #1150), and asks for more than that record did: a continuation
mechanism rather than a state word, an observation failure path that never becomes a cursor
gap, and a gate that keeps the loop's own bookkeeping off `main`.

The ask, in the operator's own words:

> A native work session reported that it had returned to the loop, but then emitted a final
> response and ceased observing even though the durable coordinator record still said
> `running`. After the next manual resumption, the Slack adapter returned
> `observation_proved:false` with an unreadable source while a new human-authored channel root
> already existed. The session nevertheless described the channel as quiet and only found the
> message after the human supplied its exact permalink. This demonstrates that coordinator
> state is being reported as liveness without an actual continuation mechanism, and that an
> unknown Slack read can still become an effective cursor gap.
>
> Related to #1147, but this also needs the observation failure path fixed. An ordinary
> mid-loop comment must return to an interruptible parent or establish a same-chat scheduled
> continuation before any response ends the turn. A `running` state alone must never be called
> a resumed loop. When Slack observation is unproved or unreadable, do not classify it as
> quiet, do not advance beyond the unread interval, and keep retrying independently; a later
> direct read must overlap the unproved interval. Add regression coverage in which a human
> root exists during an unproved observation and prove it is captured and acknowledged without
> the human having to paste a permalink.
>
> The same run history also shows excessive direct writes to `main`. In a bounded
> first-parent window, 335 commits have `Log ... tick` subjects and nine have `Record the
> tick's feedback findings` subjects; a recent deferred-concern commit was verified to have no
> associated pull request. Runtime cadence logs and unattended maintenance records must not
> update the base branch directly. Keep ephemeral loop state outside git, and route durable
> repository artifacts through a claim or publish branch and pull request with the normal
> checks. Add a base-ref write gate and regression tests proving that Propose, Moderate,
> notification, and finish-log paths cannot commit or push directly to `main`.

Three repairs are named, in the operator's order: (1) a mid-loop comment returns to an
interruptible parent or establishes a same-chat scheduled continuation before any response
ends the turn, and `running` alone is never called a resumed loop; (2) an unproved or
unreadable Slack observation is never classified as quiet, never advances the cursor past the
unread interval, keeps retrying on its own, and a later direct read overlaps the unproved
interval — proved by a regression in which a human root exists during an unproved observation
and is captured without a pasted permalink; (3) a base-ref write gate with regression tests
proving the Propose, Moderate, notification and finish-log paths cannot commit or push
directly to `main`, with ephemeral loop state kept out of git and durable artifacts routed
through a claim or publish branch and pull request.
