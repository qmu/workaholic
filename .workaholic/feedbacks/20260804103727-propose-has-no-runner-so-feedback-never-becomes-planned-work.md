---
type: Feedback
title: /propose has no runner so feedback never becomes planned work
kind: concern
source: slack
created_at: 2026-08-04T10:37:27+00:00
author: a@qmu.jp
supersedes: 
---

# /propose has no runner so feedback never becomes planned work

Issue #192 assumes that when a feedback item ("FB") is filed, a routine produces a `[Proposal]` pull request carrying a detailed mission and its ordered ticket set, which the FB's thread then announces and tracks. Nothing produces that today: the FB routine registers a feedback record and opens a plain PR for the record itself — a *record*, not a *plan*. `/propose` is the only seam meant to turn feedback into a mission plus ticket set, and it is broken in three separate ways:

1. **`/propose` has no runner.** `/workaholify` ships exactly three routine templates — `fb`, `drive`, `merged-pr` — and none of them invoke `/propose`. CLAUDE.md still describes `/propose` as "the 15-minute cron entry", but the fleet has moved to Claude Code Web routines, so the planning step is simply never run.
2. **Its cursor makes it a no-op in the cloud even if it were scheduled.** `.workaholic/proposal-cursor` is runner-local and git-ignored, and `cursor.sh read` bootstraps a missing cursor to `origin/main` HEAD — treating all pre-existing feedback as already-seen. Every web-routine session is a fresh container with no cursor file, so every run would bootstrap to HEAD, see zero new feedback, and stay silent forever. Decision C1 assumed one long-lived server runs the batch; ephemeral containers break that assumption.
3. **It is decoupled from the FB that triggered it.** `/propose` reads feedback merged to `main` since its cursor, so it cannot act on an FB at FB-creation time — only after that FB's record PR has merged. Even then it may legitimately stay silent under its conservative bar, with nothing reported back to the FB's thread, so "judged not worth proposing" and "never processed" look identical from the outside.

Net effect: FB → record → (nothing) → drive. The step that is supposed to turn an ask into reviewable planned work never runs, which is why #192 received a feedback record instead of the proposal it was expecting.

This should be decided together with #192, since that issue's "[Proposal]" thread-root notification presumes a proposal actually gets produced.

Source: GitHub issue #196, raised from Slack in #dev-workaholic on 2026-08-04.
