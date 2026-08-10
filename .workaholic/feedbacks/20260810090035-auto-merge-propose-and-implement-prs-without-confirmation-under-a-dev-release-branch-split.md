---
type: Feedback
title: Auto-merge propose and implement PRs without confirmation, under a dev/release branch split
kind: instruction
source: discussion
created_at: 2026-08-10T09:00:35+00:00
author: a@qmu.jp
supersedes: 
---

# Auto-merge propose and implement PRs without confirmation, under a dev/release branch split

The developer wants to add a significant change to the direction captured in FB 20260810085032 (issue #336, PR #339, mission move-the-propose-and-implement-routines-to-a-fixed-interval-schedule): /propose's own output (and /implement's own output) should not wait for human confirmation before merging. Once a pull request is created, it should be merged immediately.

This is intended to work alongside three complementary loops that do not exist yet:
- a Quality Assurance (QA) loop
- a release-planning loop
- a post-release quality-check loop

It also implies splitting the current "main + feature branch" model into a development branch (where work accumulates continuously) and a release branch (the pre-production QA/release boundary) — likely building on the existing release/* tier (cut-release-branch.sh, .workaholic/releases/).

The developer's reasoning for why an unreviewed merge onto the development branch is safe:
1. It is not released immediately just because it merged.
2. A wrong spec or defect will likely be caught and fixed by later development work, or explicitly by the quality-check loop.
3. Even if such a problem slips through, the agent(s) responsible for deployment/release planning are expected to handle it sensibly when they plan the release.

The developer also sketched simplified routine-template prompts consistent with this policy — no separate "started" notification, just read the thread, run the command, and post one finish line once the PR exists:

[Propose] template:
  Read the feedback (FB) from the Issue and find its reply thread (the workaholic:notify lookup).
  After running `/propose [FB]`, notify the thread in the following format:
  🔵 Proposed - [#123 [Proposal] PR Title]({repo}/pull/123)
  by the [routine](https://claude.ai/code/session_***) of <@U…>

[Implement] template (new shape):
  Read the Mission/Ticket from the PR and find its reply thread (the workaholic:notify lookup).
  After running `/implement [Mission/Ticket]`, notify the thread in the following format:
  🟢 Implemented - [#123 Title]({repo}/pull/123)
  by the [routine](https://claude.ai/code/session_***) of <@U…>

The developer asked that this be folded into the plan alongside the existing feedback, i.e. reconsidered together with FB 20260810085032 rather than as an isolated, disconnected ask.
