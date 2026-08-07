---
created_at: 2026-08-06T12:50:31+00:00
author: noreply@anthropic.com
assignees: [noreply@anthropic.com]
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: slim-commands-skills-and-docs-for-ai-agent-use
merge_policy:
---

# Make every command a thin skill-alias

## Overview

<!-- PROPOSED. Sharpened by the mission's approval interrogation. -->

Commands under `plugins/workaholic/commands/` should be thin aliases that name the
skill to run and pass arguments — the processing body belongs in the skill. Several
commands still carry orchestration and prose that duplicate their skill. The
`/propose` and `/implement` (routine) instructions are the same case: their real
work must live in the corresponding skill and be called from there. This is the
FB's item 1 and the "thin commands, comprehensive skills" design principle made
true everywhere.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/*.md` — each command; move any processing body into its skill.
- `plugins/workaholic/skills/*/SKILL.md` — the destination for logic that leaves a command.
- `CLAUDE.md` — the "Thin commands, comprehensive skills" principle and the commands table.

## Implementation Steps

1. Inventory each command in `commands/` and mark the prose that is orchestration
   the skill should own versus the few lines that must stay (skill name, args, notice).
2. Move each owned block into the command's skill; leave the command as a short alias.
3. Do the same for the routine instructions (`/propose`, `/implement`), pointing them
   at their skills.
4. Update `CLAUDE.md` and any doc that describes command bodies.

## Quality Gate

**Acceptance criteria:**

- Every command file is a short skill-alias with no standalone processing body.
- `/propose` and `/implement` route through their skills.

**Verification method:**

- Manual review of each `commands/*.md`; `node scripts/build-plugins/verify.mjs` passes.

**Gate:**

- No behavior regression in the workflow commands; docs updated in the same change.

## Considerations

<!-- The line between "orchestration a command may keep" and "logic a skill must own"
     needs a crisp rule; the approval interrogation should set it. -->
