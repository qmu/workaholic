---
type: Feedback
title: Specificate published a duplicate ticket set for an already-driven mission
kind: concern
source: development
subject: observer_ai:[Specificate] routine
created_at: 2026-09-01T07:25:08+00:00
author: a@qmu.jp
supersedes: 
---

# Specificate published a duplicate ticket set for an already-driven mission

# Specificate published a duplicate ticket set for an already-driven mission

Source: https://github.com/qmu/workaholic/issues/824

A `[Specificate]` run published a ticket set that duplicates an already-driven one, and all eight duplicates are queued on `main` now.

**What happened.** Issue #617 was ingested twice against the same mission slug `say-when-the-loop-has-run-out-of-direction`. A run scaffolded the mission at `2026-08-26T07:19:28Z`, was interrupted, and did not reach its publish seam until `11:05`. In that window a second run emitted the mission's ticket set at `08:20:29`, and `work-20260826-084111` drove and archived all eight of them. The first run then scaffolded its own eight tickets at `11:00:16` into its still-open publish tree and published them as PR #625, which merged. Every one of the eight tickets now in `.workaholic/tickets/todo/2026082611001*` has a same-titled counterpart already archived under `.workaholic/tickets/archive/work-20260826-084111/2026082608202*`; the pairs match one-for-one, and only three filenames differ slightly in wording (`drill-direction-health-with-no-network`, `render-...-on-the-moderation-root`, `write-direction-state-sh-the-one-lifecycle-reader`).

**Why it is live.** The mission is `status: active` on `main` with `tickets: []`, and its `## Acceptance` links point at the **queued** filenames rather than the archived ones. So the archive gate's arithmetic (`checked == total`, `unlinked == 0`, `todo == 0`) cannot close it, and `/implement` will claim and re-drive eight tickets whose work is already on `main`.

**Why the existing guards did not catch it.** `list-inbound-issues.sh` excludes an issue a feedback record already names, but the second run's record had not reached `main` when the first run's publish tree was cut, so #617 read as uncaptured. `list-proposed-refs.sh` could not separate them either: both artifacts carry the strategy's own ref `20260821162443-...`, which `/specificate` carries onto every mission for that direction, so the one ref they share is exactly the ref that cannot serve as a dedup signal, and the run-specific records differ by construction. `scaffold-draft.sh` refuses an existing slug, but the slug did not exist on the base at `07:19`; it was the *first* run that created it. The common factor the reporter names is a **publish tree that outlives the base state it was cut from**: every gate read a base that was current when the tree opened and stale when it published.

**What is asked for.** Two decisions the reporter states an unattended run should not make on its own: whether the eight queued tickets are removed from `main`, and by whom, since deleting queued work from the base is outside what `/specificate` or `/implement` may do; and whether the mission's acceptance links are re-stamped onto the archived filenames so the archive gate can close it, or the mission is closed by `/mission-close`. And a possible third, for the loop itself: whether a publish seam should re-check its base immediately before publishing, since the dedup reads are all taken at steps 3-6 and nothing re-reads them at step 10.
