---
type: Feedback
title: Trigger the drive routine on a merged proposal and report start and completion in its thread
kind: instruction
source: slack
created_at: 2026-08-05T13:04:07+00:00
author: a@qmu.jp
supersedes: 
---

# Trigger the drive routine on a merged proposal and report start and completion in its thread

tamura_yoshiya asked in `#dev-workaholic` that the `[Drive]` routine stop running on a clock and instead start when it detects that a proposal's pull request has merged, and that the run then report itself into the Slack thread that proposal already has — an "implementation started" notice when it begins the work, and a completion notice when it finishes — rather than as posts of their own.

Today `[Drive]` is the only scheduled template, firing hourly at :56 UTC and taking whatever the survey offers; nothing ties a given run to the proposal that produced its work. The threading half is already written policy — *One thread per feedback item* names "any `/drive` outcome for work that traces back to it" as an in-thread reply, and the template's §5 defers its post routing to it. What does not exist is the wiring and the granularity: a drive session has no path from the unit it is driving, through that artifact's `feedback:` refs, to the `fb:<stem>` key that identifies the thread; and the postable set is per-**run**, so the "run started" line names no single item and has nothing to thread to. `[Consent]` already fires on a merged pull request, so an event-driven `[Drive]` would be the second routine watching that event, and which of the two owns the proposal-merge case is part of what this asks to settle.

The reporter's stated goal is that the whole Proposal → Drive → completion lifecycle be followable in one thread — the same principle already applied to `[Propose]` and `[Consent]`.

Reported in Slack (<https://qmu.slack.com/archives/C0BLL9J7FMY/p1785934528023809>) and registered as qmu/workaholic#256.
