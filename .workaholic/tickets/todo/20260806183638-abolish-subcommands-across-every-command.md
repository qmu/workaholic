---
created_at: 2026-08-06T18:36:38+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: reduce-the-loop-to-two-routines-and-one-behaviour-per-command
merge_policy:
---

# Abolish subcommands across every command

## Overview

PROPOSED. Several commands fork on a first word — `/mission close <slug>` versus a free-form
instruction versus a bare listing; `/ticket summary` versus a description; `/setup-routines`
with an optional repository name. Each fork is a second command wearing one name, and it is
the shape that makes a surface hard to learn and hard to document. Every command takes
arguments and has exactly one behaviour.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/*.md` — the whole command surface
- `plugins/workaholic/skills/mission/SKILL.md` — create / replan / list / close
- `plugins/workaholic/skills/create-ticket/SKILL.md` — create versus summary
- `CLAUDE.md` — the Commands table, which documents each fork
- `scripts/test-workflow-scripts.mjs` — pins that name a subcommand

## Implementation Steps

1. Inventory every command that forks on a first word, and what each fork does.
2. For each, decide the one surviving behaviour and where the others go — a separate
   command, or nothing. Record the decision per fork rather than in bulk.
3. Apply, updating the Commands table in the same change.
4. Re-point the tests and the docs that name a retired form.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- No command's behaviour depends on the first word of its argument.
- Every retired fork is either a command of its own or recorded as deliberately dropped.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Read the Commands table as a newcomer: one row, one behaviour

**Gate** — what must pass before approval:

- No behaviour is silently lost; a dropped fork is named as dropped.

## Considerations

- `/mission close` is the only sanctioned way to end a mission today. Whatever replaces it
  must keep that single-writer property, or the archive move grows a second path.
- This is the widest-blast-radius ticket of the four; sequencing it last keeps the routine
  work independent of it.
