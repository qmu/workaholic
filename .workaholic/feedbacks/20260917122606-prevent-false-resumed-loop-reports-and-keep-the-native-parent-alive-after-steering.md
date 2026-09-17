---
type: Feedback
title: Prevent false resumed-loop reports and keep the native parent alive after steering
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-17T12:26:06+09:00
author: a@qmu.jp
supersedes: 
---

# Prevent false resumed-loop reports and keep the native parent alive after steering

kind: instruction / source: discussion / subject: person:tamurayoshiya

# Prevent false resumed-loop reports and keep the native parent alive

The user repeatedly requested feedback to Workaholic followed by resuming work. Despite #1147 and #1151 being closed, the Codex parent repeatedly answered that the loop was resumed, emitted a final response, and stopped observing. A worker could continue and even finish while the parent no longer read Slack or reconciled its result. The coordinator's persisted control was running while the host goal was paused. Even after reading that paused state, the agent ended its response again and transferred the restart burden to the user instead of sustaining its available interruptible native parent. The user explicitly asks that this false reporting stop. Make resume claims require actual continuation evidence, distinguish worker liveness from coordinator observation, and keep ordinary steering/status replies in commentary followed by the next observation. Do not treat a running state file or a launched worker as proof of continuous monitoring. Cover the regression where the host goal is paused but native tools can continue: the parent must process the comment, wait interruptibly, observe again, and consume the child's terminal result without requiring another user message. If no continuation mechanism really exists, report that precise limitation without saying work has resumed. Preserve the existing anchor and active work; no duplicate loop or direct commits to main.


Source: https://github.com/qmu/workaholic/issues/1156
