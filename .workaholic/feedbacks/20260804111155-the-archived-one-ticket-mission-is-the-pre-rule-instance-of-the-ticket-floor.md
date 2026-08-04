---
type: Feedback
title: The archived one-ticket mission is the pre-rule instance of the ticket floor
kind: insight
source: discussion
created_at: 2026-08-04T11:11:55+00:00
author: a@qmu.jp
supersedes: 
---

# The archived one-ticket mission is the pre-rule instance of the ticket floor

The two-ticket floor was decided on 2026-08-04 (`20260804173526-a-mission-is-created-with-two-or-more-tickets-or-it-is-not-a-mission.md`) and enforced at all four creation seams the same day. This record names the one instance that predates it, so a future reader auditing the mission tree against the floor does not read history as a live violation.

**`drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main` — archived, one ticket — is pre-rule.** It shipped fine and did no harm; the claim the floor makes is not that a one-ticket mission fails, but that "mission" and "ticket" must not both name the same thing. It is annotated here rather than in its own file because the archive is history and history is not rewritten (`workaholic:design` / `history-structures`) — an edit to an archived mission to satisfy a rule invented after it closed would make the archive a record of the present rather than of what happened.

**The other sub-floor instance was resolved rather than annotated**, because it was live: `make-the-branch-story-measurably-shorter` was minted with zero tickets by `close.sh --successor-title` on 2026-08-04 and was replanned into its two-ticket set the same day. The seam that minted it is now refused (`successor_title_refused`), so that route cannot produce another.

**The audit, for anyone re-checking:** `mission/scripts/queue-size.sh <slug>` reports `meets_floor` per mission. No repo-wide sweep script was added — every creation seam now refuses below the floor, so a recurrence would have to come from a hand-written file, and a script that can only ever report zero is a script nobody re-runs.
