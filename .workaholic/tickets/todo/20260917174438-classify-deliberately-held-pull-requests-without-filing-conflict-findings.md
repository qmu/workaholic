---
created_at: 2026-09-17T17:44:38+09:00
author: a@qmu.jp
assignees: []
depends_on:
feedback: [20260907070904-keep-a-handoff-branch-mergeable-while-it-waits-for-the-person.md]
merge_policy:
verification_handoff:
claim: work-20260917-184248
---

# Classify deliberately held pull requests without filing conflict findings

## Overview

Complete issue #1041's undelivered half: moderation must distinguish a broken pull request from a handoff pull request deliberately waiting for a person. Catch-up support landed in PR #1068, but `merge-conflicts` and `stuck-prs` still need a shared held verdict so the same handoff is not reported as a repairable conflict every tick.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/monitoring-and-observability.md` — operational reports distinguish expected waits from failures

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — conflict classification.
- `plugins/workaholic/skills/moderate/scripts/step-stuck-prs.sh` — stuck pull request classification.
- claim/handoff readers — authoritative `awaiting_verification` and handoff evidence.

## Implementation Steps

1. Reproduce a conflicting open PR whose live claim is `awaiting_verification` and localize where both moderation steps discard that state.
2. Read one shared held verdict from the claim/handoff evidence and exclude deliberately held PRs from `blocked` and repairable-finding output.
3. Continue reporting the held PR as waiting, without weakening catch-up, merge authority, or genuine conflict detection.
4. Add fixtures for held, ordinary conflicted, and unreadable claim state; unreadable must not be treated as held.

## Quality Gate

**Acceptance criteria** — a handoff PR waiting on a person is reported once as held and produces no conflict finding; an ordinary conflicting PR remains blocked.

**Verification method** — run the focused `merge-conflicts`, `stuck-prs`, and claim-reader fixtures plus the workflow script suite.

**Gate** — tests prove held, blocked, and unreadable are three distinct outcomes and PR #1068's catch-up-only boundary remains intact.

## Considerations

This ticket closes only the reporting half of #1041. It must not merge a handoff PR or infer that a person answered.

## Final Report

Added a shared, per-tick cached held-branch reader backed by the claim oracle's `awaiting_verification` verdict. Both conflict and stuck-PR moderation steps now exclude those branches from repair findings and questions while reporting them as deliberately held; unreadable claim evidence excludes nothing. Focused held-state fixtures passed 5/5 and shell syntax checks passed.
