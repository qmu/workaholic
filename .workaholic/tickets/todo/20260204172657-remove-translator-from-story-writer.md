---
created_at: 2026-02-04T17:26:57+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Remove translator from story-writer subagent

## Overview

Remove translation logic from the story-writer subagent. Currently, story-writer creates both the English story file and its Japanese translation (`<branch-name>_ja.md`). This responsibility should be removed - story-writer should only generate the English story file. Translation to other languages should happen during the `/scan` command workflow, centralizing all i18n work in the scanner.

This change simplifies the story-writer's single responsibility and makes translation timing consistent with other documentation (specs, terms, changelog).

## Key Files

- `plugins/core/agents/story-writer.md` - Remove translate skill from preload, remove translation step
- `plugins/core/skills/write-story/SKILL.md` - Remove Translation section and translate skill preload
- `plugins/core/agents/scanner.md` - Consider adding story translation responsibility
- `plugins/core/commands/scan.md` - May need to add stories directory to documentation update scope

## Related History

Translation was added to story-writer as part of the bilingual documentation policy. The original implementation placed translation responsibility within the story generation workflow.

Past tickets that touched similar areas:

- [20260128005021-add-story-translation-to-write-story.md](.workaholic/tickets/archive/feat-20260128-001720/20260128005021-add-story-translation-to-write-story.md) - Added translation to write-story (reversing this change)
- [20260127004417-story-writer-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127004417-story-writer-subagent.md) - Original story-writer extraction (same file)
- [20260203182617-extract-scan-command.md](.workaholic/tickets/archive/drive-20260203-122444/20260203182617-extract-scan-command.md) - Created scan command for documentation updates (related workflow)

## Implementation Steps

1. **Update story-writer agent** (`plugins/core/agents/story-writer.md`):
   - Remove `translate` from skills list in frontmatter (keep gather-git-context, write-story)
   - Remove step "Translate Story: Create `<branch-name>_ja.md`"
   - Update output JSON schema to remove `story_file_ja` field
   - Simplify step for updating index - only update `README.md`, not `README_ja.md`

2. **Update write-story skill** (`plugins/core/skills/write-story/SKILL.md`):
   - Remove `translate` from skills list in frontmatter
   - Remove entire "## Translation" section at the end
   - Update "## Updating Stories Index" section to only mention README.md

3. **Update scanner or scan command** (if needed):
   - Evaluate whether stories should be translated during `/scan`
   - If yes, add story translation to scanner workflow
   - Update README_ja.md index during scan instead of during story creation

## Patches

### `plugins/core/agents/story-writer.md`

```diff
--- a/plugins/core/agents/story-writer.md
+++ b/plugins/core/agents/story-writer.md
@@ -33,9 +33,7 @@ Wait for all 4 agents to complete. Track which succeeded and which failed.

 2. **Write Story**: Follow the preloaded write-story skill for content structure, agent output mapping, templates, and guidelines.

-3. **Translate Story**: Create `<branch-name>_ja.md` with Japanese translation.
-
-4. **Update Index**: Add entry to both `.workaholic/stories/README.md` and `README_ja.md`.
+3. **Update Index**: Add entry to `.workaholic/stories/README.md`.

 ### Phase 3: Create Pull Request
```

```diff
--- a/plugins/core/agents/story-writer.md
+++ b/plugins/core/agents/story-writer.md
@@ -50,7 +50,6 @@ Return JSON with story and PR status:

 ```json
 {
   "story_file": ".workaholic/stories/<branch-name>.md",
-  "story_file_ja": ".workaholic/stories/<branch-name>_ja.md",
   "pr_url": "<PR-URL>",
   "agents": {
```

### `plugins/core/skills/write-story/SKILL.md`

```diff
--- a/plugins/core/skills/write-story/SKILL.md
+++ b/plugins/core/skills/write-story/SKILL.md
@@ -1,8 +1,7 @@
 ---
 name: write-story
 description: Story content structure, templates, and writing guidelines for branch narratives.
-skills:
-  - translate
 user-invocable: false
 ---
```

```diff
--- a/plugins/core/skills/write-story/SKILL.md
+++ b/plugins/core/skills/write-story/SKILL.md
@@ -219,19 +218,8 @@ duration_days: <from performance-analyst metrics if velocity_unit is "day">

 ## Updating Stories Index

-Update both `.workaholic/stories/README.md` and `README_ja.md` to include the new story:
+Update `.workaholic/stories/README.md` to include the new story:

 **README.md**:
 - Add entry: `- [<branch-name>.md](<branch-name>.md) - Brief description of the branch work`
-
-**README_ja.md**:
-- Add entry: `- [<branch-name>_ja.md](<branch-name>_ja.md) - ブランチの作業内容の簡潔な説明`
-
-## Translation
-
-Per `.workaholic/` i18n requirements, create a Japanese translation alongside the English story:
-
-1. Create `<branch-name>_ja.md` with translated content
-2. Keep frontmatter in English (only translate prose content)
-3. Follow the preloaded `translate` skill for translation policies
-4. Technical terms (commit, branch, plugin, etc.) should remain in English
```

> **Note**: These patches are speculative - verify exact line numbers and whitespace before applying.

## Considerations

- **i18n policy compliance**: The `.workaholic/` directory requires bilingual documentation. This change shifts responsibility but should not eliminate translation entirely. Ensure scan command handles story translation.
- **Existing translations**: Existing `*_ja.md` story files will remain unchanged. Only new stories will follow the new workflow.
- **README_ja.md maintenance**: The Japanese story index will need updating during scan, not during story creation. Consider whether scanner should also update this index when translating stories.
- **Single responsibility**: story-writer focuses solely on English story generation; translation becomes a separate concern handled by scan workflow.

## Final Report

Development completed as planned. Removed translation responsibility from story-writer:
- Removed "Translate Story" step and `story_file_ja` output field from agent
- Removed `translate` skill preload and Translation section from write-story skill
- Simplified index updates to only modify README.md (not README_ja.md)

Story translation is now out of scope for story-writer, following single-responsibility principle.
