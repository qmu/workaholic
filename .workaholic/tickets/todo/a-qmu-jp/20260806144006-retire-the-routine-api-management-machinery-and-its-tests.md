---
created_at: 2026-08-06T14:40:06+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on: 20260806144006-render-copy-paste-setup-sheets-from-structured-trigger-declarations.md
mission: retire-routine-management-into-a-setup-sheet
merge_policy:
---

# Retire the routine API management machinery and its tests

## Overview

PROPOSED. The API management machinery — `plan-routine-change.sh` /
`authorize-routine-change.sh` (the digest gate), `compare-routines.sh` /
`list-routines.sh` (drift and fleet reporting) — managed the half of a routine the API
exposes while blind to the half that decides whether it runs. Measured cost, 2026-08-06:
a paginated `list` (20 rows, unread `has_more`) was surveyed as the whole account, six
duplicate records were carefully updated through the digest gate while the real, wired
`[Propose]` ran a stale prompt beyond page one, and the "drift-free fleet" verdict was
wrong twice. The developer retired the surface: delete the machinery and its tests, and
correct every document that presents it as the management path.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/` — `plan-routine-change.sh`,
  `authorize-routine-change.sh`, `compare-routines.sh`, `list-routines.sh`,
  `lib/compare_routines.py`, `lib/list_routines.py`, `lib/routine_change.py`
- `scripts/test-workflow-scripts.mjs` — their assertion blocks
- `CLAUDE.md` `/setup-routines` and `/workaholify` rows; `workaholify/SKILL.md` §5
  (the digest-gate and drift prose); `docs/proposal-loop-runbook.md` §3
- Keep: `render-routine.sh`, `list-routine-templates.sh`, `resolve-repo-url.sh`,
  `check-slack-channel.sh`, `check-bootstrap.sh` — the sheet path and preconditions

## Implementation Steps

1. Land after the sheet ticket, so the command never has a gap where it does nothing.
2. Delete the four scripts and their libs; sweep the test suite's blocks for them.
3. Rewrite the docs' truth: routines are set up by a human in the UI from the plugin's
   sheets; the plugin neither reads nor mutates the account; the retired digest-gate
   prose survives only as the recorded reason (feedback record
   `20260806143907-routine-setup-is-a-human-act-the-plugin-makes-cheap`).
4. Rebuild `outputs/` and run the suite.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- No script under the plugin calls `RemoteTrigger`'s surface or reasons about live
  routine records; grep finds no `plan-routine-change`/`authorize-routine-change`/
  `compare-routines`/`list-routines` reference outside history/feedback records.
- Every current-truth document describes the sheet flow, not the retired management flow.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green after the deletions
- repo-wide grep for the retired script names

**Gate** — what must pass before approval:

- `depends_on` the sheet ticket; never merged ahead of it.

## Considerations

- The digest gate was itself a measured answer (substitution/batching); its reasoning is
  preserved in the feedback stream, and nothing here weakens the verbatim-confirmation
  bar for acts that remain — it removes the acts.
- `check-slack-channel.sh` stays: the sheet tells the developer to have `dev-<repo>`
  ready, and the probe's honest `checked: false` contract is still the right shape.
