---
type: Feedback
title: `/fb` still commits without pushing, so its records never reach `/propose`
kind: concern
source: development
created_at: 2026-07-30T11:16:00+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: fb-still-commits-without-pushing-so
owner: 
mission: []
tickets: []
origin_pr: 103
origin_pr_url: https://github.com/qmu/workaholic/pull/103
origin_branch: work-20260729-193859
origin_commit: 2e7f1b00
last_seen: 2026-07-30T11:16:00+09:00
---

# `/fb` still commits without pushing, so its records never reach `/propose`

## Description

Two of the new tickets independently flag it in their Considerations: `commands/fb.md` step 4 commits without pushing and never guards on `main`, so a feedback registered from a work branch never reaches `/propose`'s cursor, which reads records *merged to main*. It is the same invisibility defect the whole ticket batch exists to remove for tickets and missions, and it is explicitly declared out of scope in both. The branch touched `fb.md` for the rename and left the defect in place, so the file now carries a correctness fix and a known correctness gap in the same commit.

## How to Fix

Once the publish-tree primitive lands, add a fifth ticket routing `/fb`'s write through it, identically to `/ticket` — the tickets already name it as the intended follow-up. Until then, note the gap in `feedback/SKILL.md` so a developer registering feedback mid-branch knows the proposal loop will not see it until the branch merges.
