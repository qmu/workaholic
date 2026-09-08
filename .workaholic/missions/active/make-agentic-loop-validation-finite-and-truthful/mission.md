---
type: Mission
title: Make agentic-loop validation finite and truthful
slug: make-agentic-loop-validation-finite-and-truthful
status: active
merge_policy:
created_at: 2026-09-08T14:58:31+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260908145807-make-validate-plugins-fail-finitely.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Make agentic-loop validation finite and truthful

## Goal

Make the agentic-loop validation describe real distinct inbound activity and always reach a finite pass or fail result, so a broken fixture can never hold every pull request in `checks_pending` indefinitely.

## Experience

A contributor sees `Validate Plugins` complete normally when the activity-clock contract holds, and receives a named timeout failure within a bounded window when any contract leaks a process.

## Acceptance

- [ ] The observation-clock fixture presents two distinct source coordinates and proves that the second observation-only wake does not advance the anchored work cadence. (#20260908145846-make-the-observation-clock-fixture-emit-distinct-activity.md)
- [ ] The agentic-loop process test and its CI step terminate within explicit bounds, failing with actionable output instead of remaining pending. (#20260908145847-bound-agentic-loop-validation-against-leaked-processes.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
