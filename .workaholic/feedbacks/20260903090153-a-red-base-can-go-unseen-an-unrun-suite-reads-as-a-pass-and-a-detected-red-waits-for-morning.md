---
type: Feedback
title: A red base can go unseen: an unrun suite reads as a pass and a detected red waits for morning
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T09:01:53+09:00
author: a@qmu.jp
supersedes: 
---

# A red base can go unseen: an unrun suite reads as a pass and a detected red waits for morning

Source: https://github.com/qmu/workaholic/issues/943

The operator's words: 毎ティック出なくてもいいから GHA のエラーに気づかないとダメ. The frequency is
not the problem — not noticing at all is. The base was red for about an hour and nothing surfaced
it, through two independent mechanisms, neither of them about how often the loop looks.

## Cause 1 — a suite that never ran reads as a pass

The mock workflow fires only on changes under the mock package, and the mock tests import from
the application package's source. A unit that touched only the application landed a change that
broke the mock suite, and that suite never ran on the offending commit — so there was no failing
verdict to detect. The base was red in fact and green in every reading.

`base-health` reads the newest verdict the base carries. On that commit the newest verdict was
the application's, and it was green: a missing verdict and a passing one are indistinguishable to
it. Meanwhile the loop kept claiming units, opening pull requests and merging them against that
base. The gap was found only because a later unit happened to touch the mock package.

## Cause 2 — a detected red waits for morning

Earlier the same day `base-health` did catch a red base correctly. The alert was a `base-red:<sha>`
question, and `ask-question.sh` held it under `quiet_hours` (22–08), so a base that goes red in
the evening is first announced the next morning and the loop builds on it all night. Questions
are held for a good reason — they address a named person, and nobody should be paged at 23:00 to
choose between two dates. A red base is not that kind of message: it asks the operator to decide
nothing, it reports that the ground everything is landing on is broken. `🔴 Blocked` already
exists for that class and is governed by a cool-down rather than by a speaking window.

## What the ask asks for

- `base-health` requires a verdict per declared suite on the current tip, not merely the newest
  verdict. A suite with no run on this commit is reported as `unverified: <suite>`, never folded
  into green. That needs no new source of truth — the workflows are already declared.
- A red base leaves the question channel: it is a `🔴 Blocked` report subject to the existing
  failure-signature cool-down, not to `quiet_hours`. Nobody is being asked anything, so the reason
  the quiet window exists does not apply.
- The reading is cheap enough to keep however rarely it is delivered: it need not fire every tick,
  it must be impossible for the loop to be unaware.
