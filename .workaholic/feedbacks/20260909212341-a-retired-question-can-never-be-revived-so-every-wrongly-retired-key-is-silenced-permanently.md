---
type: Feedback
title: A retired question can never be revived, so every wrongly retired key is silenced permanently
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-09-09T21:23:41+09:00
author: a@qmu.jp
supersedes: 
---

# A retired question can never be revived, so every wrongly retired key is silenced permanently

Measured on moderation tick `20260909-120609`, on this checkout.

A third, distinct cause of the permanent silencing recorded in
`20260909181740-reconcile-questions-retires-a-live-question-because-the-registry-records-human-checkin-as-every-question-s-owning-step.md`
and
`20260909202412-question-liveness-retires-an-escalation-key-its-owning-step-can-never-name-as-a-string-node.md`.
Both of those name a reason a retirement fires **wrongly**. Neither names the fact that a
retirement, right or wrong, is **terminal**: nothing in the loop can return a retired key to the
candidate set, so every question either of those defects has already retired is silenced for the
life of the registry even after both are repaired.

## The mechanism

`question-registry.sh` accepts exactly five events — `list`, `register`, `asked`, `answer`,
`retire` — and none of them revives a retired key:

- `register` on an existing key merges only `step`, `coordinate` and `subject`
  (`.[$e.key] = ((.[$e.key] // {key,state:"candidate"}) + ($e|{step,coordinate,subject}|…))`).
  It never resets `state`, so a step re-registering its live candidate every tick leaves the
  retirement standing.
- `asked` refuses by name: `elif ($q[$e.key].state == "answered" or $q[$e.key].state ==
  "retired") then $q`.
- `answer` would overwrite the state, but it requires a person's words, and the whole point of
  the failure is that the question never reaches a person.

`ask-question.sh` therefore answers `{"ask":false,"reason":"premise_resolved","hold":false}` —
and `hold:false` is the load-bearing half: the question is not held for a later tick the way
`quiet_hours`, `off_day`, `tick_cap` and `day_cap` hold one. It is dropped, every tick, forever.

## Measured this tick

The registry (revision as read at 12:06 UTC) holds four keys. Three are `retired` while the step
that owns each one raised it as a live finding in the same run:

| Key | Registry state | What its owning step reported this tick |
| --- | --- | --- |
| `mission-leftovers:turn-quiescent-blockers-into-mature-decisions-and-resume-work` | `retired` | `closable-missions`: 1 mission at full acceptance with tickets still queued |
| `inbound-channel-unreadable:dev-workaholic` | `retired` | `unanswered-asks`: the channel was again not read (`operations_unsatisfied`) |
| `release-status-waiting` | `retired` | `release-status`: `blocked`/`waiting`, 2 targets — docs-site, marketplace |
| `direction-expiring:an-autonomous-improvement-loop-run-by-the-routines` | `candidate` | `direction-health`: expiring, 5 days to 2026-09-14 |

Each of the three was re-probed through `ask-question.sh` at the moment of this report and each
answered `premise_resolved` / `hold:false`. The fourth answered `ask:true`, which is what an
un-retired key looks like.

The three were retired for two different wrong reasons — the owning-step defect (`181740`) and
the string-node defect (`202412`) — and the registry now records the *correct* owning step for
all four, so the first defect's cause is already gone from the field it was about. The silence it
produced is not.

## Why this is not the same finding

Apply the repairs both earlier records name and re-run the loop: `question-liveness.sh` stops
answering `settled` for a step that hands the agent the reading, and `reconcile-questions.sh`
stops retiring on `settled` alone. Nothing retires wrongly again — and these three keys stay
retired, because no event returns them. The recorded repair set stops the bleeding and never
heals. That gap is what this record names.

The consequence is concrete on this repository right now. The mission
`turn-quiescent-blockers-into-mature-decisions-and-resume-work` stands at 3/3 acceptance with one
ticket still queued (`.workaholic/tickets/todo/20260908190000-reconcile-the-survey-s-observing-refusal-with-its-ladder.md`).
That leftover is what keeps the single active direction refused `work_waiting`, which is why
`/propose` has originated nothing for nine consecutive turns. `close.sh` may not close the mission
— the queue is not empty, and the close is arithmetic — so the only available act is to ask the
owner whether the leftover still matters. That question is `mission-leftovers:<slug>`, and it is
one of the three that can never be asked again.

## What the repair would have to provide

Stated as the finding sees it, not as a decision:

1. An event that returns a retired key to `candidate` when its owning step raises it again — the
   registry already receives a `register` for exactly that key on exactly that tick, so the
   signal is present and only the state transition is missing.
2. Or, failing that, a retirement that carries the reading it was made on, so a later tick can
   tell a retirement made on a *proof* from one made on a `settled` that was never re-derived.

Both need the same care the existing `retire` event has: a revival is as much a claim as a
retirement, and reviving on anything weaker than the owning step's own live finding would turn
the asked-once gate back into hourly nagging, which is what this repository has retired two roots
for.

Nothing was retired, revived, re-asked or hand-edited by this report. The three registry entries
are left exactly as they are; naming them is the act.
