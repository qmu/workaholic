---
type: Feedback
title: Both sub-floor missions are resolved: one replanned, one pre-rule history
kind: insight
source: discussion
created_at: 2026-08-04T20:36:13+09:00
author: a@qmu.jp
supersedes: 
---

# Both sub-floor missions are resolved: one replanned, one pre-rule history

The ticket floor shipped on 2026-08-04. This records what the two sub-floor missions on record turned out to need, so a later audit is not re-run from scratch.

**The live one resolved itself before the cleanup reached it.** `make-the-branch-story-measurably-shorter` was minted with zero tickets by `close.sh --successor-title` — the seam the floor has since removed — and the cleanup ticket (`20260804173626`) was written expecting to decide between replanning it and dissolving it into a ticket plus a feedback record. It was replanned first, in the ordinary way, and now carries two tickets: `20260804201653-measure-which-story-sections-carry-the-growth.md` and `20260804201653-fix-the-measured-cause-and-verify-a-shorter-story.md`. So the dissolve path was never needed, and the mission stands as genuinely wanted work. The measurement behind it survives into those tickets: stories averaged 127 lines across eight before the predecessor mission’s structural changes and 164 across ten after — a 29% increase, cause still unfound, which is the successor’s whole justification.

**The archived one is pre-rule history and stays untouched.** `drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main` (archived, one ticket) predates the floor and shipped fine. History is never rewritten, so the file is not edited and the mission is not re-opened; the annotation lives here and in `mission/SKILL.md`. An auditor reading `missions/archive/` against the floor should stop at that sentence rather than filing it — the floor is a rule about **creation**, so only `missions/active/` is auditable against it.

**State at the moment the rule shipped:** four active missions, at 4, 4, 2 and 4 tickets. `check-floor.sh <slug>` over `missions/active/*` is the whole audit, which is why no separate audit script was written — a second script whose entire content is that loop is a maintenance surface carrying no information the per-mission verdict does not already give.
