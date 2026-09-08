---
type: Mission
title: Make Slack acknowledgements informative without becoming notification noise
slug: make-slack-acknowledgements-informative-without-becoming-notification-noise
status: active
merge_policy:
created_at: 2026-09-08T12:44:04+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260908124344-make-slack-acknowledgements-specific-conversational-and-burst-aware.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260908-140833
---

# Make Slack acknowledgements informative without becoming notification noise

## Goal

Treat Slack acknowledgements as useful conversation between people and general-purpose agents: make each subject recognizable, group bursts without losing durable per-message state, and constrain workflow facts without forcing repetitive prose.

## Experience

A person scanning one receipt or a burst can tell what was heard, where it was recorded, and what the loop actually committed to without opening every issue or reading identical bot copy.

## Acceptance

- [x] Every visible receipt identifies the request in the person's language and promises only the workflow state actually reached. (#20260908124419-define-the-human-centered-slack-acknowledgement-contract.md)
- [x] Related rapid asks can produce one compact subject-to-issue acknowledgement while every source message retains durable handled state. (#20260908124419-group-burst-receipts-while-preserving-per-message-durable-state.md)
- [ ] Tests assert required facts, grouping, deduplication, and delivery separately from one mandatory prose sentence. (#20260908124419-test-acknowledgement-facts-separately-from-natural-prose.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-08 — ticket archived — 20260908124419-define-the-human-centered-slack-acknowledgement-contract.md
- 2026-09-08 — ticket archived — 20260908124419-group-burst-receipts-while-preserving-per-message-durable-state.md
