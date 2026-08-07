---
created_at: 2026-08-06T12:50:31+00:00
author: noreply@anthropic.com
assignees: [noreply@anthropic.com]
type: refactoring
layer: [Config]
effort: 1h
commit_hash:
category: Changed
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

## Final Report

Development completed as planned. All 14 commands are now thin skill-aliases (850 → 203 lines total; each 12–18 lines): frontmatter kept verbatim, the `workaholic:policy-lens` sentinel kept in exactly the six commands the hook matches, the long Notice / plugin-boundary paragraphs replaced by a one-line namespace echo, and every command body reduced to the skill + section to run plus what is entry-point-specific. Unique orchestration moved into the owning skills: mission command flows → `skills/mission/reference/command-flows.md`; ticket publish/present flow → `skills/create-ticket/` (+ `reference/publishing.md`); propose workflow → `skills/propose/reference/workflow.md`; fb capture/crossing routing → `skills/feedback/SKILL.md`; small load-bearing rules → commit/ship/workaholify SKILLs. The two routine templates were trimmed to thin pointers with their machine-read frontmatter and four-line prompts byte-identical (render-setup-sheet.sh contract verified). CLAUDE.md's Design Principle and boundary-echo sentences updated.

### Discovered Insights

- **Insight**: 40 smoke tests pin exact prose in command markdown; they fail after the move although every rule survives in the skills/reference files.
  **Context**: The suite treats command bodies as the rule's address. Retargeting/pruning these assertions is exactly the pare-tests ticket's scope and is handled there, so this branch is green at its head.
- **Insight**: `mission/reference/scripts.md` still advertised the refused `--successor-title` flag; fixed here as a truthfulness repair while relocating the mission flows.
  **Context**: close.sh's header is the authority — the flag is refused by the ticket floor.
