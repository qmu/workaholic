---
type: Feedback
title: The Propose schedule migration includes discovery of assigned open issues, not just the trigger move
kind: instruction
source: discussion
created_at: 2026-08-12T22:56:50+09:00
author: a@qmu.jp
supersedes: 
---

# The Propose schedule migration includes discovery of assigned open issues, not just the trigger move

Converting [Propose] from a GitHub-triggered routine to a time-triggered routine was meant to include the migration of the routine's input: it should not require a specific feedback issue URL or ID handed in, but instead search the recent open FB issues on GitHub, filtered by assignee (the developer), on every hourly tick. The first migration moved only the trigger and left a pure clock tick reporting nothing_in_hand, which was recorded as an unresolved question rather than implemented.

Resolution (same day, this record's change): /propose now owns a Clock-fired discovery step — propose/scripts/list-inbound-issues.sh lists the open issues assigned to the session's own identity, oldest-first, excluding issues a feedback record already names (already_captured), and each returned issue is taken as an ask in hand through the full run. Unassigned issues are deliberately not taken (every developer's copy fires hourly; racing is the measured P8 failure), and no title-prefix filter is applied (an [FB] prefix was considered and rejected — /fb's cross-repository crossing deliberately adds no prefix to the issues it opens, so a title filter would drop exactly the asks the loop exists to ingest).
