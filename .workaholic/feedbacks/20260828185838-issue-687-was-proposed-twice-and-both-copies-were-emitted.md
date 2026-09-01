---
type: Feedback
title: Issue #687 was proposed twice and both copies were emitted
kind: insight
source: development
subject: observer_ai:[Moderate] tick 20260828-185119
created_at: 2026-08-28T18:58:38+00:00
author: a@qmu.jp
supersedes: 
---

# Issue #687 was proposed twice and both copies were emitted

Issue #687 was ingested twice by `/specificate`, six hours apart, and each run emitted a full proposal for it. Both pull requests carry `Closes #687`:

- **#688** — opened 2026-08-28T12:25:00Z from `work-20260828-122456`, still **open** and **conflicting with main**. Its feedback record is `.workaholic/feedbacks/20260828121729-deliver-what-the-loop-already-knows-to-the-person-who-can-act.md`, which exists only on that branch (commit `d74c7be0`, not an ancestor of `main`). Body: "1 feedback added, 1 feedback modified, 1 mission added, 1 mission modified, 7 tickets added".
- **#689** — opened 2026-08-28T18:25:38Z from `work-20260828-182534`, **merged** at 18:25:41Z as `039a2bd4`. Its record is `.workaholic/feedbacks/20260828181639-deliver-what-the-loop-already-knows-to-the-person-who-can-act.md` — the same slug, a different stem.

So the loop planned the same mission twice and the second copy landed, leaving #688 as a stale conflicting pull request that nothing will merge and whose seven tickets duplicate the seven that did land.

The dedup that should have caught this is `/specificate`'s `list-proposed-refs.sh`, which `CLAUDE.md` states reads unmerged branches as well as `main`; it did not exclude #687 on the second run while #688 was open in front of it. This is the same defect class as `20260805053636-list-proposed-refs-sh-dedup-misses-feedback-refs-on-unmerged-pull-requests.md`, measured again with an issue number and two pull requests rather than a near miss — that record described a duplicate a reviewer caught by hand; here both copies were actually emitted, and one merged.

A second, smaller reading from the same measurement: the merged item (#689) has **no Slack thread at all**. Two exact-string case-2 searches on both of its feedback stems returned nothing, while the *unmerged* copy's record does have a `📝 FB` root (2026-08-28 21:25:49 JST) whose link points at a path that will never resolve on `main`. The `thread-reconcile` step reported `no_thread` for it and posted nothing, which is its contract — but the channel now carries a root for the copy that did not land and none for the copy that did.

Noticed by the `[Moderate]` tick while resolving a `thread-reconcile` candidate; nothing was merged, closed, rebased or claimed.
