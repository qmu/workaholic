---
type: Feedback
title: Archiving a mission leaves its active index entry, so the base index lists it twice
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-09-10T13:19:57+09:00
author: a@qmu.jp
supersedes: 
---

# Archiving a mission leaves its active index entry, so the base index lists it twice

The commit that archives a mission adds its `archive/` index line and never removes the `active/` one, so the base's own index names one mission in two lifecycle states - and every checkout that regenerates the index is permanently dirty against the base.

## Measured (2026-09-10, moderation tick 20260910-040330)

On `origin/main` at 6af7d00d8:

    6:   * [report-a-native-tick-...](active/report-a-native-tick-.../mission.md)  - ...
    124: * [report-a-native-tick-...](archive/report-a-native-tick-.../mission.md) - ...

`git show 6af7d00d8 --name-status -- .workaholic/missions/` answers, in that one commit:

    R065  .workaholic/missions/active/report-a-native-tick-.../mission.md -> .workaholic/missions/archive/report-a-native-tick-.../mission.md
    M     .workaholic/missions/index.md

and the index diff is `1 file changed, 1 insertion(+)` - the archive bullet appended, the active bullet untouched. The mission file exists only under `archive/`; the index says it is also active.

## The consequence, which is the reason this is filed rather than tidied

`okf/scripts/refresh-index.sh` regenerates from the tree, so any seam that refreshes an index in a working checkout removes the stale `active/` line. That single-line deletion is residue no clear can settle: `classify-residue.sh` proves it `regenerable`, `clear-proved-residue.sh` restores the path and re-runs the generator, and the generator writes the correction straight back. Measured this tick, twice in a row:

    {"counts":{"on_base":0,"regenerable":2,"untracked":0,"divergent":0,"unanswerable":0,"total":2}}

with `.workaholic/missions/index.md` in it both times. `sync-main.sh` refuses `dirty_workspace` on any unclean tree, so this is the same permanent stall the mission `clear-the-residue-the-base-already-holds-and-never-stop-silently` shipped its mechanism to end - reached this time from a stale generated file on the base rather than from anything a run left behind.

## What this is NOT a duplicate of

- `20260909202359` names the clear restoring to HEAD while proving against the base, and a `moderations/` bullet the base cannot hold. Neither term is this: the two refs agree about this path's content and the offending line is a real mission bullet.
- `20260909202703` names `persist-log.sh --record` landing a feedback record without refreshing `feedbacks/index.md` - a MISSING entry from a different seam. This is a SURVIVING entry from the mission archive seam.

The three share one outcome and have three separate causes; only this one is unfiled.

## Bounds observed

The tick reported and did nothing else. It committed no index, pushed no branch, opened no pull request, and closed, moved or re-listed no mission: `close.sh` remains the only writer of an end state.
