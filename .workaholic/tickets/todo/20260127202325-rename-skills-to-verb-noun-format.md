---
created_at: 2026-01-27T20:23:25+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Rename Skills to Verb-Noun Format

## Overview

Standardize skill directory names to use consistent "verb-noun" format for better intuitiveness. Currently, skill names are inconsistent - some use verb-noun (`archive-ticket`), some use noun-noun (`spec-context`), and some use just nouns (`changelog`, `translate`). A consistent naming convention improves discoverability and communicates what each skill does.

## Key Files

- `plugins/core/skills/` - All skill directories to be renamed
- `plugins/core/agents/*.md` - Update skill references in frontmatter
- `plugins/core/commands/*.md` - Update skill references in frontmatter
- Skill internal files that reference `.claude/skills/<name>/` paths

## Related History

Past tickets that touched similar areas:

- `20260127102007-rename-scripts-to-sh.md` - Renamed scripts directories (same layer: Config)
- `20260127010716-rename-terminology-to-terms.md` - Renamed terminology directory (same layer: Config)

## Implementation Steps

1. **Analyze current names and propose new names**

   Current → Proposed:
   | Current | Pattern | Proposed | Rationale |
   |---------|---------|----------|-----------|
   | `archive-ticket` | verb-noun ✓ | (keep) | Already correct |
   | `changelog` | noun | `generate-changelog` | Action: generates changelog entries |
   | `command-prohibition` | noun-noun | `block-commands` | Action: blocks dangerous commands |
   | `drive-workflow` | noun-noun | (keep or `define-workflow`) | Borderline acceptable |
   | `i18n` | abbreviation | `enforce-i18n` | Action: enforces i18n requirements |
   | `pr-ops` | noun-noun | `manage-pr` | Action: creates/updates PRs |
   | `spec-context` | noun-noun | `gather-spec-context` | Action: gathers context |
   | `story-metrics` | noun-noun | `calculate-story-metrics` | Action: calculates metrics |
   | `terms-context` | noun-noun | `gather-terms-context` | Action: gathers context |
   | `ticket-format` | noun-noun | `define-ticket-format` | Action: defines format conventions |
   | `translate` | verb ✓ | (keep) | Already a verb (implicit noun: docs) |

2. **Rename skill directories**

   For each skill being renamed:
   ```bash
   git mv plugins/core/skills/<old> plugins/core/skills/<new>
   ```

3. **Update SKILL.md frontmatter**

   In each renamed skill's SKILL.md, update the `name:` field to match directory.

4. **Update skill references in agents/commands**

   Update `skills:` frontmatter arrays in:
   - `plugins/core/agents/changelog-writer.md` - changelog → generate-changelog
   - `plugins/core/agents/pr-creator.md` - pr-ops → manage-pr
   - `plugins/core/agents/spec-writer.md` - spec-context → gather-spec-context
   - `plugins/core/agents/story-writer.md` - story-metrics → calculate-story-metrics
   - `plugins/core/agents/terms-writer.md` - terms-context → gather-terms-context
   - `plugins/core/commands/ticket.md` - ticket-format → define-ticket-format

5. **Update internal script paths**

   Update `.claude/skills/<name>/` paths in SKILL.md documentation where skills reference their own bundled scripts.

6. **Update any cross-references**

   Search for skill name references in rules, other skills, or documentation.

## Considerations

- Some names like `drive-workflow` and `translate` are borderline - could keep them as-is
- The `i18n` abbreviation is widely understood but `enforce-i18n` is more descriptive
- Consider whether `command-prohibition` → `block-commands` loses nuance (it's documentation, not active blocking)
- All internal `.claude/skills/<path>` references must be updated for bundled scripts
