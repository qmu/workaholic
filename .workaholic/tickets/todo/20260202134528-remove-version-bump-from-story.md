---
created_at: 2026-02-02T13:45:11+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Remove version bump from /story command

## Overview

The `/story` command currently includes a version bump step (step 5) that conflicts with the `/release` command's version bumping. This causes double increments when the workflow is: `/story` (bumps version) -> PR merge -> `/release` (bumps version again). For example, v1.0.26 became v1.0.28 instead of v1.0.27 due to this issue.

The solution is to remove the version bump step from `/story` and make `/release` the single source of truth for version management.

## Key Files

- `plugins/core/commands/story.md` - Contains the version bump step at line 62 that needs removal
- `.claude/commands/release.md` - The release command that should be the only place bumping versions
- `CLAUDE.md` - Documents version management policy (referenced by story.md step 5)

## Related History

Past tickets reveal the version bump was intentionally added to `/story` to include version changes in PR diff, but this conflicts with the automated release workflow.

- [20260201112308-fix-release-default-to-patch.md](.workaholic/tickets/archive/drive-20260201-112920/20260201112308-fix-release-default-to-patch.md) - Added version bump to /story command (source of current issue)
- [20260129123400-auto-release-on-merge.md](.workaholic/tickets/archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md) - Added auto-release on merge (conflicts with /story version bump)

## Implementation Steps

1. **Remove step 5 from story.md**: Delete the "Bump version" step (line 62) and any related instructions that reference version bumping
2. **Renumber subsequent steps**: After removal, renumber step 6 (Push branch) to step 5, and step 7 (Create/update PR) to step 6
3. **Verify CLAUDE.md**: Ensure version management section still correctly documents that `/release` is the command responsible for version bumping

## Considerations

- The GitHub Actions workflow `.github/workflows/release.yml` auto-detects version type based on branch prefix (feat -> minor, fix/refact/drive -> patch)
- After this change, version bumps will only appear after PR merge, not in the PR diff itself
- This is acceptable because the version is determined by the release workflow, not by developers
