---
type: Feedback
title: Nothing invokes the worktree reaper
kind: concern
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T08:39:22+09:00
author: a@qmu.jp
supersedes: 
---

# Nothing invokes the worktree reaper

Inbound ask captured by the maintenance tick from GitHub.

- Issue: https://github.com/qmu/workaholic/issues/1212
- Title as written: [FB] Nothing ever invokes reap-worktrees.sh, so worktrees accumulate without bound
- Author: tamurayoshiya, opened 2026-09-18T19:24:30Z

Captured here rather than left to issue discovery because the issue carries no assignee, and `specificate/scripts/list-inbound-issues.sh` filters server-side on `assignee=<login>`: an unassigned [FB] issue is returned to no inbox and is ingested by nobody. Verified this tick — the lister returned an empty `issues` array and did not name #1212 even among its exclusions.

Pointer and title only; the issue is the durable text, and the measurements it carries were taken in another repository.
