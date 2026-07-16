---
type: Concern
concern_id: the-carried-concern-corpus-has-outgrown
mission: []
tickets: [20260715213320-surface-the-ship-flow-push-outcome.md, 20260715213321-compound-concern-identity-and-provenance.md, 20260715213322-scope-trip-mode-to-the-branch.md, 20260715215008-summary-unassigned-missions.md, 20260716012845-mission-interrogation-emits-ticket-set.md, 20260716012846-enforce-quality-gate-section.md, 20260716012847-drive-a-mission-authorized-queue.md, 20260716012848-mission-carry-over-successor.md, 20260716021000-gate-sh-worktree-port-resolution.md, 20260716102950-mission-describes-experience-not-gate.md, 20260716102951-drive-writes-tickets-for-midrun-problems.md, 20260716102952-mission-position-is-always-reported.md]
origin_pr: 87
origin_pr_url: https://github.com/qmu/workaholic/pull/87
origin_branch: work-20260715-213222
origin_commit: 9065d7a1
created_at: 2026-07-16T12:06:03+09:00
first_seen: 2026-07-16T12:06:03+09:00
last_seen: 2026-07-16T12:06:03+09:00
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Promoted to ticket 20260716163003-concern-machinery-robustness.md (2026-07-16 triage-to-zero): measure the PR body against the 65,536-char limit with a section-6 fallback. Risk now tracked in the queue.
closed_at: 2026-07-16T17:09:47+09:00
---

# The carried-concern corpus has outgrown the GitHub PR body

## Description

`create-or-update.sh` failed on this branch with `GraphQL: Body is too long (maximum is 65536 characters)`. The story body is ~80KB, of which section 6 alone is ~41KB: 29 carried concerns plus 11 new. The report skill states the story "IS the PR description", and nothing in the flow measures the body against GitHub's 65,536-character limit, so the PR simply does not get created — a hard stop at the last step of `/report`, after the story is written, committed and pushed. It is not a one-off: the corpus grows every ship, each carried block is prepended verbatim to every subsequent story, and 29 is where it broke. The next branch starts from at least 31.

## How to Fix

Have `create-or-update.sh` measure the stripped body and, when it exceeds the limit, render section 6 as the new concerns plus a link to the story file for the carried set — instead of failing. The story file must stay complete regardless: `extract-deferred-concerns.sh` reads `.workaholic/stories/<branch>.md`, not the PR body, so trimming the rendering is safe while trimming the file would silently drop institutional memory. Doing it in the script also removes the temptation to trim the file by hand under time pressure. Consider whether a corpus that only ever grows needs a retirement path (this branch's triage archived 5 of 32, and minted 2).
