---
type: Mission
title: Make the feedback loop actually propose
slug: make-the-feedback-loop-actually-propose
status: active
merge_policy: 
created_at: 2026-08-04T20:05:42+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
feedback: [20260730101911-the-proposal-cursor-is-runner-local-so-an-ephemeral-runner-cold-starts-every-tick-and-proposes-nothing.md, 20260730110659-the-proposal-cursor-cannot-survive-an-ephemeral-runner.md, 20260730111041-propose-should-pick-ticket-vs-mission-by-cardinality.md]
claim: work-20260804-202110
---

# Make the feedback loop actually propose

## Goal

Feedback flows in but nothing flows out: `/propose` has never produced a proposal
in the current deployment. Measured 2026-08-04 — four causes stack: the batch has
no runner (the runbook's cron was never installed and no routine template exists),
the runner-local cursor bootstraps-and-stops on every fresh cloud container, the
[FB] routine calls `/propose` in the same session where the new record is still on
an unmerged PR branch (invisible to the window by design), and Slack work requests
are captured as `concern`/`insight`, which the judgment bar deliberately never
triggers on. The loop's contract — humans supply feedback, the AI proposes
missions — is currently a one-way pipe into the stream.

## Experience

A developer reports an ask in Slack; the [FB] routine records it as an
`instruction` and its PR merges. Within one scheduled tick, `/propose` — running
in a fresh cloud container with no local state — reads the shared cursor, sees the
new record, and either opens a proposal PR (a mission with two or more tickets, or
a single loose ticket when the ask is atomic) or reports a named drop reason.
Silence still means "judged and found not actionable", never "the runner could not
see the queue".

## Acceptance

- [x] A stateless runner can propose: the cursor is read from and advanced on a shared pushed ref, with the bootstrap-and-stop cold start gone (#20260804200555-move-the-proposal-cursor-to-a-shared-pushed-ref.md)
- [x] The batch has a scheduled seat: a propose routine template ships, the runbook describes it, and the [FB] template no longer claims to run /propose in-session (#20260804200555-give-the-proposal-batch-a-routine-seat-and-retire-the-cron-premise.md)
- [ ] An atomic direction becomes a loose backlog ticket behind a PR instead of silence, and a Slack work request reaches the bar as kind: instruction (#20260804200555-emit-a-loose-ticket-when-a-direction-is-atomic.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
- 2026-08-04 — ticket archived — 20260804200555-move-the-proposal-cursor-to-a-shared-pushed-ref.md
- 2026-08-04 — ticket archived — 20260804200555-give-the-proposal-batch-a-routine-seat-and-retire-the-cron-premise.md
