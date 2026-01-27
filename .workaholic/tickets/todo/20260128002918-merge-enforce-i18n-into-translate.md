---
created_at: 2026-01-28T00:29:18+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Merge enforce-i18n skill into translate skill

## Overview

The `enforce-i18n` skill contains `.workaholic/`-specific translation requirements, while `translate` contains general translation policies. These are closely related and both deal with i18n concerns. Merge them into a single `translate` skill that includes both the policies and the enforcement rules for `.workaholic/` documentation.

This reduces skill fragmentation and consolidates all translation-related guidance in one place.

## Key Files

- `plugins/core/skills/translate/SKILL.md` - Skill to expand with enforcement rules
- `plugins/core/skills/enforce-i18n/SKILL.md` - Skill to merge and delete
- `plugins/core/agents/spec-writer.md` - Agent that preloads enforce-i18n
- `plugins/core/agents/terms-writer.md` - Agent that preloads enforce-i18n
- `plugins/core/skills/write-spec/SKILL.md` - References enforce-i18n
- `plugins/core/skills/write-terms/SKILL.md` - References enforce-i18n

## Related History

The enforce-i18n skill was extracted from a rule to ensure translation requirements were preloaded into documentation agents.

Past tickets that touched similar areas:

- `20260127103935-convert-i18n-rule-to-skill.md` - Created enforce-i18n as a preloadable skill (same files)
- `20260124112637-add-translate-skill.md` - Created translate skill with translation policies (same files)

## Implementation Steps

1. **Merge enforce-i18n content into translate**:
   - Add a new section "## .workaholic/ Translation Requirements" to translate SKILL.md
   - Include the critical rule about always creating `_ja.md` translations
   - Include file naming conventions (`_ja.md` suffix)
   - Include README mirroring requirements
   - Include the workflow (English first, then Japanese)

2. **Update agents to preload translate instead of enforce-i18n**:
   - In `plugins/core/agents/spec-writer.md`: change `enforce-i18n` to `translate` in skills list
   - In `plugins/core/agents/terms-writer.md`: change `enforce-i18n` to `translate` in skills list

3. **Update skill references**:
   - In `plugins/core/skills/write-spec/SKILL.md`: change "preloaded `enforce-i18n` skill" to "preloaded `translate` skill"
   - In `plugins/core/skills/write-terms/SKILL.md`: change "preloaded `enforce-i18n` skill" to "preloaded `translate` skill"

4. **Delete enforce-i18n skill directory**:
   - Remove `plugins/core/skills/enforce-i18n/` entirely

## Considerations

- The translate skill becomes the single source of truth for all i18n concerns
- The enforcement rules are specific to `.workaholic/` but fit naturally within the broader translation skill
- Agents will receive more context (full translation policies) but this is beneficial for quality
- The merged skill should clearly separate general policies from `.workaholic/`-specific enforcement
