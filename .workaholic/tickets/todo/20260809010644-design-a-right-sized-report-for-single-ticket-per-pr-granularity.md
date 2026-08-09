---
created_at: 2026-08-09T01:06:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: right-size-report-to-single-ticket-per-pr-granularity
merge_policy:
---

# Design a right-sized /report for single-ticket-per-PR granularity

## Overview

The loop now merges a PR per single ticket rather than batching a whole
Story's worth of tickets into one PR (`docs/loop-engineering-workflow.md`
G1/P1). `/report`'s current scope is sized around reporting on a whole
Story's volume of work, so it now costs more time and output than the unit
it is reporting on (FB `20260809010511-lighten-report-now-that-prs-are-
merged-per-single-ticket-without-losing-result-records-or-cross-document-
relations.md`).

This ticket is the design half: read `/report`'s current workflow end to
end (`plugins/workaholic/skills/report/`), name what it does today that a
single-ticket-sized run does not need, and produce a written design for a
right-sized `/report` — narrower unit of work, and/or a trimmed per-run
procedure — that keeps exactly two things intact: the recording of results
(whatever `/report` currently persists about what was done and its
outcome) and the cross-document relations (the FB → Proposal →
Implementation → Report chain a human or agent can navigate). No
implementation in this ticket; the output is a design a human reviews
before the companion implementation ticket proceeds.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:planning` — scoping a change against the project's existing workflow before implementation begins

## Key Files

<!-- The files this ticket would touch, each with why it is relevant. -->

- `plugins/workaholic/skills/report/` — the skill whose per-run scope and cost are in question
- `plugins/workaholic/skills/review-sections/` — generates the branch story's Motivation/Outcome/Concerns/Patterns content `/report` assembles
- `plugins/workaholic/commands/report.md` — the command's entry-point contract
- `CLAUDE.md` (`/report` row, Development Workflow) — the doc that must describe whatever the design lands on

## Implementation Steps

1. Read `/report`'s current workflow and measure what it does per run today (sections generated, subagents fanned out, scripts invoked) against a single-ticket branch's actual size.
2. Identify what is Story-shaped rather than ticket-shaped in that scope, and what must not be trimmed: the result record and the cross-document relations named above.
3. Write the design (as this ticket's Overview/Considerations, or a linked note) — the new unit of work `/report` reports on, and/or the sections/steps to drop or shrink — with enough detail that the companion implementation ticket needs no further design decisions.
4. Name explicitly, in the design, how each preserved thing (results record, relations) is carried under the new shape.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A written design exists naming `/report`'s right-sized unit of work and/or its trimmed per-run steps.
- The design states explicitly how the results record and the FB/Proposal/Ticket/Report relations survive the resizing.

**Verification method** — the commands/tests/probes that prove them:

- Review of the design document/section against the two preservation requirements above.

**Gate** — what must pass before approval:

- A human reviewer confirms the design does not silently drop result recording or cross-document traceability.

## Considerations

- This is a design ticket, not an implementation one — resist the temptation to also change `/report`'s scripts here; that is the companion ticket's job once this design is reviewed.
- Some of `/report`'s current per-run cost may already be justified even at single-ticket granularity (e.g. the branch-safety scan `/report` warns on); the design should say which parts are genuinely Story-sized versus load-bearing at any size.
