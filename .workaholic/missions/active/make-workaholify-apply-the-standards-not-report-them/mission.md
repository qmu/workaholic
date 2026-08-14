---
type: Mission
title: Make workaholify apply the standards, not report them
slug: make-workaholify-apply-the-standards-not-report-them
status: active
merge_policy:
created_at: 2026-08-14T10:37:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260814103718-workaholify-is-the-preparation-command-so-it-must-apply-rather-than-report.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Make workaholify apply the standards, not report them

## Goal

PROPOSED. `/workaholify` is the preparation command, but its flow still ends in
"report what conforms and what needs fixing". The tree half converges already
(`converge-layout.sh`); the rest does not — `CLAUDE.md` is audited and a reference
*offered*, the bootstrap *checked*, §5 renders sheets though `/setup-routines`
configures directly. The migrations are hardcoded in one script, so the next
P2-shaped change can be forgotten there as `migrate-todo-owners.sh` was at
`archive.sh` (issue #444).

## Experience

Running `/workaholify` in an unprepared repository leaves it prepared: gateway
reference written, bootstrap current, routines configured, tree converged.
Report-only survives as a named refusal's recovery path, not the ordinary outcome.

## Acceptance

- [ ] Living migrations are declared in one registry the command walks, and the
      gateway skill states that a structural change registers its migration there. (#20260814103811-walk-a-registry-of-living-migrations.md)
- [ ] `/workaholify` writes the `CLAUDE.md` gateway reference and installs or
      refreshes the web bootstrap hook, rather than offering and reporting them. (#20260814103811-apply-the-gateway-reference-and-the-bootstrap.md)
- [ ] §5 configures the routines instead of rendering sheets; sheets remain the
      recovery path for the named `no_transport` refusal. (#20260814103811-configure-routines-instead-of-rendering-sheets.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
