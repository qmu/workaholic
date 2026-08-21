---
type: Feedback
title: An autonomous improvement loop run by the routines
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-08-21T16:24:43+09:00
author: a@qmu.jp
supersedes: 
---

# An autonomous improvement loop run by the routines

The operator asks for an **autonomous improvement loop run by the routines**, filed as a
strategy with `target_date: 2026-08-31` and the issue's assignee as its owner.

Source: https://github.com/qmu/workaholic/issues/555

## What was asked

- Add a **`/propose` routine**, after `/specificate` and `/implement`. It is an entirely
  different thing from the `/propose` that was renamed to `/specificate` on 2026-08-19.
- Its job is to produce the feedback needed to move the running identity's **own assigned
  strategies** closer to being reached.
- The three routines should turn an hourly loop — `/specificate` → `/implement` →
  `/propose` → `/specificate` … — so the development experience is a self-improving cycle.
- The developer's work moves up a layer: enriching the direction (strategies and the like)
  rather than the tickets.
- **`/propose` must not be housekeeping.** It has to be evolutionary with respect to a
  strategy — widening its depth and its breadth, and contracting it where consistency
  demands — not safe small change. The feedback it produces must **commit to the strategy**.

## The four things the ask left open, named by the operator

1. **The name has moved twice in five days.** Taking `/propose` back means confirming it
   collides with neither the command that became `/specificate` nor the routine that became
   `[Moderate]`. Convergence matches an account's routines by rendered `name`.
2. **The loop's clock is already crowded** — `:10` `[Workaholic]`, `:15` `[Specificate]`,
   `:30` `[Implement]`, `:50` `[Moderate]`. Where `/propose` lands, and whether the loop
   closes within one hour or across hours, is the concrete question.
3. **The reader that answers "what belongs to this strategy" is lossy by design.**
   `strategy/scripts/attributed-work.sh` walks `strategy.feedback[] ∩ artifact.feedback[]`
   plus one hop through a mission, and every consumer is contracted to report what it could
   not attribute. Judging "widen here, contract there" on top of a reader that admits it
   cannot see everything is the core of the ask.
4. **Where the output goes decides whether the loop closes.** `/specificate`'s unattended
   entrance is the open GitHub issues assigned to the running identity. A record written
   straight into `.workaholic/feedbacks/` is not discovered, because discovery reads issues.

## The bar this deliberately breaks

Every unattended routine today is unified under a conservative rule: when unsure, record
only, and say what made you unsure. A routine that emits strategy-committing feedback every
hour is the first to drop that bar on purpose. What stops it running away is this strategy's
to answer — the existing loop has no brake other than that bar.
