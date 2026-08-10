---
type: Feedback
title: Fix drift in routine notify templates for Propose/Implement status posts
kind: instruction
source: discussion
created_at: 2026-08-10T08:09:30+00:00
author: a@qmu.jp
supersedes: 
---

# Fix drift in routine notify templates for Propose/Implement status posts

GitHub issue #333 (filed by claude[bot] at the request of the repository developer, tamurayoshiya, via a direct Slack instruction on 2026-08-10) reports that the routine templates powering the [Propose] and [Implement] Claude Code Web routines have drifted from the notification model actually implemented in the workaholic:notify skill.

The developer supplied a corrected template in Slack for the two routine prompts (Propose, Implement), specifying four Slack status posts per feedback item's lifecycle:
1. Proposing started (`\U0001F4D0 Proposing for [#N [FB] Title](issue url) by the [routine](session url) of <@user>`)
2. Proposed (`\U0001F535 Proposed - [#N [Proposal] PR Title](pr url) by the [routine](session url) of <@user>`) - posted after /propose runs
3. Implementing started (`\U0001F7E0 Implementing for [#N Proposal PR Title](pr url) by the [routine](session url) of <@user>`)
4. Implemented (`\U0001F7E2 Implemented - [#N Title](pr url) by the [routine](session url) of <@user>`) - posted after /implement runs

This does not match workaholic:notify's current canonical model (SKILL.md + reference/notifications.md), which defines only a single post for the whole propose stage (\U0001F7E2 Proposed, as the routine'\''s thread root, no pre-post) and a different palette for the implement stage (\U0001F7E0 drive started / \U0001F7E2 Merge Requested / \U0001F7E1 Handoff / \U0001F534 blocked, no separate '\''Implementing started'\'' post keyed to the PR and no plain '\''Implemented'\'' shape). The issue asks that the routine templates and/or the notify skill be reconciled around the developer'\''s corrected wording so routine posts stop drifting from what the skill documents.
