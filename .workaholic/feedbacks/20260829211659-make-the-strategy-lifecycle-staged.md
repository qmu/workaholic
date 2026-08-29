---
type: Feedback
title: Make the strategy lifecycle staged: 進行中 / 改良中 / 観察中
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-29T21:16:59+00:00
author: a@qmu.jp
supersedes: 
---

# Make the strategy lifecycle staged: 進行中 / 改良中 / 観察中

Source: https://github.com/qmu/workaholic/issues/733

The operator asks that a strategy's lifecycle become **staged, not binary**. Today the loop
reads a direction as converged-or-not (`quiescent`, `dormant`, `no_evolutionary_move`); the
operator wants three explicit, visible stages, in the operator's own vocabulary, kept
verbatim:

1. **進行中 (in progress)** — pull requests are landing, but the work cannot be cut over yet
   (no feature toggle can be flipped; the built thing is not yet usable end to end).
2. **改良中 (improving)** — cut-over is possible or done. Development continues: proposals
   keep being made and refined, with the strategy's priority rising and falling **relative
   to the other active strategies**.
3. **観察中 (observing)** — the development has settled. The loop stays reactive only: it
   responds when log observation finds an error, or when a user files feedback — it no
   longer originates proposals for this direction on its own.

**A handoff is orthogonal to the stage.** `handoff` / blocked / undecided states occur in
any of the three stages; a pending or un-drivable unit must never be read as evidence that
the direction is 観察中. The stage is never inferred from stuckness.

## What the stage should drive

- **Positioning**: the stage is the direction's declared phase, visible wherever directions
  are read (the roadmap, the standup digest, `/moderate`'s questions, `survey-strategies.sh`
  rows) — one word per direction, not a bundle of readings the reader must cross-reference.
- **Behavior**: `/propose`'s judgment should differ by stage — 進行中 and 改良中 keep
  originating moves (with cross-strategy prioritization in 改良中); 観察中 originates nothing
  and reacts only to inbound signals (errors observed in logs, user feedback).
- **Noticing**: stage transitions are the moments worth telling a person about — "this
  direction can now cut over" (1→2) and "this direction has settled into observation" (2→3)
  — rather than only overdue/dormant alarms.

## The operating context (generalized)

The operator runs **multiple strategies that reference each other and improve as a blend** —
for example a foundation system's improvement, a feature area's CRUD built on that
foundation, and the domain modeling behind that area, all verified on a shared mock /
developer portal. The strategies are expected to resolve priority among themselves while
mutually influencing each other's work. The staged lifecycle is what lets that blend run:
each direction can sit in a different stage, and the loop's proposing energy concentrates on
the directions whose stage asks for it.

## Constraints already ruled

- The strategy artifact keeps its writers; how the stage is recorded and who moves it is a
  design question for `/specificate` to open, but a stage change is an operator-auditable
  act, never a machine's silent reclassification.
- Existing readings (`quiescent`, `dormant`, `overdue`, `expiring`, `pace`) are evidence that
  can *suggest* a transition; none of them becomes the stage by itself.
