---
type: Feedback
title: A running work loop must not stop after an ordinary progress report
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-26T17:47:13+09:00
author: a@qmu.jp
supersedes: 
review_surface: 
---

# A running work loop must not stop after an ordinary progress report

Source: https://github.com/qmu/workaholic/issues/1267

# A running work loop must not stop after an ordinary progress report

The operator has repeatedly instructed that an active work loop continue observing and advancing accepted work without stopping. In an `interruptible_parent` run, the coordinator persisted `control: running` and a future `next_due`, but the parent turn ended after an ordinary progress response and no later tick occurred until the operator explicitly prompted it again. Treat a normal progress response as a yield within the same active loop, not as completion: schedule or resume the next observation tick automatically while the coordinator remains running, and reserve termination for an explicit pause, a completed objective, or a genuinely blocked state under the loop contract.
