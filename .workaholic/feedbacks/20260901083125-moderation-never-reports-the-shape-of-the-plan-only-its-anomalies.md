---
type: Feedback
title: Moderation never reports the shape of the plan, only its anomalies
kind: instruction
source: development
subject: person:the operator of a consuming repository
created_at: 2026-09-01T08:31:25+00:00
author: a@qmu.jp
supersedes: 
---

# Moderation never reports the shape of the plan, only its anomalies

The operator of a consuming repository had to ask, in the middle of a session, "so how many todos are left?" — and the answer was in no post the tick had made. Measured 2026-09-01 against plugin 1.0.266.

**Every step answers the same shape of question.** `strategy-pace` and `direction-health` read lifecycle and pace, `stalled-units` and `undrivable-units` count claims, `closable-missions` looks for a mission to close: what has gone stale, stuck or drifted. Not one of them says what is simply *there* — which live directions exist, which missions serve each, how many tickets are queued under each mission, and how far each has got. So the routine posts an hourly anomaly list against a plan the reader cannot see, and the ordinary question "how much is left" has to be asked of a person, who then reads it out of the bundle by hand.

Producing it by hand took four ad-hoc git commands over the bundle. On that repository it came out as: 3 active directions, all dated the same day six days out; 6 active missions; 30 queued tickets, distributed 8 / 7 / 7 / 6 / 1 / 1; acceptance progress 3/3, 2/3, and 0/3 on the remaining four. That is one table, cheap to compute, and it is the thing the operator actually wanted from a report called Moderation.

**The join is not merely unreported, it is unreadable.** A mission file carries no `strategy:` field. The relation runs `strategy.feedback[] ∩ artifact.feedback[]`, walked by `attributed-work.sh` — a set intersection with no surface anywhere, so a person opening a mission file cannot tell which direction it serves either. Any step that wants to report strategy → mission → ticket has to reconstruct it, which is presumably why no step does.

What is asked: add a step that posts a plan digest — per active direction, its target date and its missions; per mission, acceptance done/total and the count of queued tickets; and the total queued — and post it on the ordinary tick rather than only when something is wrong, because "nothing is wrong" and "here is where the work stands" are different reports and only the first exists today. And make the direction a readable field on the mission, so the chain can be read by a person as well as walked by a script.

Source: https://github.com/qmu/workaholic/issues/831
