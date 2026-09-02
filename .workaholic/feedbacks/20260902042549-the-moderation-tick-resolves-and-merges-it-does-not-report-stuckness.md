---
type: Feedback
title: The moderation tick resolves and merges, it does not report stuckness
kind: instruction
source: slack
subject: person:a@qmu.jp
created_at: 2026-09-02T04:25:49+00:00
author: a@qmu.jp
supersedes: 
---

# The moderation tick resolves and merges, it does not report stuckness

Source: https://github.com/qmu/workaholic/issues/861

The operator corrected three behaviors observed in the moderation tick's channel posts,
and states that the current implementation is entirely contrary to their intent.

1. The tick posted that some pull requests could not be merged because GitHub had not yet
   computed mergeability. That is not worth a notification; an unknown mergeable state
   only means the pull request cannot be included in this pass's conflict resolution.
2. The tick posted "we do not rebase here; generated-index conflicts are catch-up's to
   resolve and content conflicts belong to the claim holder". The operator calls this
   completely wrong: the moderation tick's role is to decide, resolve, and advance. It
   must bring every conflicted pull request into a mergeable state itself — rebasing or
   merging as appropriate — and merge it, rather than parking it for a claim holder who
   never comes.
3. The stuck-prs step was never asked for and is not working; it must not be used. The
   moderation tick resolves the stuckness and reports what it did, never that things are
   stuck.

This is the operator's standing "resolve, not report" expectation restated against three
concrete measured behaviors; the parked "handoff" pull requests read as progress to the
loop while reading as total stagnation to the operator.
