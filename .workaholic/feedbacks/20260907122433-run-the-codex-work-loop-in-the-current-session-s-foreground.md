---
type: Feedback
title: Run the Codex /work loop in the current session's foreground
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-07T12:24:33+09:00
author: a@qmu.jp
supersedes: 
---

# Run the Codex /work loop in the current session's foreground

# Run the Codex /work loop in the current session's foreground

Source: https://github.com/qmu/workaholic/issues/1070

## The ask, in the operator's own framing

When `/work` is run in Codex, the loop must keep running **in the foreground of that same
Codex session**. The `work` skill did not work well for the operator, so they instructed
Codex directly to check Slack every minute and reply to messages repeatedly within the
current session — and that worked. The observed behaviour is the requested behaviour:

- the session waits using `clock.sleep` and repeats **without ending the turn**;
- it reads Slack through **its own connector**;
- it reads a message's thread **before** replying, and avoids duplicate replies;
- it accepts **new instructions in the chat while the loop is running**.

It received and answered a test message, answered a request by checking the repository, and
responded to a subsequent thread reply. The trial used roughly 43–55-second interruptible
waits between tool calls, at a one-minute interval. It used **no** external supervisor, no
fresh `codex exec` session and no scheduled task.

The ask: keep the current session as the loop owner, honour the requested interval, and
continue until the user stops it.

**The operator states the trial's own bounds**: it demonstrates recurring in-session
operation, not a precise timing guarantee, and it covered Slack monitoring and replies —
not execution of the full development backlog.

## Why this warrants no new plan

This is the operator's **fourth** statement of one direction, and the plan it asks for
already exists. `20260906022552-report-each-tick-in-the-originating-codex-chat-and-prove-it-end-to-end.md`
(issue #989) is in the dedup set, and the mission it produced —
`.workaholic/missions/active/report-each-tick-in-the-originating-codex-chat/` — is active
with **seven queued tickets** whose `## Experience` covers this ask exactly:

> Started in a chat, the loop keeps its parent turn: it reports each tick there, answers a
> question mid-loop without cancelling it, delegates workers it does not wait for, and names
> each outcome once.

Every mechanism named above is already a queued ticket in that mission:

| What #1070 asks | The queued ticket that holds it |
| --------------- | ------------------------------- |
| the loop keeps the current session's turn | `20260906022855-run-the-tick-as-a-native-parent-that-keeps-its-turn.md` |
| interruptible waits, not a blocking sleep | the same ticket — waits of at most 60 seconds, shortened near a deadline |
| new instructions answered mid-loop | the same ticket — an early wake is not a tick boundary |
| choose this mode because the session can do it | `20260906022855-select-the-loop-mode-from-measured-capabilities.md` |
| the turn ends only on a stop | `20260906022855-reserve-the-final-response-for-a-stop-or-a-refusal.md` |
| workers dispatched, not awaited | `20260906022855-delegate-each-due-role-as-a-bounded-native-child.md` |
| do not silently keep the external supervisor | `20260906022855-retire-only-the-supervisor-the-native-mode-replaces.md` |
| the loop survives a long session | `20260906022855-carry-the-loop-state-across-context-compaction.md` |
| prove it in the operator's own chat | `20260906022907-prove-the-behaviour-in-the-operator-s-own-codex-chat.md` |

Emitting a second mission for this would be the duplicate-plan failure this repository has
measured before. The ask is not unplanned; it is **undriven**.

## What this record adds that the earlier ones do not

**The branch is no longer a hypothesis — the operator ran it.** Issue #989 derived the
native-parent branch from tool declarations, and the mission's own acceptance ticket says in
so many words that a documented tool capability is an implementation lead and never a
substitute for end-to-end evidence. This record carries the first **observed** run: a
one-minute in-session loop that read Slack through its own connector, read a thread before
replying, suppressed a duplicate, answered a repository question, and took new instructions
mid-loop, all without ending the turn.

That is a partial discharge of the mission's third acceptance item and it is bounded exactly
as the operator bounded it: it does **not** cover a delegated task outrunning ten minutes,
two successive tick reports arriving unprompted, or the development backlog running under
the loop. Those remain unproved.

## Why it has not been implemented — the reading, on 2026-09-07

The mission is **claimed, driven and reported**, on branch `work-20260906-023953`, with its
pull request open on the `handoff` route. The claim reads `awaiting_verification`, and
`declared_members` names exactly **one** ticket:
`20260906022907-prove-the-behaviour-in-the-operator-s-own-codex-chat.md`, whose
`verification_handoff` requires a live run in the operator's own Codex chat — an account,
app and conversation an unattended run does not have.

So the answer to *why has this not been implemented* is not that it was unplanned or
unnoticed. It is that the unit is parked behind one member's handoff while the other six
members — which declare nothing and need no operator — sit queued behind it.

**This is the shape the mission `hand-off-the-members-that-declare-and-drive-the-rest`
(archived achieved, 2026-09-07) was written to repair**: the handoff holds the members that
carry it, not the whole unit, and `awaiting_verification` requires *every* remaining queued
member to declare rather than any one. This claim predates that landing and still reads the
old way. Whether the repair reaches an already-standing claim is a question for the
executor's next pass and `/moderate`, not for this record — but it is named here because it
is the whole distance between the operator's ask and the work being done.

## The one term to check against the existing plan

The operator asks that the loop **honour the requested interval** (one minute in the trial).
`commands/work.md` invokes the loop at a fixed `5m` and takes no argument by design, and the
native-parent ticket computes boundaries from an interval without saying where that interval
comes from for this branch. This is a constraint on the existing plan rather than new work,
and the operator has already downgraded it themselves — the trial is offered as evidence of
recurring in-session operation, not as a timing guarantee.
