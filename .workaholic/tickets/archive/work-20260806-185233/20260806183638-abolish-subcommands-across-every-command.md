---
created_at: 2026-08-06T18:36:38+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
category: Changed
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

## Final Report

Development completed as planned. No command's behaviour depends on the first word of
its argument. Every fork was inventoried and decided separately, and the inventory is
recorded in `CLAUDE.md` and as decision P5 rather than summarized in bulk.

### Discovered Insights

- **Insight**: Two of the four forks were **deprecation stubs for modes already
  retired**. `/mission summary` went on 2026-07-22 and `/mission approve` on
  2026-07-31, but each left a branch intercepting its literal to print a courtesy
  message — and that stub *was* the surviving fork. It also kept reserving a word
  no mission could be titled, months after the behaviour it named was gone.
  **Context**: A retirement is not finished while its stub still dispatches. The
  new surface pin greps for the dispatch shape, not for the word, so a
  reintroduced stub fails.
- **Insight**: `close` is the one fork that could not be dropped, and the reason
  is a property rather than a preference: `close.sh` is the only sanctioned writer
  of a mission's end state, and that single-writer property is what keeps the
  archive move from growing a second path. The ticket's own Considerations flagged
  it, and it is why the behaviour **moved** to `/mission-close` rather than going
  away.
- **Insight**: Writing the new command surfaced stale prose it inherited —
  `--successor-title` was still offered ("a title to mint one") although the
  ticket floor has refused it since 2026-08-04. Relocating text is a good moment
  to check it against the code it describes; the extraction is what made it
  visible.
- **Insight**: Bare-versus-argument was deliberately left alone, and the
  distinction is worth keeping explicit: `/ticket` with nothing described reports
  rather than writes, `/mission` with nothing named plans over all of yours. Those
  are **scopes**, not modes selected by a word, and the acceptance criterion is
  literally about the first word. Reading it wider would have meant two more new
  commands on the widest-blast-radius ticket of the mission; the reading is
  recorded in P5 so a reviewer can disagree with it rather than having to infer it.
