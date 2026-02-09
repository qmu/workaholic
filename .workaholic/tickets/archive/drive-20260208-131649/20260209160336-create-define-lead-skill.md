---
created_at: 2026-02-09T16:03:36+08:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: 01b44bd
category: Added
---

# Create define-lead Skill

## Overview

Create a new `define-lead` skill at `plugins/core/skills/define-lead/` that provides the authoritative schema template and guidelines for defining Leading Agents (leads) in the Workaholic plugin system. The skill codifies the schema currently documented in `memo.md` into a reusable skill that any agent or command can preload when creating or validating lead definitions.

## Key Files

- `memo.md` - Current source of the Leading Agent schema definition (to be codified into the skill)
- `plugins/core/skills/create-ticket/SKILL.md` - Reference for SKILL.md frontmatter conventions and structure
- `plugins/core/skills/analyze-policy/SKILL.md` - Reference for skills that provide template/guideline knowledge
- `plugins/core/skills/write-spec/SKILL.md` - Reference for skills with structured output formats
- `plugins/core/agents/drive-navigator.md` - Example agent with frontmatter (name, description, tools, skills)

## Related History

Past tickets established the skill extraction pattern and skill-to-skill composition model that this new skill follows.

- [20260131153043-allow-skill-to-skill-nesting.md](.workaholic/tickets/archive/feat-20260131-125844/20260131153043-allow-skill-to-skill-nesting.md) - Enabled skill-to-skill preloading via `skills:` frontmatter (same layer: Config)
- [20260131162854-extract-update-ticket-frontmatter-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131162854-extract-update-ticket-frontmatter-skill.md) - Extracted reusable skill with shell script from scattered logic (same pattern: knowledge extraction)
- [20260131153736-split-drive-workflow-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131153736-split-drive-workflow-skill.md) - Split monolithic skill into composable focused skills (same principle: thin orchestrators, comprehensive skills)

## Implementation Steps

1. **Create the skill directory and SKILL.md file**

   Create `plugins/core/skills/define-lead/SKILL.md` with standard frontmatter:

   ```yaml
   ---
   name: define-lead
   description: Schema template and guidelines for defining Leading Agents (leads) in the Workaholic plugin system.
   user-invocable: false
   ---
   ```

2. **Write the Schema Template section**

   Document the complete lead agent markdown template with all required sections, based on the schema in `memo.md`:

   - Frontmatter block with `name` (short, unique, `<speciality>-lead` format) and `description` (structured identity/purpose summary)
   - `# <Name>` heading
   - `## Role` section defining the agent's function
   - `## Responsibility` section (necessary condition - minimum duties)
   - `## Goal` section (sufficient condition - measurable completion objective)
   - `## Default Policies` section with four subsections:
     - `### Implementation` - coding standards, patterns, constraints
     - `### Review` - acceptance criteria, what to check and flag
     - `### Documentation` - format, tone, detail level, required sections
     - `### Execution` - sequencing, error handling, safety constraints

3. **Write the Guidelines section**

   Provide authoring guidelines that explain:

   - The relationship between Responsibility (necessary condition: "what must not be neglected") and Goal (sufficient condition: "what constitutes completion")
   - Naming conventions for leads (`<speciality>-lead` format)
   - Description writing guidance (structured summary of identity/purpose)
   - Policy writing guidance (each subsection should be specific and actionable, not aspirational)
   - How Default Policies interact with per-task overrides

4. **Write the Validation Checklist section**

   Provide a checklist for verifying a lead definition is complete and well-formed:

   - All four schema sections present (Frontmatter, Role, Responsibility/Goal, Default Policies)
   - All four Default Policy subsections present (Implementation, Review, Documentation, Execution)
   - Name follows `<speciality>-lead` format
   - Responsibility defines minimum duties (necessary condition)
   - Goal defines measurable completion (sufficient condition)
   - Each policy subsection contains concrete, actionable rules

5. **Write an Example section**

   Provide a minimal but complete example lead definition demonstrating all required sections with realistic placeholder content.

## Considerations

- The skill should codify `memo.md` content without duplicating it verbatim - `memo.md` can then be retired or reference the skill as the source of truth (`memo.md`)
- The skill has no shell scripts or `allowed-tools` since it is purely a knowledge/template skill, similar to `create-ticket` and `discover-ticket` (`plugins/core/skills/create-ticket/SKILL.md`)
- Future agents or commands that create lead definitions should preload this skill, following the "thin orchestrators, comprehensive skills" principle (`CLAUDE.md`)
- Consider whether the skill should also cover validation shell scripts in the future, but keep the initial scope focused on the schema template and guidelines only (`plugins/core/skills/define-lead/`)

## Final Report

Created `plugins/core/skills/define-lead/SKILL.md` as a pure knowledge skill (no shell scripts, no allowed-tools) following the same pattern as `create-ticket` and `discover-ticket`. The skill contains five sections: Schema Template (full markdown structure with fenced code block), Guidelines (naming conventions, description writing, responsibility vs goal semantics, default policy authoring, override behavior), Validation Checklist (11-item checklist), and Example (a complete `testing-lead` definition demonstrating all required sections with realistic content). All five implementation steps from the ticket are addressed in the single SKILL.md file.
