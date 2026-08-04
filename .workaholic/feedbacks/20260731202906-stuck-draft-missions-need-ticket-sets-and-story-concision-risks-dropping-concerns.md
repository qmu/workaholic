---
type: Feedback
title: Stuck draft missions need ticket sets and story concision risks dropping concerns
kind: concern
source: discussion
created_at: 2026-07-31T20:29:06+00:00
author: noreply@anthropic.com
supersedes: 
---

# Stuck draft missions need ticket sets and story concision risks dropping concerns

Two findings from an audit of issues #120, #125, #126, and #129's follow-through, relevant to whoever drives the mission-gate retirement work and the story-concision mission. Reported as GitHub issue #149.

First, PR #142 retires the mission draft/approve gate so that merging a mission's own PR is itself the approval, but the three still-draft missions it is meant to unblock — `make-scheduled-routines-a-configurable-inspectable-part-of-a-repository`, `make-the-branch-story-concise-by-default`, and `make-the-per-commit-changed-lines-ceiling-a-rule-that-holds` — all carry an empty ticket set (`tickets: []`). Merging #142 will relabel their blocking reason from `not_approved` to `no_tickets` without actually making them claimable; each one still needs its ticket set emitted, presumably through the mission's creation or replan interrogation, before `/drive` can pick anything up from them.

Second, the draft mission `make-the-branch-story-concise-by-default` (from issue #125) proposes dropping `Severity: low` blocks from the branch story to make it more concise, but `ship/scripts/extract-deferred-concerns.sh` currently reads the story's own section on deferred concerns as its only source and records every severity it finds there with no filter. Implementing the story-format change first, without also updating that extraction script, would silently delete every low-severity concern from the feedback stream instead of merely shortening the write-up. Whoever picks up that mission should treat updating `extract-deferred-concerns.sh` — or explicitly deciding that low-severity concerns should stop being recorded at all — as part of the same change, not a follow-up.
