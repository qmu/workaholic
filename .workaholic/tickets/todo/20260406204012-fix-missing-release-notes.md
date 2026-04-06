---
created_at: 2026-04-06T20:40:12+09:00
author: a@qmu.jp
type: bugfix
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
---

# Fix Missing Release Notes from Recent Releases

## Overview

The `.workaholic/release-notes/` directory contains release notes for only 13 of 32 branch stories, and the GitHub Actions release workflow (`release.yml`) has been publishing the same stale release note (from drive-20260204-160722) for every release since at least v1.0.30. This ticket covers three areas: (1) diagnose and fix the root cause in `release.yml`, (2) backfill missing release notes for branches that have stories, and (3) ensure the trip mode of `/report` also generates release notes going forward.

## Key Files

- `.github/workflows/release.yml` - Release workflow; line 67 uses `ls -t` to select release note file, which is non-deterministic in CI where `actions/checkout` sets all timestamps to checkout time
- `plugins/work/agents/story-writer.md` - Drive mode story writer; Phase 4-5 correctly generates and commits release notes
- `plugins/core/commands/report.md` - Report command; trip mode (lines 51-69) skips release note generation entirely
- `plugins/standards/agents/release-note-writer.md` - Release note writer agent; needs to be invoked from trip mode as well
- `plugins/standards/skills/write-release-note/SKILL.md` - Release note content structure and guidelines
- `.workaholic/release-notes/README.md` - Index file; only lists 4 of 13 existing release note files
- `.workaholic/stories/` - Contains 32 story files; 18 have no corresponding release note

## Related History

The release-note-writer was introduced in drive-20260204-160722 and has been patched twice for metric and formatting issues. The `release.yml` file-selection bug was noted as a consideration in ticket 20260212182713 but was never addressed because it was out of scope for that fix.

Past tickets that touched similar areas:

- [20260204201108-add-release-note-writer-to-report.md](.workaholic/tickets/archive/drive-20260204-160722/20260204201108-add-release-note-writer-to-report.md) - Created release-note-writer and write-release-note skill; noted the `ls -t` concern in considerations
- [20260210125506-fix-release-note-hardcoded-metrics.md](.workaholic/tickets/archive/drive-20260210-121635/20260210125506-fix-release-note-hardcoded-metrics.md) - Fixed hardcoded metric placeholders in write-release-note skill
- [20260212182713-fix-release-note-generation.md](.workaholic/tickets/archive/drive-20260212-122906/20260212182713-fix-release-note-generation.md) - Fixed H1 heading, Changes section, Velocity metric, and PR URL ordering; explicitly noted `ls -t` bug as a separate issue
- [20260129140000-add-release-github-action.md](.workaholic/tickets/archive/feat-20260129-023941/20260129140000-add-release-github-action.md) - Created the GitHub Actions release workflow
- [20260202204111-fix-release-action-trigger-on-merge.md](.workaholic/tickets/archive/drive-20260202-203938/20260202204111-fix-release-action-trigger-on-merge.md) - Fixed release action trigger condition

## Implementation Steps

1. **Fix release.yml file selection** (`.github/workflows/release.yml`): Replace the `ls -t` approach on line 67 with a deterministic method. The release note file should be identified by correlating the merge commit with the branch name, then looking up `.workaholic/release-notes/<branch-name>.md`. Use `git log --merges -1 --format=%s` to extract the branch name from the most recent merge commit message (format: "Merge pull request #N from owner/branch-name"), then check if the corresponding release note file exists.

2. **Backfill missing release notes**: For each story in `.workaholic/stories/` that lacks a corresponding file in `.workaholic/release-notes/`, generate the release note by invoking the release-note-writer agent or manually extracting content from the story. The branches missing release notes are:
   - 11 `feat-*` branches (predate the release-note-writer feature)
   - 5 `drive-*` branches (drive-20260131 through drive-20260203)
   - `trip-trip-20260319-squashed`
   - `work-20260404-101424-fix-trip-report-dir-path`

3. **Update release-notes README.md**: Regenerate the index to include all release note files, not just the 4 currently listed.

4. **Add release note generation to trip mode** (`plugins/core/commands/report.md`): After the trip mode creates the story and PR (step 5), invoke the release-note-writer agent to generate a release note, then commit and push it. This mirrors what story-writer does in Phase 4-5 for drive mode.

## Patches

### `.github/workflows/release.yml`

```diff
--- a/.github/workflows/release.yml
+++ b/.github/workflows/release.yml
@@ -62,8 +62,17 @@
       - name: Extract release notes
         id: notes
         if: steps.check.outputs.needed == 'true'
         run: |
-          # Check for generated release notes file (most recent by modification time)
-          release_note=$(ls -t .workaholic/release-notes/*.md 2>/dev/null | grep -v README.md | head -1)
+          # Determine the branch name from the most recent merge commit
+          merge_msg=$(git log --merges -1 --format=%s)
+          branch_name=$(echo "$merge_msg" | sed -n 's|.*from [^/]*/\(.*\)|\1|p')
+
+          release_note=""
+          if [ -n "$branch_name" ]; then
+            candidate=".workaholic/release-notes/${branch_name}.md"
+            if [ -f "$candidate" ]; then
+              release_note="$candidate"
+            fi
+          fi
 
           if [ -n "$release_note" ] && [ -f "$release_note" ]; then
             echo "Using generated release notes from: $release_note"
```

> **Note**: This patch is speculative - the merge commit message format depends on GitHub's merge strategy. Verify the actual format used by `gh pr merge` before applying.

## Considerations

- The merge commit message format varies depending on merge strategy. GitHub's default squash-merge uses "Title (#N)" while merge-commit uses "Merge pull request #N from owner/branch". The `release.yml` fix must handle the strategy actually configured for this repository. (`.github/workflows/release.yml` lines 62-67)
- Backfilling 18 release notes is a bulk operation. For `feat-*` stories that predate the release-note-writer, the story format may differ from current conventions (missing frontmatter fields like `velocity`, `duration_days`). The release-note-writer should handle missing fields gracefully. (`.workaholic/stories/feat-*.md`)
- The trip mode release note generation should reuse the existing release-note-writer agent rather than duplicating logic. The PR URL must be available before invoking the writer, so the invocation must happen after PR creation. (`plugins/core/commands/report.md` lines 51-69)
- The `release-notes/README.md` index is currently maintained manually by the release-note-writer agent (Step 4 in `plugins/standards/agents/release-note-writer.md`). The backfill step should update it comprehensively rather than appending 18 individual entries.
- After fixing `release.yml`, consider re-publishing the most recent GitHub Release (v1.0.44) with the correct release notes so the public-facing release page is accurate.
