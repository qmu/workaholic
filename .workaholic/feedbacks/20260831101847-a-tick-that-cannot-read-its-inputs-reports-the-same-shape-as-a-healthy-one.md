---
type: Feedback
title: A tick that cannot read its inputs reports the same shape as a healthy one
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-31T10:18:47+00:00
author: a@qmu.jp
supersedes: 
---

# A tick that cannot read its inputs reports the same shape as a healthy one

Source: https://github.com/qmu/workaholic/issues/759

Measured over 106 ticks in five days on a consuming repository. Six of the twenty-nine
steps returned `degraded` in nearly every tick: `base-health` (`tip_session_refused`),
`merge-conflicts` and `stuck-prs` ("pull requests unreadable"), `direction-health`
(`inbox_unreadable`), `strategy-pace`, and `thread-reconcile`. On the last full day, 24
of 25 ticks were in that state.

The rendered post carries only `N change(s), M question(s)`. A tick where six steps saw
nothing is therefore byte-identical, to the operator, to a tick where everything was
read and everything was fine. `base-health` writes "a red base is indistinguishable from
a green one this tick" into the tick log, which is exactly right — and that sentence
never leaves the log.

The operator found out four days later, by asking. Please make the post name the
degraded steps, so an impaired tick cannot read as a quiet one. This is the same class
as the standing ruling that a disabled routine must never read as a converged one, and
it wants the same answer: report the impairment by name, every tick, until it clears.
