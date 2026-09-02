---
created_at: 2026-09-02T04:26:30+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
merge_policy:
verification_handoff: 
---

# Localize which step posted each of the three corrected lines

## Overview

PROPOSED. The operator corrected three behaviours by quoting what the channel said, not by
naming a step. One of the three — "the stuck-prs step" — is a name no step in
`workaholic:moderate` carries; the candidates are `catchup-blocked`,
`stranded-publications` and `stalled-units`, and which of them produced each line decides
what the rest of this mission edits.

This is the mission's diagnosis step and it changes no behaviour. Guessing here means the
next four tickets edit the wrong step and the operator sees the same posts again.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/reference/workflow.md` — the per-step specs; each
  step's question and event wording is composed here.
- `plugins/workaholic/skills/moderate/scripts/step-catchup-blocked.sh`,
  `step-stranded-publications.sh`, `step-stalled-units.sh` — the three candidates.
- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — the source of the
  `unanswerable` class the "GitHub has not computed mergeability" line reports.
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` — carries the
  same class onto a publication row.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shapes the lines were
  emitted in; which shape carried each line narrows the step.

## Implementation Steps

1. Take the three quoted behaviours one at a time: (a) *some pull requests could not be
   merged because GitHub had not yet computed mergeability*; (b) *we do not rebase here;
   generated-index conflicts are catch-up's to resolve and content conflicts belong to the
   claim holder*; (c) *the stuck-prs step*.
2. For each, find the composing surface in the tree — the step script, its spec in
   `moderate/reference/workflow.md`, and the shape it rendered into. Search the wording,
   not the step name; the operator quoted output.
3. Record the mapping in the ticket's own findings and in the mission's `## Changelog`:
   quoted line → step id → file and section. Where a line was composed by the agent from a
   step's spec rather than by a script, say so — the repair is then the spec.
4. Where a quoted line maps to no step, say that too, and name the nearest candidates with
   the evidence for each. An honest *not found* is the outcome; inventing a step id is not.
5. Name, for each mapped step, whether it currently acts or only reports — that is the fact
   the four following tickets are written against.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each of the three quoted behaviours has a named composing surface, or an explicit
  *not found* with the candidates and their evidence.
- The mapping is recorded where the following tickets can read it.

**Verification method** — the commands/tests/probes that prove them:

- The recorded mapping cites file and section for each line; a reader can open each one.

**Gate** — what must pass before approval:

- No behaviour change: the diff touches findings and the mission changelog only.

## Considerations

- "stuck-prs" may be the operator's name for a behaviour rather than a step id. Treat the
  quoted behaviour as authoritative and the name as a description.
