---
type: Feedback
title: A native Work loop must not end after an ordinary progress report
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-21T18:01:38+09:00
author: a@qmu.jp
supersedes: 
review_surface: 
---

# A native Work loop must not end after an ordinary progress report

kind: instruction / source: discussion / subject: person:tamurayoshiya

Source: https://github.com/qmu/workaholic/issues/1260

# A native Work loop must not end after an ordinary progress report

The operator reports that a native `/work` session repeatedly stops after the agent emits a
final response reporting a completed subset of work, while accepted work and observation
remain. Persisting `control: running` is not sufficient: once the host turn has ended and no
interruptible wait remains, nothing carries the loop.

The ask names three things to be made true:

1. A live continuation must be re-established immediately before the turn yields.
2. An attempted routine final response must fail closed.
3. A regression test must cover a completed worker followed by a progress report and
   continued observation, with no second human message.

## What this run measured

`plugins/workaholic/skills/work/scripts/final-response-contract.sh` already refuses a routine
turn that names no continuation (`continuation_unproved`), and validates that a named
continuation carries a `kind` from the closed set, an `id` and a numeric `next_due`. It does
**not** compare `next_due` against the moment of the turn, so a continuation whose deadline has
already passed satisfies the contract and the turn yields to nothing.

`plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq` already makes exactly that
reading at every event: `resumed` is false with `resumed_reason: continuation_lapsed` when
`continuation.next_due < now`. The derivation exists; the final-response gate does not consult
it.

Second, the contract answers `final_response: false` for a routine turn but has no fact
describing what the turn *intends*. A run that emits a routine final response anyway is
invisible to the reader, so the contract cannot fail closed on the act the ask names.
