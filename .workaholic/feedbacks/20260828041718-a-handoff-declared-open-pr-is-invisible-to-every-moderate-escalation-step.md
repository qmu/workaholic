---
type: Feedback
title: A handoff-declared open PR is invisible to every moderate escalation step
kind: instruction
source: slack
subject: person:a@qmu.jp
created_at: 2026-08-28T04:17:18+00:00
author: a@qmu.jp
supersedes: 
---

# A handoff-declared open PR is invisible to every moderate escalation step

# A handoff-declared open PR is invisible to every moderate escalation step

Measured 2026-08-27/28 on a repository running the loop.

A unit `/drive` classified as a declared handoff opened its pull request and posted the
🟡 Handoff line as a threaded reply under the mission's FB root — correct per the notify
model, but invisible at channel level. The operator judgement it asked for then went
unanswered for a full day, and the hourly `/moderate` ticks never surfaced it. The tick
logs show this was not a miss but the rules composing into a blind spot:

- `unanswered-asks` counts only human-authored channel messages, so the loop's own Handoff
  post is never a candidate ("it is the loop's own post and is never a candidate by this
  step's own rule").
- `stuck-prs` fires only on a conflict or a failing check; the PR was clean, and one tick
  recorded: "its body is an explicit handoff waiting on the developer: no step of this tick
  returned it, and this tick asks only about what its steps read."
- `stalled-units` keys on a 24h last-commit staleness threshold, and an hourly keep-fresh
  session (merging the base into the branch and pushing) reset that clock every hour — the
  mechanism keeping the PR mergeable is also what keeps it invisible.

Net effect: the healthier the loop keeps a handoff PR, the less likely a human ever hears
about it again. The operator found it a day later by accident, while reviewing unrelated
routine state.

Ask: give the moderation tick a step that reads the open pull requests' handoff state
directly — `declared_handoff` on the claim, or the `## Handoff` section in the PR body —
and asks the operator through the existing ask-once/quiet-hours ledger until the handoff is
answered, regardless of clean mergeability and fresh commits. A declared handoff is by
definition waiting on a person; clean and fresh are exactly the states it will sit in
forever.

Source: https://github.com/qmu/workaholic/issues/674
