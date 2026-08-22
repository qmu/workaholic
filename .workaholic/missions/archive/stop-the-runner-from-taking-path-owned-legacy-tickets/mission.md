---
type: Mission
title: Stop the runner from taking path-owned legacy tickets
slug: stop-the-runner-from-taking-path-owned-legacy-tickets
status: achieved
merge_policy:
created_at: 2026-08-14T10:29:59+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.55
feedback: [20260814102845-path-owned-legacy-todo-tickets-are-surveyed-as-team-owned-by-the-unattended-routine.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260814-110344
---

# Stop the runner from taking path-owned legacy tickets

## Goal

PROPOSED. P2 moved a ticket's owner from its directory into `assignees:` but left
the old layout tolerated: `list-todo.sh` surveys `todo/<user-slug>/*.md`,
`owners.sh` finds no field, `owns.sh` answers `unowned` — claimable by anyone.
Measured overnight 2026-08-13→14: ~10 PR-units driven and merged under one
developer's identity out of colleagues' queues.

## Experience

A runner on the old layout sees a colleague's path-owned ticket excluded as
`owned_by_other` and its own still offered; each drive converges the tickets it
touches without anyone running `/workaholify`; and a run whose claimed unit was
authored by someone else says so where a human reads it.

## Acceptance

- [x] A queued ticket under `todo/<user-slug>/` with no `assignees:` resolves to
      that slug through the one ownership oracle, so a colleague's legacy ticket is
      excluded from the survey, not offered as unowned. (#20260814103051-resolve-a-legacy-path-owned-ticket-to-its-owner.md)
- [x] `drive/scripts/archive.sh` runs `migrate-todo-owners.sh`, so an actively
      driven queue converges at the seam the migration's own header claims. (#20260814103051-converge-the-todo-layout-at-the-archive-seam.md)
- [x] `/implement`'s run report and finish line name a claimed unit whose tickets
      were authored by someone other than the runner's identity. (#20260814103051-name-a-unit-whose-tickets-are-not-the-runner-s.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-14 — ticket archived — 20260814103051-resolve-a-legacy-path-owned-ticket-to-its-owner.md
- 2026-08-14 — ticket archived — 20260814103051-converge-the-todo-layout-at-the-archive-seam.md
- 2026-08-14 — ticket archived — 20260814103051-name-a-unit-whose-tickets-are-not-the-runner-s.md
- 2026-08-14 — Story written (3 tickets; all acceptance items met) — work-20260814-110344.md
- 2026-08-14 — run recorded (+0.55h) — run-20260814-110344
- 2026-08-22 — mission achieved — mission.md
