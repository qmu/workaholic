---
created_at: 2026-01-27T10:39:35+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Convert i18n rule to skill and preload in documentation agents

## Overview

The i18n rules in `plugins/core/rules/i18n.md` are not enforced during `/report` because documentation agents (spec-writer, terms-writer) only reference it as a passive rule, not a preloaded skill. Convert the `.workaholic/`-specific i18n content into a skill that agents preload, ensuring translations are always created alongside English docs.

Current state:
- `i18n.md` rule exists but agents just say "See `plugins/core/rules/i18n.md`"
- Agents don't preload i18n skill, so context doesn't include translation requirements

Desired state:
- Create `i18n` skill with `.workaholic/` translation enforcement
- Preload skill in spec-writer and terms-writer agents
- Keep `i18n.md` rule for general project i18n guidance
- Have `workaholic.md` rule reference the skill for `.workaholic/` specific rules

## Key Files

- `plugins/core/rules/i18n.md` - Extract `.workaholic/` section to skill
- `plugins/core/rules/workaholic.md` - Reference i18n skill
- `plugins/core/skills/i18n/SKILL.md` - New skill to create
- `plugins/core/agents/spec-writer.md` - Add i18n skill to preload
- `plugins/core/agents/terms-writer.md` - Add i18n skill to preload

## Implementation Steps

1. Create `plugins/core/skills/i18n/SKILL.md`:
   ```yaml
   ---
   name: i18n
   description: i18n requirements for .workaholic/ documentation.
   user-invocable: false
   ---
   ```

   Content should include:
   - File naming convention (`_ja.md` suffix)
   - README mirroring requirement (must update both language READMEs)
   - Translation workflow (create English first, then Japanese)
   - **CRITICAL**: When creating/editing any `.md` file in `.workaholic/`, MUST also create/update corresponding `_ja.md`

2. Update `plugins/core/rules/i18n.md`:
   - Remove the `.workaholic/ Directory Rules` section
   - Add reference: "For `.workaholic/` specific i18n, see the `i18n` skill"
   - Keep general project i18n guidance (README structure, folder-based vs suffix-based)

3. Update `plugins/core/rules/workaholic.md`:
   - Add note under structure: "i18n is enforced - see `i18n` skill for translation requirements"

4. Update `plugins/core/agents/spec-writer.md`:
   - Add `i18n` to skills list in frontmatter
   - Remove the "See `plugins/core/rules/i18n.md`" reference (now preloaded)

5. Update `plugins/core/agents/terms-writer.md`:
   - Add `i18n` to skills list in frontmatter
   - Remove the "See `plugins/core/rules/i18n.md`" reference (now preloaded)

## Considerations

- Skills preload content into agent context, ensuring i18n rules are always visible
- Rules are passive - agents may not read them unless specifically instructed
- The skill should be concise but emphatic about translation requirements
- story-writer doesn't need this (stories are branch-specific, not translated)
- changelog-writer doesn't need this (CHANGELOG.md is single-language)
