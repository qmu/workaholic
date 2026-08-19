---
type: Feedback
title: Generate stories/index.md like every other OKF area
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-08-19T11:18:41+00:00
author: a@qmu.jp
supersedes: 
---

# Generate stories/index.md like every other OKF area

Source: https://github.com/qmu/workaholic/issues/524

The stories index is the one ledger index with no generator. `skills/okf/scripts/refresh-index.sh` owns the marked region of every flat knowledge area index and deliberately excludes `stories/index.md` — the exclusion is well-founded today, because the per-entry description exists nowhere but the index itself: the Story frontmatter (`type`, `branch`, `tickets_completed`, `tickets`, `mission`) carries no field for it, so `/report` writes the bullet directly.

The cost of that exclusion:

- Nothing repairs it. Every other area index is restored by a regeneration after a merge disturbs it; this one stays however the merge left it.
- Nothing detects drift in it. A run that writes its story file but never adds the bullet leaves no trace. In one consuming repository, 12 story files and one feedback record were missing from their indexes, found only by an identity check written by hand for the purpose.
- Ordering degrades monotonically. Every run inserts its line at the top, so any merge that keeps both sides — a `merge=union` attribute, or a hand resolution — leaves entries in insertion order rather than reverse-chronological order, and nothing normalizes it afterwards.

This matters more now that consumers are marking the ledger indexes `merge=union` in `.gitattributes` so a catch-up merge stops conflicting on a file where both sides are always right. Union never reports a conflict, so for the generated areas correctness rests on regeneration — which the stories index alone cannot use.

What would fix it:

1. Add `summary:` to the Story frontmatter schema (`skills/report/reference/story-structure.md`) — the same one-line text `/report` already composes for the index bullet.
2. `/report` writes that field into the story file and stops writing the index directly.
3. `refresh-index.sh` owns `stories/index.md` inside `okf:generated` markers like every other area: entries ordered deterministically (filename descending is newest-first for `work-YYYYMMDD-HHMMSS.md`), description taken from `summary:` with the existing fallback to the description the prior region already carried.

The reporter states the migration needs no special case: the file today is an H1 plus `* [...]` bullets, which is the shape the script first-touch rule already migrates losslessly into the marked form, and the prior-region fallback carries every existing description across.

What a maintainer would observe when it is done:

- Adding a story file and running `refresh-index.sh` produces that story index entry, with no `/report` run involved.
- Running `refresh-index.sh` twice on a clean tree still leaves it clean.
- An index whose entries were reordered, dropped or duplicated by a merge is repaired by regenerating it, not by hand.
