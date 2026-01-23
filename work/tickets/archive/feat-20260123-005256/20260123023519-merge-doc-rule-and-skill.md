# Merge Documentation Rule and Skill into Path-Specific Rule

## Overview

Consolidate `plugins/tdd/rules/documentation.md` and `plugins/tdd/skills/doc-writer/` into a single path-specific rule `plugins/tdd/rules/doc-specs.md` that applies only to `doc/specs/**`. This uses Claude Code's path-specific rules feature to automatically apply documentation standards when working in the docs directory. Delete the doc-writer skill since its instructions will be merged into the rule.

## Key Files

- `plugins/tdd/rules/documentation.md` - Current rule (to be renamed and merged)
- `plugins/tdd/skills/doc-writer/SKILL.md` - Skill to merge and delete
- `plugins/tdd/rules/doc-specs.md` - New consolidated rule with path restriction
- `plugins/core/commands/pull-request.md` - Remove doc-writer skill invocation

## Implementation Steps

1. **Create `plugins/tdd/rules/doc-specs.md`** with path-specific frontmatter:

   ```yaml
   ---
   name: doc-specs
   description: Documentation standards for doc/specs/
   paths: doc/specs/**
   ---
   ```

2. **Merge content from both sources**:

   - Documentation standards from `documentation.md` (file naming, format, structure, etc.)
   - Critical rules from doc-writer skill (document everything, no skipping, update READMEs)
   - PR-time workflow instructions from doc-writer skill

3. **Delete old files**:

   - `rm plugins/tdd/rules/documentation.md`
   - `rm -r plugins/tdd/skills/doc-writer`

4. **Update `plugins/core/commands/pull-request.md`**:

   - Remove the step that invokes doc-writer skill
   - The rule will automatically apply when working in doc/specs/
   - Add instruction: "Update documentation in `doc/specs/` based on archived tickets"

5. **Update any references** to the old rule path:
   - Check for references to `plugins/tdd/rules/documentation.md`

## Considerations

- Path-specific rules auto-load when context matches the path pattern
- No need for explicit skill invocation - rule applies automatically
- Simpler architecture: one rule file instead of rule + skill
- The `paths: doc/specs/**` ensures rule only loads for documentation work
