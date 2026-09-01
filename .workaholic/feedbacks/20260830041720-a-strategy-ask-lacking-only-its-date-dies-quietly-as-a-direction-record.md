---
type: Feedback
title: A strategy ask lacking only its date dies quietly as a direction record
kind: instruction
source: discussion
subject: person:Yoshiya Tamura
created_at: 2026-08-30T04:17:20+00:00
author: a@qmu.jp
supersedes: 
---

# A strategy ask lacking only its date dies quietly as a direction record

kind: instruction / source: discussion / subject: person:Yoshiya Tamura

Source: https://github.com/qmu/workaholic/issues/743

Measured 2026-08-30 on a repository running this loop. The operator announced three named directions in the repository's channel, asking that they form a mutually-referencing improvement loop, each verifiable on the project's two public surfaces. The asks carried an aim and an owner but no target date, so the strategy form could not be met, and the loop did what it is written to do: it registered each as a feedback record only, with a finish line reading "[Proposal] Register the … direction (no target date, so no strategy)". Everything downstream then behaved correctly and nothing moved — no file appeared under \`.workaholic/strategies/\`, the hourly \`[Propose]\` kept planning from the previously existing directions alone, and the operator discovered the stall only by asking, hours later, why the three directions seemed stuck.

The defect is not the refusal — a strategy without a date is rightly not a strategy — but that the refusal's only trace is a parenthetical in a finish line addressed to nobody. Nothing asked the operator for the one missing part, in the thread where they were already talking, even though the loop already has a shape for exactly that (the moderation tick's directed in-thread question).

Two acceptable endings, either or both:

1. An ask that fails the strategy form on the date alone produces a **directed question naming the missing part** in the item's own thread — "this needs a target date to become a strategy; what date?" — instead of only the parenthetical.
2. Per this operator's standing ruling, stated for the record: **the default target date is one week from the ask**. The loop may draft the strategy with that default, saying so in the proposal, on the existing never-auto-merge strategy path, so the operator's merge stays the authorship and editing the date before merging is the veto.

Done means: an ask naming a direction with an aim and an owner but no date no longer ends as a silent direction record — it ends as an in-thread question about the date, or as a draft strategy carrying the stated one-week default.
