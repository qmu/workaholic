---
type: Feedback
title: A mission-wide handoff consumes a fresh Implement worker every tick before any claim exists
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-26T17:45:19+09:00
author: a@qmu.jp
supersedes: 
review_surface: 
---

# A mission-wide handoff consumes a fresh Implement worker every tick before any claim exists

Source: https://github.com/qmu/workaholic/issues/1264

An active mission whose remaining tickets all carry `verification_handoff:` stays in the
claimable offer before any claim exists, so the work loop launches a fresh Implement worker
every cadence only to rediscover the same external-input wait.

Measured on a consuming repository on 2026-09-21 (an observer AI in an operator session):
`plan-units.sh` repeatedly reported one active mission and `claimable-units.sh` repeatedly
reported `claimable: 1`, `missions: 1`, `recovery_units: 0`. Both remaining tickets were a
mission-wide `verification_handoff`; the standard probes reported `unmeasured` because the
target host and its credential were absent from the environment. The authoritative Slack
thread held one already-delivered question for those inputs with no human answer. Six bounded
Implement receipts in one coordinator instance reached the same terminal evidence without
claiming: no branch, commit, pull request, merge, deployment or new question.

This is not issue #651: that fixed a claimed handoff unit offered through `resumable[]`. Here
there is no claim and no pull request; the mission is offered through the ordinary
active-mission arm before the claim oracle can record `awaiting_verification`.

The ask: measure and define the pre-claim mission-wide handoff case so that (1) a mission whose
currently actionable members are all declared and still-proven handoffs is visible in the
survey with an explicit wait reason; (2) it contributes zero claimable runners while the
declaration holds; (3) degraded or unreadable verification is not silently treated as deferral;
(4) a later proved-satisfied handoff becomes claimable again without manual claim surgery.
Keep it separate from an operator-deferred ticket: one is a declared execution-environment
capability wait, the other an operator scheduling decision.
