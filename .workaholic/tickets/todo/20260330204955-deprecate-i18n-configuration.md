---
created_at: 2026-03-30T20:49:55+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Deprecate I18n-Related Configuration

## Overview

The plugin system originally supported concurrent multi-language documentation generation, producing both English and Japanese versions of `.workaholic/` content. This approach is too redundant and no longer needed. The simpler model is: Claude Code refers to the repository root CLAUDE.md, which declares the written language, and the language protocol handles the rest. There is no need for duplicated i18n documentation generation, translate skills, or i18n rule files.

This ticket removes all i18n infrastructure: rule files, the translate skill, translation references in agents and skills, the Written Language section from CLAUDE.md, all `_ja.md` duplicate files, and `README_ja.md` index files from `.workaholic/`.

## Key Files

- `CLAUDE.md` - Contains "Written Language" section with `.workaholic/` English/Japanese distinction to remove
- `plugins/trippin/rules/i18n.md` - Written Language Policy rule for trippin plugin to delete
- `plugins/drivin/rules/i18n.md` - Multi-Language Documentation rule for drivin plugin to delete
- `plugins/drivin/rules/workaholic.md` - References i18n skill enforcement on line 19
- `plugins/standards/skills/translate/SKILL.md` - Entire translate skill to delete
- `plugins/standards/skills/analyze-viewpoint/SKILL.md` - References translate skill in frontmatter, has language navigation in output template
- `plugins/standards/skills/analyze-policy/SKILL.md` - References translate skill in frontmatter, has `_ja` naming convention
- `plugins/standards/skills/write-spec/SKILL.md` - References translate skill, describes `_ja.md` translation counterparts, i18n README mirroring section
- `plugins/standards/skills/write-terms/SKILL.md` - i18n mirroring section, translation sync rules
- `plugins/standards/skills/lead-ux/SKILL.md` - Translation goal and documentation policy (representative of all 10 lead skills)
- `plugins/standards/skills/manage-architecture/SKILL.md` - Translation documentation rule
- `plugins/standards/agents/ux-lead.md` - Preloads translate skill (representative of 16 agents that preload it)
- `plugins/standards/agents/model-analyst.md` - "Write Translations" step and translate skill preload
- `plugins/standards/agents/terms-writer.md` - Translation maintenance instructions and translate skill preload
- `plugins/drivin/commands/scan.md` - Phase 5 updates `README_ja.md` files, write-spec skill i18n mirroring

## Related History

The i18n system was built incrementally from the earliest days of the project, starting with multi-language documentation policy, then bilingual `.workaholic/` support, a dedicated translate skill, and eventually enforcement rules across both drivin and trippin plugins. Several later tickets already tried to fix problems caused by this complexity (duplicate Japanese specs, hardcoded translation targets), indicating the system was already proving costly to maintain.

Past tickets that touched similar areas:

- [20260326183945-enforce-written-language-policy-in-trippin.md](.workaholic/tickets/archive/drive-20260326-183949/20260326183945-enforce-written-language-policy-in-trippin.md) - Added i18n rule to trippin plugin and language enforcement to agents (same layer: Config, same files)
- [20260212123836-fix-duplicate-japanese-specs-in-workaholic.md](.workaholic/tickets/archive/drive-20260212-122906/20260212123836-fix-duplicate-japanese-specs-in-workaholic.md) - Fixed language duplication where Japanese-primary projects got redundant `_ja.md` files; demonstrates the maintenance burden of i18n
- [20260204172657-remove-translator-from-story-writer.md](.workaholic/tickets/archive/drive-20260204-160722/20260204172657-remove-translator-from-story-writer.md) - Removed translation responsibility from story-writer; early simplification of i18n
- [20260124112637-add-translate-skill.md](.workaholic/tickets/archive/feat-20260124-105903/20260124112637-add-translate-skill.md) - Original creation of the translate skill being removed
- [20260123234825-multi-language-documentation-policy.md](.workaholic/tickets/archive/feat-20260123-191707/20260123234825-multi-language-documentation-policy.md) - Original multi-language policy that established the i18n approach now being deprecated
- [20260128002918-merge-enforce-i18n-into-translate.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002918-merge-enforce-i18n-into-translate.md) - Consolidated i18n enforcement into the translate skill

## Implementation Steps

1. **Delete i18n rule files**:
   - Delete `plugins/trippin/rules/i18n.md`
   - Delete `plugins/drivin/rules/i18n.md`

2. **Delete the translate skill**:
   - Delete the entire `plugins/standards/skills/translate/` directory

3. **Remove Written Language section from CLAUDE.md**: Remove the "Written Language" section (lines 9-16) that declares the `.workaholic/` English/Japanese distinction. Also remove `rules/i18n` from the trippin Project Structure entry.

4. **Update `plugins/drivin/rules/workaholic.md`**: Remove the i18n enforcement reference on line 19 (`**i18n**: Translation is enforced. See the 'i18n' skill for requirements.`). Also remove `README_ja.md` from the README allowance on line 17.

5. **Remove translate skill from all agent frontmatter** (16 agents):
   - `plugins/standards/agents/ux-lead.md` - remove `- translate` from skills list
   - `plugins/standards/agents/test-lead.md`
   - `plugins/standards/agents/observability-lead.md`
   - `plugins/standards/agents/model-analyst.md`
   - `plugins/standards/agents/security-lead.md`
   - `plugins/standards/agents/infra-lead.md`
   - `plugins/standards/agents/delivery-lead.md`
   - `plugins/standards/agents/recovery-lead.md`
   - `plugins/standards/agents/db-lead.md`
   - `plugins/standards/agents/quality-manager.md`
   - `plugins/standards/agents/quality-lead.md`
   - `plugins/standards/agents/architecture-manager.md`
   - `plugins/standards/agents/project-manager.md`
   - `plugins/standards/agents/a11y-lead.md`
   - `plugins/standards/agents/terms-writer.md`

6. **Update agent instructions that mention translations**:
   - `plugins/standards/agents/model-analyst.md` - Remove step 5 "Write Translations" and update output JSON to remove translation file references
   - `plugins/standards/agents/terms-writer.md` - Remove translation maintenance instructions (steps 5, 6)

7. **Remove translate skill from analysis skill frontmatter and content**:
   - `plugins/standards/skills/analyze-viewpoint/SKILL.md` - Remove `- translate` from skills list, remove language navigation line from output template (line 48)
   - `plugins/standards/skills/analyze-policy/SKILL.md` - Remove `- translate` from skills list, remove language navigation line from output template (line 37), remove `_ja` suffix file naming convention (line 94)

8. **Remove translation references from write-spec and write-terms skills**:
   - `plugins/standards/skills/write-spec/SKILL.md` - Remove `- translate` from skills list (line 6), remove "plus their Japanese translations" from viewpoint files description (line 66), remove `_ja.md` translation file naming (lines 98-100), remove entire "i18n README mirroring" subsection (lines 163-167)
   - `plugins/standards/skills/write-terms/SKILL.md` - Remove "i18n mirroring" subsection (lines 102-107), remove "Keep translations in sync" rule (line 116)

9. **Remove translation goals/rules from all 10 lead skills**: Each lead skill in `plugins/standards/skills/lead-*/SKILL.md` has 3 lines referencing translations:
   - Goal: "Translations are produced only when the user's root CLAUDE.md declares translation requirements."
   - Review responsibility: "Produce translations only when..."
   - Documentation policy: "Write the English spec/policy first, then produce translations per..."
   - Remove all three translation-related lines from each lead skill

10. **Remove translation rule from manage-architecture skill**:
    - `plugins/standards/skills/manage-architecture/SKILL.md` - Remove translation documentation rule (line 81)

11. **Update the /scan command** (`plugins/drivin/commands/scan.md`):
    - Phase 5: Remove `README_ja.md` update instructions (lines 86-87 reference updating `README_ja.md`)

12. **Delete all `_ja.md` files from `.workaholic/`** (43 files across specs, terms, guides, policies, stories, and root):
    - All files matching `.workaholic/**/*_ja.md`

13. **Update `.workaholic/` README files**: Remove language navigation badges/links from README.md files that link to README_ja.md (in specs/, terms/, guides/, policies/, stories/, and root)

## Considerations

- The a11y lead skill has additional i18n-specific content in its role description: it mentions analyzing "internationalization support, language coverage, translation workflows." This needs to be rewritten to focus purely on accessibility, since i18n analysis is no longer a concern of this plugin (`plugins/standards/skills/lead-a11y/SKILL.md` lines 3, 11, 24, 55)
- The trippin agents (planner.md, architect.md, constructor.md) had language enforcement rules added in ticket 20260326. Those rules mention English-only output with a `.workaholic/` exception for Japanese. The i18n rules themselves should be removed, but the "write in English" instruction may still be valuable as a general agent behavior guide, distinct from i18n infrastructure. Consider whether to keep a simplified "output language: English" line or remove entirely (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`)
- The trippin trip-protocol skill has a "Written Language Policy" section added in ticket 20260326. This section should be simplified or removed since the i18n framework it references no longer exists (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- Deleting 43 `_ja.md` files is a large operation. The `git add` for this commit should be done carefully -- `git add -u .workaholic/` after deletion captures all removals, or `git rm` each file explicitly (`plugins/standards/skills/validate-writer-output/sh/validate.sh` is not affected since it only checks English filenames)
- The `plugins/drivin/rules/workaholic.md` also mentions `README_ja.md` in the allowed root-level files line. This should be simplified to just `README.md` (`plugins/drivin/rules/workaholic.md` line 17)
- Existing `.workaholic/` README.md files likely contain language navigation links like `[English](README.md) | [Japanese](README_ja.md)` that need to be removed from the top of each file (`.workaholic/README.md`, `.workaholic/specs/README.md`, `.workaholic/terms/README.md`, `.workaholic/guides/README.md`, `.workaholic/policies/README.md`, `.workaholic/stories/README.md`)
