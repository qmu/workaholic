---
created_at: 2026-08-06T18:36:38+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission: reduce-the-loop-to-two-routines-and-one-behaviour-per-command
merge_policy:
---

# Split drive into an interactive drive and an unattended implement

## Overview

PROPOSED. `/drive` currently carries both forms behind one name: bare `/drive` is attended
and asks which units to take, `/drive auto` is unattended and asks nothing (decision O1,
2026-08-05). The developer's ruling retires that split — the unattended executor becomes
**`/implement`**, and `/drive` goes back to being the interactive command it was, with its
confirmation dialog. One name, one behaviour.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/drive.md` — the two-form contract and the §2 selection
- `plugins/workaholic/skills/drive/SKILL.md` — the Unified Run; the *attended / unattended*
  distinction runs through §2 and the terminal-token table
- `plugins/workaholic/commands/` — where `implement.md` is added
- `docs/drive-loop-runbook.md` — names `/drive auto` as the loop's invocation
- `scripts/test-workflow-scripts.mjs` — the fourteen pins that assert the `auto` token

## Implementation Steps

1. Decide where the run knowledge lives: the two commands share a survey/claim/route
   spine, so it stays one skill with two entry points rather than a forked copy.
2. Add `/implement`, taking the artifact to implement as its argument; it is prompt-free
   at every step and keeps the terminal contract.
3. Return `/drive` to the interactive shape, with the confirmation dialog restored.
4. Re-point every caller and pin that names `/drive auto`, including the runbook.
5. Update `CLAUDE.md`, the SKILL and the docs in the same commit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `/implement <artifact>` runs unattended end to end and issues no prompt at any step.
- `/drive` asks for confirmation, and no document or test still names `/drive auto`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with the `auto`-token pins re-pointed
- `node scripts/build-plugins/build.mjs` then `verify.mjs`

**Gate** — what must pass before approval:

- The terminal contract (`N units: …` + `ok`/`pending`) is unchanged for `/implement`.

## Considerations

- The `auto` token is load-bearing in five places today; a rename that misses one leaves a
  caller sitting on a prompt with nobody to answer it.

## Final Report

Development completed as planned. `/implement` is the unattended executor, `/drive` is
attended only, and both are thin entry points over the one Unified Run in
`skills/drive/SKILL.md`.

### Discovered Insights

- **Insight**: The `auto`/`night` first words were only half the duplication. The
  step-0 freshness table lived in `commands/drive.md`, so splitting the command in
  two would have produced two copies of it — and the routine-template lesson
  (a prompt that duplicates a procedure is a second source of truth, and the drift
  is one-directional) applies to a command file exactly as it does to a routine
  prompt. The table moved into the skill's §1 and both commands now defer to it.
  **Context**: Any future entry point onto this run inherits the tables for free;
  a change to a refusal reason is made once. `testDriveFreshnessContract` was
  re-pointed at the skill to pin that the copy does not come back.
- **Insight**: The optional `<unit>` argument is deliberately a *scope*, not a mode.
  That distinction is what keeps this a split rather than a new fork — the very
  thing the mission abolishes — and it is pinned as its own assertion.
  **Context**: If a future change makes the argument select a behaviour, the
  command has grown a subcommand again under a different spelling.
- **Insight**: `/drive` keeps the "ask nothing when there is nothing to choose"
  carve-out rather than confirming unconditionally, even though the ticket's
  acceptance reads as "asks for confirmation". `rules/interaction.md`'s
  Recommended-label test forbids a prompt whose first option could honestly be
  marked *(Recommended)*, and "drive the one claimable unit?" is exactly that.
  **Context**: The always-loaded rule outranks a phrase in a provisional gate;
  the reasoning is now written into the skill next to the carve-out so the next
  reader does not re-litigate it.
