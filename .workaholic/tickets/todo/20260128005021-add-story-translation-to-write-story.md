---
created_at: 2026-01-28T00:50:21+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add story translation requirement to write-story skill

## Overview

Per CLAUDE.md's Written Language section, files in `.workaholic/` directory should have English and Japanese versions (i18n). Stories in `.workaholic/stories/` are covered by this policy, but the `write-story` skill and `story-writer` agent don't currently instruct to create Japanese translations.

Add instructions to:
1. Create `<branch-name>_ja.md` alongside the English story
2. Update both `README.md` and `README_ja.md` in the stories index
3. Reference the `translate` skill for translation policies

## Key Files

- `plugins/core/skills/write-story/SKILL.md` - Add translation requirement
- `plugins/core/agents/story-writer.md` - Add translate skill to preload, add translation step

## Related History

The bilingual documentation policy was established early and applies to all `.workaholic/` content.

Past tickets that touched similar areas:

- `20260128002918-merge-enforce-i18n-into-translate.md` - Merging enforce-i18n into translate (same concern)
- `20260127103935-convert-i18n-rule-to-skill.md` - Created enforce-i18n skill for documentation agents (same pattern)
- `20260124003751-bilingual-work-documentation.md` - Established story translation requirement (same files)

## Implementation Steps

1. **Update story-writer agent** (`plugins/core/agents/story-writer.md`):
   - Add `translate` to skills list in frontmatter
   - Add step 8: "Translate Story: Create `<branch-name>_ja.md` following the preloaded translate skill"
   - Update step 7 (Update Index): "Update both `.workaholic/stories/README.md` and `README_ja.md`"

2. **Update write-story skill** (`plugins/core/skills/write-story/SKILL.md`):
   - Add "## Translation" section after "Updating Stories Index"
   - Document: create `<branch-name>_ja.md` with Japanese translation
   - Reference translate skill for policies
   - Update "Updating Stories Index" to mention both README files

## Considerations

- The `translate` skill (after merging with enforce-i18n) will contain all translation policies
- Story content is prose-heavy, so translation will add significant work
- The README_ja.md index also needs the new story entry
- Story frontmatter stays in English (only content is translated)
