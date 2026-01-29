---
created_at: 2026-01-29T10:14:47+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Fix archive-ticket Script Path Reference

## Overview

The `drive-workflow` skill references a non-existent path `.claude/skills/archive-ticket/sh/archive.sh`. The actual path is `plugins/core/skills/archive-ticket/sh/archive.sh`. When Claude can't find the script, it falls back to manual `mv` + `git commit --amend` operations, violating the "archive script is the ONLY way to archive tickets" rule. This is the same class of bug as the create-branch path issue.

## Key Files

- `plugins/core/skills/drive-workflow/SKILL.md` - Line 112 references broken path
- `plugins/core/skills/archive-ticket/sh/archive.sh` - The actual script that handles archiving

## Related History

Same root cause as the create-branch path bug discovered earlier in this session.

Past tickets that touched similar areas:

- [20260129094618-fix-create-branch-path-reference.md](.workaholic/tickets/todo/20260129094618-fix-create-branch-path-reference.md) - Same class of path reference bug (same layer: Config)

## Implementation Steps

1. Update `plugins/core/skills/drive-workflow/SKILL.md` line 112-118:

   Replace the bash code block with inline instructions that don't depend on file path:

   ```markdown
   After writing the final report, invoke the preloaded **archive-ticket** skill to commit and archive:

   The skill's archive script handles:
   - Moving ticket to `.workaholic/tickets/archive/<branch>/`
   - Staging all changes with `git add -A`
   - Committing with proper message format
   - Updating ticket frontmatter (`commit_hash`, `category`)
   - Amending commit to include updated ticket

   Required arguments:
   - `<ticket-path>` - Path to the ticket being archived
   - `<commit-message>` - Present-tense verb commit message
   - `<repo-url>` - GitHub repository URL
   - `<description>` - 1-2 sentence motivation
   ```

2. Ensure the `drive.md` command preloads `archive-ticket` skill in its frontmatter:

   ```yaml
   skills:
     - drive-workflow
     - archive-ticket
   ```

3. Consider inlining the archive script logic into the skill (it's ~60 lines of shell) to avoid path dependency entirely.

## Considerations

- The drive-workflow skill is preloaded by the drive command, so it has access to other preloaded skills
- Inlining the script content via `@` import or as a code block would make it portable
- The skill explicitly says "CRITICAL: The archive script is the ONLY way to archive tickets" - ironic given the broken path
- Need to verify `archive-ticket` is preloaded by drive command for skill access

## Failure Analysis

### What Was Attempted

- Embedded the archive.sh script content directly into the archive-ticket SKILL.md file
- Updated drive-workflow to reference the preloaded skill instead of hardcoded path
- Removed the standalone sh/archive.sh file

### Why It Failed

Implementation was abandoned by user - likely the approach of embedding a 100-line shell script inline in markdown was too verbose or not the preferred solution.

### Insights for Future Attempts

- Consider using `${CLAUDE_PLUGIN_ROOT}` environment variable approach instead, which works for hooks
- Alternatively, the path issue may only affect development and work correctly when plugin is installed
- May need a different mechanism for portable script references in skills
