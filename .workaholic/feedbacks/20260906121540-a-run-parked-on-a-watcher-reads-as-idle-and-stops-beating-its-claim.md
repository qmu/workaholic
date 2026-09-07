---
type: Feedback
title: A run parked on a watcher reads as idle and stops beating its claim
kind: concern
source: development
subject: observer_ai:workaholic-loop
created_at: 2026-09-06T12:15:40+09:00
author: a@qmu.jp
supersedes: 
---

# A run parked on a watcher reads as idle and stops beating its claim

Source: https://github.com/qmu/workaholic/issues/1014

## A run parked on a watcher looks finished, and stops beating its own heartbeat

Two rules meet here and neither anticipated the other.

`commands/infinite-development.md` §2 tells the coordinator tick that **every `idle` subagent is
stopped at the HEAD of this tick, unconditionally**, because an idle agent is not a corpse but a
resumable session holding its whole transcript.

The claim protocol tells the runner that **the beat is step 0 of every ticket, not a cadence** — a
unit that is one long ticket runs its whole implementation on the claim commit's own timestamp and
loses its own claim to the 30-minute resume window by construction.

A run that arms a blocking watcher and yields its turn is **`idle` by the listing and alive by
intent**. It is between tickets, so no heartbeat is due; and it is not executing, so it cannot beat
one. Both rules then misfire at once.

## Measured, 2026-09-06

An `implement` run driving the operator's own Codex mission reached the drill suite, found it would
take many minutes under a loadavg of ~19 on 4 cores, armed a blocking watcher and yielded, stating
that its claim heartbeat was fresh so the unit was not at risk of being resumed out from under it.
True when written. The measurement:

```
origin/work-20260906-113520  tip 2026-09-06 02:35:24Z   (Claim a PR-unit)
now                              2026-09-06 02:58:30Z
```

23 minutes of the 30-minute resume window already spent, with nothing left that will beat it. The
run is parked; the next beat is step 0 of a ticket it will not reach until the watcher fires.

## The two failures this opens

**The coordinator stops live work.** Read literally, §2 stops this agent at the head of the next
tick — discarding a run mid-unit on a live claim, for a rule written against accumulating corpses.
The listing gives the tick one word, `idle`, for two opposite states.

**Or the loop drives the same unit twice.** If the coordinator instead leaves it alone and spawns
its ordinary per-tick `implement` runner, that runner surveys after the window lapses, sees its own
identity's stalled claim, and `claim.sh resume` takes it over — while the first run is still holding
a worktree and about to wake. The claim arbiter does not prevent this: it wins the *claim act*, and
`resume` of one's own lapsed claim is exactly what it is designed to allow.

So a tick facing a parked run must choose between throwing work away and doubling it, and the
listing gives it nothing to choose on.

## The fork, which is a person's to settle

Either **a parked run must keep its claim alive** — the heartbeat becomes something the runner arms
before yielding rather than something it beats between tickets — or **the coordinator must be able
to see the difference** between a finished run and a parked one, which the agent listing does not
currently express. The first is a claim-protocol change; the second is a tick change. They are not
equivalent and the choice is not the loop's.

## What must not be done

Do not widen `claim.sh resume` to refuse a lapsed claim of one's own. That refusal is the only
recovery path for a genuinely dead run, which the reporting session used an hour earlier to rescue
six tickets. Trading it away to cure this would reintroduce a worse failure.

## Why nothing was emitted for it

The ask is machine-originated (`subject: observer_ai:workaholic-loop`, `ask-origin.sh` → `machine`)
and its subject is the loop's own apparatus — the claim protocol and the coordinator tick. Under
`rules/workaholic.md`, *What May Originate a Mission*, such a record may not originate a mission.
It is registered as knowledge and the fork stays open for a person.
