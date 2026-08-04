---
type: Feedback
title: Make `/workaholify` a per-developer setup with event-scoped routines and no fixed channel convention
kind: instruction
source: slack
created_at: 2026-08-03T12:58:43+00:00
author: a@qmu.jp
supersedes: 
---

# Make `/workaholify` a per-developer setup with event-scoped routines and no fixed channel convention

`/workaholify` currently provisions routines at a repository/team scope, on a fixed schedule (hourly ticks), posting into a channel that follows a `dev-***` naming convention. The ask is to make `/workaholify` a developer-scoped setup instead: each developer runs it to configure their own Claude Code web routines, tied to their own activity rather than a shared schedule. A developer's routine should wake only on events belonging to that developer — when they merge a pull request, or when they create a feedback ("FB") issue — rather than ticking on a timer regardless of whether anything happened. The routine then reports into that developer's own channel. The `dev-***` naming convention should no longer be assumed or enforced; instead, `/workaholify` setup should ask the developer which channel to use and when/on-what-trigger their routine should run, rather than deriving it from a fixed convention.
