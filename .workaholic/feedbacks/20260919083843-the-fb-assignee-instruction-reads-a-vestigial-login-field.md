---
type: Feedback
title: The /fb assignee instruction reads a vestigial login field
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T08:38:43+09:00
author: a@qmu.jp
supersedes: 
---

# The /fb assignee instruction reads a vestigial login field

Inbound ask captured by the maintenance tick from GitHub.

- Issue: https://github.com/qmu/workaholic/issues/1213
- Title as written: [FB] /fb still tells the runner to read the assignee from gh-rest.sh available, whose login is always empty
- Author: tamurayoshiya, opened 2026-09-18T19:34:36Z

Captured here rather than left to issue discovery because the issue carries no assignee, and `specificate/scripts/list-inbound-issues.sh` filters server-side on `assignee=<login>`: an unassigned [FB] issue is returned to no inbox and is ingested by nobody. Verified this tick — the lister returned an empty `issues` array and did not name #1213 even among its exclusions.

Pointer and title only; the issue is the durable text.
