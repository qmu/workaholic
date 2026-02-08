---
created_at: 2026-02-08T13:30:08+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
---

# Add Automatic Version Bump to /story Command

## Overview

Neither `/story` nor `/report` currently includes a version bump step, so when PRs are merged to main the GitHub Actions release workflow sees no version change and no release is created. The `/release` command exists as a separate manual step but developers forget to run it. Adding an automatic patch-increment version bump to the `/story` command (before story-writer invocation) ensures every PR merge triggers a new release via the existing GitHub Actions workflow. The `/report` command inherits this behavior because it delegates to story-writer.

## Key Files

- `plugins/core/commands/story.md` - Story command where the version bump step will be added (between documentation commit and story-writer invocation)
- `plugins/core/agents/story-writer.md` - Story-writer subagent that handles story generation, commit, push, and PR creation (version bump must happen before this)
- `.claude-plugin/marketplace.json` - Root marketplace version file (version field at line 3 and plugins array at line 13)
- `plugins/core/.claude-plugin/plugin.json` - Core plugin version file (version field at line 4)
- `.github/workflows/release.yml` - Release workflow that compares marketplace.json version against latest release tag (no changes needed)
- `.claude/commands/release.md` - Standalone release command that currently handles version bumping (will remain for manual major/minor bumps)

## Related History

The version bumping strategy has oscillated between /story command and GitHub Actions, with the bump being added and then removed from both locations across several iterations, leaving a gap where no automatic bumping occurs.

Past tickets that touched similar areas:

- [20260201112308-fix-release-default-to-patch.md](.workaholic/tickets/archive/drive-20260201-112920/20260201112308-fix-release-default-to-patch.md) - Added version bump step to /story command and fixed patch default (same command: story.md)
- [20260202134528-remove-version-bump-from-story.md](.workaholic/tickets/archive/drive-20260202-134332/20260202134528-remove-version-bump-from-story.md) - Removed version bumping from GitHub Action to avoid double increments (same layer: Config/Infrastructure)
- [20260202204111-fix-release-action-trigger-on-merge.md](.workaholic/tickets/archive/drive-20260202-203938/20260202204111-fix-release-action-trigger-on-merge.md) - Changed release action to version-comparison approach (same file: release.yml)
- [20260129123400-auto-release-on-merge.md](.workaholic/tickets/archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md) - Added automatic release trigger on PR merge (same workflow: release.yml)
- [20260129140000-add-release-github-action.md](.workaholic/tickets/archive/feat-20260129-023941/20260129140000-add-release-github-action.md) - Created the original GitHub Actions release workflow (same file: release.yml)

## Implementation Steps

1. **Add version bump step to `plugins/core/commands/story.md`** between the documentation commit step and the story-writer invocation step:
   - Read `.claude-plugin/marketplace.json` and parse the current `version` field
   - Increment PATCH by 1 (e.g., 1.0.33 -> 1.0.34)
   - Update version in both files per CLAUDE.md Version Management section:
     - `.claude-plugin/marketplace.json` root `version` field
     - `.claude-plugin/marketplace.json` plugins array `core` entry version
     - `plugins/core/.claude-plugin/plugin.json` version field
   - Stage and commit: `"Bump version to v{new_version}"`

2. **Renumber subsequent steps in `plugins/core/commands/story.md`**: The story-writer invocation and PR URL display steps shift to accommodate the new version bump step.

3. **Verify `/report` inherits the behavior**: The `/report` command invokes story-writer directly (not via `/story`), so `/report` does NOT automatically get the version bump. To handle this, add the same version bump step to `plugins/core/commands/report.md` before the story-writer invocation.

4. **Verify no changes needed to release.yml**: The existing GitHub Actions workflow already compares `marketplace.json` version against the latest release tag and creates a release only when they differ. With the version bump happening in the PR branch, the merged version will differ from the latest release, triggering automatic release creation.

## Patches

### `plugins/core/commands/story.md`

```diff
--- a/plugins/core/commands/story.md
+++ b/plugins/core/commands/story.md
@@ -12,5 +12,6 @@ Run a partial documentation scan (only agents relevant to branch changes), then

 1. **Invoke scanner** (`subagent_type: "core:scanner"`, `model: "opus"`) with prompt: `"Scan documentation. mode: partial"`
 2. **Stage and commit**: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"`
-3. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
-4. **Display PR URL** from story-writer result (mandatory)
+3. **Bump version** following CLAUDE.md Version Management section (patch increment)
+4. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
+5. **Display PR URL** from story-writer result (mandatory)
```

### `plugins/core/commands/report.md`

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -12,5 +12,6 @@ Generate story and create or update a pull request for the current branch.

 ## Instructions

-1. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
-2. **Display PR URL** from story-writer result (mandatory)
+1. **Bump version** following CLAUDE.md Version Management section (patch increment)
+2. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
+3. **Display PR URL** from story-writer result (mandatory)
```

## Considerations

- The version bump was previously in the old `/story` command (commit `74e865f`) but was lost during the rename cycle when `/story` became `/report` and then a new `/story` was created without the bump step (`plugins/core/commands/story.md`)
- The `/release` command should remain available for manual major/minor bumps, but developers should not need to run it for routine patch releases (`plugins/core/commands/release.md` via `.claude/commands/release.md`)
- The GitHub Actions release workflow already handles duplicate protection: if the version matches the latest release, it skips creation (`.github/workflows/release.yml` lines 46-60)
- The pending ticket `20260208131751-migrate-scanner-into-scan-command.md` proposes restructuring the `/story` command to inline scanner logic. The version bump step should be added regardless and preserved during that migration (`.workaholic/tickets/todo/20260208131751-migrate-scanner-into-scan-command.md`)
- Both `/story` and `/report` need the version bump step independently because `/report` invokes story-writer directly without going through `/story` (`plugins/core/commands/report.md`)
- The version bump commit message format `"Bump version to v{new_version}"` should remain consistent with the convention used by the existing `/release` command (`CLAUDE.md` Version Management section)
