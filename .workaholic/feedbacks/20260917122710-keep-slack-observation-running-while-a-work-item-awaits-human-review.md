---
type: Feedback
title: Keep Slack observation running while a work item awaits human review
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-17T12:27:10+09:00
author: a@qmu.jp
supersedes: 
---

# Keep Slack observation running while a work item awaits human review

kind: instruction
source: discussion
subject: person:operator

# Keep the coordinator observing while a work item awaits human review

The operator reports that a review wait must not stop the work loop: they were already commenting in Slack, but the coordinator did not read those comments until they explicitly resumed it. Keep Slack and assigned-issue observation, replies, and independent work running while only the dependent implementation waits. A task-level need for clarification or review is not an operator request to pause the coordinator.

Observed with Workaholic 1.0.351: the agent published documentation, decided that downstream implementation needed interpretation review, emitted `hold` with `explicit:true`, and ended its turn with the prescribed resume question. The coordinator returned `control:held`, `resumed:false`, `resumed_reason:held`, with no live children. Human Slack corrections then accumulated and were discovered on the next explicit resume. This was an agent decision error, not a Slack read rejection. The hold was initiated by the agent; the operator had not asked to stop observation.

The installed `skills/work/SKILL.md`, `skills/runtime/reference/native-loop.md`, and `commands/infinite-development.md` prescribe persisting global hold for a review-required handoff and waiting for an explicit resume. `skills/work/scripts/final-response-contract.sh` also requires a persisted hold for `review_required`. These instructions encouraged the incorrect promotion of one dependency wait into global suspension, despite the work model having independent observation and work clocks.

Please distinguish task review/dependency waits from explicit operator hold. During task review, preserve the same coordinator instance and startup anchor, keep inbound observation and unrelated work active, and consume the answer from the original Slack thread without requiring a separate resume command. Global hold should remain available for an actual operator instruction to pause the loop. Validate the sequence: a dependent unit awaits review; a human replies in its Slack thread; the coordinator reads and acknowledges it and makes that unit eligible when the reply resolves its prerequisite, while independent work continues. Also verify that an explicit operator hold is still honored and timers cannot resume it.


Source: https://github.com/qmu/workaholic/issues/1157
