---
type: Mission
title: Make workaholify converge the repository state
slug: make-workaholify-converge-the-repository-state
status: active
merge_policy:
created_at: 2026-08-14T19:38:00+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.32
feedback: [20260814193737-workaholify-is-the-preparation-command-not-an-audit-converge-the-repository-state-by-running-the-living-migrations.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260814-104347
---

# Make workaholify converge the repository state

## Goal

`/workaholify` is the preparation command, not an audit (the developer's ruling, 2026-08-14, issue #445). The layout half already converges (`converge-layout.sh`); this mission carries the remainder: the wiring halves still stop at audit-and-offer, and nothing obliges the next structural change to register its migration at the converge seam.

## Experience

An operator runs `/workaholify` in a repository that predates recent structural changes and leaves with the repository actually prepared — wiring, bootstrap, and tree converged (each apply confirmed, report-only only as a named refusal) — and a future migration author finds a stated contract telling them where their migration must register.

## Acceptance

<!-- PROPOSED sketch - the reviewer interrogates this to drive-ready. -->

- [x] `/workaholify` applies the `CLAUDE.md` gateway reference and the web-bootstrap hook after one confirmation each, instead of stopping at "offer"; a refusal is named and report-only is its recovery path, never the ordinary outcome. (#20260814193833-apply-the-wiring-and-bootstrap-through-workaholify.md)
- [x] The gateway skill states the living-migration registry contract: `converge-layout.sh` is the one seam, and a structural change ships registered there in the same commit — with a check that every `gather/scripts/migrate-*.sh` is composed or named-excluded with a reason. (#20260814193833-state-the-living-migration-registry-contract.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-14 — ticket archived — 20260814193833-apply-the-wiring-and-bootstrap-through-workaholify.md
- 2026-08-14 — ticket archived — 20260814193833-state-the-living-migration-registry-contract.md
- 2026-08-14 — Story written (2 tickets; both acceptance items met) — work-20260814-104347.md
- 2026-08-14 — run recorded (+0.32h) — run-20260814-104347
