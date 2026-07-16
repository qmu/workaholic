---
type: Concern
concern_id: commit-release-note-sh-s-push
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
status: active
resolved_by_pr:
resolved_by_commit:
---

# commit-release-note.sh's push failure is the more expensive one and had no test at all

## Description

[1fcce15d](https://github.com/qmu/workaholic/commit/1fcce15d) surfaced the push outcome for both pushing scripts, but the two failures are not equally costly and only one had ever been tested. If `commit-release-note.sh`'s push fails, its note is committed locally but is **not** on the branch the PR merges — so the release ships without its note, silently. `extract-deferred-concerns.sh`'s failure merely diverges local `main`. The mitigation added is prose: `ship/SKILL.md` now says to push before merging on `pushed:false`. That is a rule an agent must read and obey, on a path where the previous rule ("the push prevents a one-commit-ahead divergence", in the script's own header) was already being silently violated.

## How to Fix

Consider making `commit-release-note.sh`'s push failure a hard stop *before the merge* rather than a reported best-effort — unlike the post-merge case, nothing has landed yet, so aborting is cheap and the `|| true` reasoning (the merge already happened; do not abort) does not apply. At minimum, keep the five measured push cases green and add one asserting the release-note branch state after a failed push.
