---
created_at: 2026-08-30T04:28:03+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: catch-a-reported-claim-up-before-its-conflict-hardens
merge_policy:
verification_handoff: 
---

# Take the act on every catchable claim in the run

## Overview

PROPOSED. The caller is what changes. `/implement` walks the new reader beside its
existing `undelivered[]` loop, one `catch-up-claim.sh` run per candidate. The writer
is untouched: it re-derives its own verdict at the moment of the act and applies its
own refusals, which is exactly why widening the caller is safe.

**A unit in both sets is caught up once, not twice.** The `undelivered[]` entries
already receive a catch-up before their retry; a second run over the same unit would
report `already_current` and cost a worktree for nothing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §6's catch-up step, currently reached
  only from the `undelivered[]` loop
- `plugins/workaholic/skills/drive/reference/routing.md` — the invocation
- `plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` — the reader
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — unchanged by this
  ticket

## Implementation Steps

1. Read `drive/SKILL.md` §6 and `reference/routing.md` whole before editing: the
   catch-up is a numbered step of an existing route, and the widening must join that
   route rather than opening a second one.
2. Walk `list-catchable-claims.sh` beside the `undelivered[]` loop, one
   `catch-up-claim.sh` run per candidate, **once each**.
3. Deduplicate across the two sets by unit id, so a unit in both is caught up once.
   State which loop takes it, so the outcome is reported in one place.
4. The act stays **per candidate**, never batched and never retried inside the run: a
   refusal is reported, not worked around.
5. Change nothing about the writer, the survey, the claim oracle or any gate; no
   token moves in this ticket (reporting is the next two).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every candidate the reader names gets exactly one `catch-up-claim.sh` run
- A unit in both candidate sets is caught up once
- A run with no candidates behaves byte-identically to today
- No gate, route, demotion, claim or survey reads the new set

**Verification method** — the commands/tests/probes that prove them:

- The drill rows added by this mission's last ticket
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `catch-up-claim.sh`, `list-claims.sh` and `plan-units.sh` byte-identical

## Considerations

- The cost per tick is one worktree, one merge and one push per candidate. With the
  `clean` filter in the reader the steady state is zero candidates, so measure the
  idle case and confirm the widening costs a run nothing when nothing is catchable.
- `/drive` (attended) and `/implement` (unattended) share the Unified Run: decide
  explicitly whether the attended entry point walks it too, and say which.
