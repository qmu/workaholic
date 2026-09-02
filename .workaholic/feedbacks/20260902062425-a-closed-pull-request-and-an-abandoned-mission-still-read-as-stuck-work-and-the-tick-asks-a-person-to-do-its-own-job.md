---
type: Feedback
title: A closed pull request and an abandoned mission still read as stuck work, and the tick asks a person to do its own job
kind: instruction
source: slack
subject: person:a@qmu.jp
created_at: 2026-09-02T06:24:25+00:00
author: a@qmu.jp
supersedes: 
---

# A closed pull request and an abandoned mission still read as stuck work, and the tick asks a person to do its own job

Source: https://github.com/qmu/workaholic/issues/881

The operator reports no improvement after the earlier instruction (issue #861) that the
moderation tick must resolve conflicts and merge rather than defer to a claim holder.
This afternoon's tick posted the same shape again: a hundred-odd files conflict on a
finished unit, "decide which content to keep and resolve it yourself; the loop will not
merge, rebase or touch the claim".

Worse, the pull request it points at had been closed by the operator hours earlier and
the mission behind it closed as abandoned; the tick read neither, and the stale claim
branch behind the closed pull request went on being reported as stuck work every hour
until the operator's assistant deleted the branch by hand.

The instruction, restated with the new defect added:

1. A conflicted finished unit is the tick's to catch up and merge.
2. A claim whose pull request is closed, or whose mission is no longer active, is
   retired by the tick — the branch deleted and the claim released — never reported as
   stuck work.
3. A question that asks a person to do the tick's own job is not a question the tick
   may post.

The operator calls the current behaviour useless.
