---
created_at: 2026-08-06T18:36:38+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
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
