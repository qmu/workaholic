---
type: Feedback
title: Workaholify is the preparation command not an audit - converge the repository state by running the living migrations
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-14T19:37:37+09:00
author: a@qmu.jp
supersedes: 
---

# Workaholify is the preparation command not an audit - converge the repository state by running the living migrations

The developer's ruling, restated 2026-08-14: `/workaholify` is the preparation command — what a repository runs to be able to use workaholic consistently — and that covers state, not just wiring. Measured 2026-08-13 → 08-14: a repository on the pre-P2 `todo/<user-slug>/` layout was reported fully conformant by `/workaholify` while its legacy queue let an [Implement] routine merge colleagues' path-owned tickets overnight (issue #444). The living migrations converge only at write seams, so a repository that predates a structural change stays on the legacy shape indefinitely while the audit calls it clean.

The ask: (1) make `/workaholify` apply, not report — converge the CLAUDE.md wiring, the bootstrap, the routines (per FB 20260813205116), and the `.workaholic` tree's layout by running every living migration as part of the command's own end-to-end flow; a confirmation before applying is acceptable, stopping at a rendered report is not, and report-only remains the recovery path for a named refusal. (2) State that contract in the gateway skill — a single registry of living migrations the command walks — so every future structural change registers its migration at this seam and the next P2-shaped change cannot leave repositories on a layout the current plugin misreads while `/workaholify` calls them conformant.

Already landed before this record was captured: `converge-layout.sh` (2026-08-14, issue #436's reshape mission) composes `migrate-todo-owners.sh` and `migrate-ticket-states.sh` through `/workaholify` and reports the judgment-needing residue. This record captures the remainder of the ask: the wiring/bootstrap halves still stop at audit-and-offer, and the registration contract is not yet stated as an obligation on future migrations.

Source: https://github.com/qmu/workaholic/issues/445
