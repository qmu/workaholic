---
type: Feedback
title: Throttle repeat drive-blocked notifications for the same unresolved condition
kind: instruction
source: slack
created_at: 2026-08-02T14:03:23+00:00
author: a@qmu.jp
supersedes: 
---

# Throttle repeat drive-blocked notifications for the same unresolved condition

The hourly drive automation re-posts a "drive blocked" failure notification to Slack every single time it runs, even when the failure is a repeat of the exact same already-known condition — a series of near-identical red-circle alerts in #dev-workaholic, one per hour, with no new information in each successive message. Because the automation has no notion of "this is the same failure as last time," it treats each hourly tick as a brand-new event, which produces notification spam for what is, from the user's perspective, a single ongoing unresolved issue. The ask is for the alerting behavior to recognize when a recurring automated check fails with the same root cause as its immediately preceding failure(s) and to de-duplicate or throttle in that case: notify once when the condition first appears, then suppress or reduce repeat notifications for the same unresolved condition, alerting again only if the condition changes or a cool-down window elapses. Deliberately scoped to the notification behavior itself, not to fixing the underlying trigger (the cloud container image bundling a stale workaholic plugin — v1.0.112 against the repository's v1.0.118 — whose dirty-tree precondition failure is what fires every hour); that root cause is a separate concern. Reported as qmu/workaholic#168.
