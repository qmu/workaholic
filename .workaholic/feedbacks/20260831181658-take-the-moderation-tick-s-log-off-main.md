---
type: Feedback
title: Take the moderation tick's log off main
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-08-31T18:16:58+00:00
author: a@qmu.jp
supersedes: 
---

# Take the moderation tick's log off main

Source: https://github.com/qmu/workaholic/issues/782

**A commit is a change to the development target.** `main`'s history is not, and the loop is the author of the noise.

## Measured

`osbrjp/coop-planner`, `main`, one calendar day (2026-08-31) — **275 commits**:

| class | count |
| ----- | ----- |
| touches only `.workaholic/` | **138** |
| mixed | 63 |
| merge commits | 44 |
| empty (`Refresh heartbeat`, `Resume a PR-unit`) | 25 |
| **touches only the product** | **5** |

Over the last 400 commits the same shape holds: 187 `.workaholic/`-only, 26 empty, 6 product-only. The largest single author is the moderation tick's own log — **65+ `Log the propose tick <id>` commits in that sample, two or three per tick id**, because `persist-log.sh` is invoked three times per tick (the opening persist for `blocked-tick`, the closing act, and the agent's persist after recording what it filed).

## Already shipped, and what it leaves

Squash-merging every pull request this loop merges (`gather/scripts/merge-method.sh`, 2026-09-01) removes the 44 merge commits and folds each unit's claim, heartbeat, story and mission-hours commits into that unit's one commit. It does **not** touch the tick log, which reaches `main` as a **direct** commit through the publish tree with no pull request at all. After the squash change the tick log is what is left, and it is then the dominant author of `main`.

## The ask

**The moderation tick's log must stop reaching `main`.**

Its *content* is load-bearing and is not in question: it is the tick's only memory across discarded containers — every step's dedup, `question-state.sh`, `record-answer.sh`, `condition-age.sh`, `filed-records.sh`, `step-blocked-tick.sh` all read it. What is wrong is its **home**. `CLAUDE.md` already says what it is — *an operational log, not knowledge* — and an operational log is not part of the product's history.

Direction (the operator's, not a fork to re-open): it moves to a **dedicated ref in this same repository**, so the repository stays the coordination medium and no server appears, while `main`'s log becomes a list of units of product change. `.workaholic/moderations/` stops being a path on `main`.

What the mission has to answer, because none of it is obvious:

- which ref, how it is created on a repository that has never had one, and how a fresh container fetches it;
- how concurrent ticks still union by `(tick, step)` against it — the property `persist-log.sh` currently gets from the publish tree;
- how every reader listed above reaches it without a second walker;
- what happens to the `moderations/` history already on `main` (left where it is, or moved) and what `layout-doctor.sh`, the root index and the OKF floor say afterwards;
- whether the three persists per tick are still three once the log is off `main`, each justified by name or dropped by name;
- the drill that fails when a tick's log does not reach the ref, and the drill that fails when a tick log reaches `main` again.

## Not in scope

The claim commit, the heartbeat and the branch story stay exactly as they are. They are correct where they live; the squash already keeps them off `main`.
