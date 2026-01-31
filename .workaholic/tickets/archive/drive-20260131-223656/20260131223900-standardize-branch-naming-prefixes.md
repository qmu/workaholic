---
created_at: 2026-01-31T22:39:00+09:00
author: noreply@anthropic.com
type: housekeeping
layer: Config
effort: 0.5h
commit_hash: a69b473---
category: Changed
# Standardize Branch Naming to drive-/trip- Prefixes Only

## Overview

Ensure all branch naming documentation and examples use only `drive-` or `trip-` prefixes. Remove references to legacy prefixes (`feat-`, `fix-`, `refact-`) from instructions and examples, while preserving historical context in archived tickets and stories.

## Motivation

The `create-branch` skill defines valid prefixes as `drive` and `trip`, but several files still reference the old `feat-*`, `fix-*`, `refact-*` prefixes in examples and instructions. This inconsistency confuses users about which prefixes to use. The GitHub Actions workflow uses the old prefixes for version detection on merge, which needs to be updated to recognize the new naming convention.

## Key Files

| Path | Change Type |
|------|-------------|
| `plugins/core/commands/ticket.md` | Update topic branch pattern |
| `plugins/core/skills/create-branch/SKILL.md` | Fix example output |
| `.workaholic/guides/workflow.md` | Update example branch names |
| `.workaholic/guides/workflow_ja.md` | Update example branch names |
| `.github/workflows/release.yml` | Update branch prefix detection |

## Related History

- [Extract create-branch skill](../archive/feat-20260128-001720/20260128002536-extract-create-branch-skill.md): Defined `drive`/`trip` as valid prefixes
- [Auto-create Branch on /ticket](../archive/feat-20260128-220712/20260129012614-auto-branch-on-ticket.md): Integrated branch creation into `/ticket`, originally used `feat-*` pattern
- [Auto Release on Merge](../archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md): Added version detection from branch prefixes (`feat-*` → minor, `fix-*`/`refact-*` → patch)

## Implementation

### 1. Update ticket.md Topic Branch Pattern

Change line 24:
```diff
-   Topic branch pattern: `drive-*`, `feat-*`, `fix-*`, `refact-*`
+   Topic branch pattern: `drive-*`, `trip-*`
```

### 2. Fix create-branch Skill Example Output

Line 30 shows `feat-20260120-205418` but should match the valid prefixes:
```diff
-feat-20260120-205418
+drive-20260120-205418
```

### 3. Update workflow.md Example Branch Names

Lines 25, 47 reference `/branch` command and `feat-20260123-143022`:
- Change Step 1 example output from `feat-20260123-143022` to `drive-20260123-143022`
- Update the diagram if it references specific branch naming

### 4. Update workflow_ja.md Example Branch Names

Same changes as workflow.md:
- Line 47: Change `feat-20260123-143022` to `drive-20260123-143022`

### 5. Update release.yml Branch Detection

Update the grep patterns to recognize `drive-` and `trip-` branches for version bumping:
```diff
-if echo "$commit_msg" | grep -qE "Merge pull request.*from.*/feat-"; then
+if echo "$commit_msg" | grep -qE "Merge pull request.*from.*/(drive|trip)-"; then
  echo "Detected feature branch merge -> minor bump"
-elif echo "$commit_msg" | grep -qE "Merge pull request.*from.*/(fix|refact)-"; then
-  echo "Detected fix/refactor branch merge -> patch bump"
```

Note: With `drive-`/`trip-` being the only prefixes, we need to decide version bump strategy:
- Option A: All branches get minor bumps (simplest)
- Option B: Use commit message content or other signals for version type
- Option C: Keep `trip-` as minor, add `hotfix-` prefix for patches

Recommend Option A for simplicity: all `drive-` and `trip-` branches trigger minor bumps.

## What NOT to Change

- **Archived tickets/stories**: Keep historical branch names as-is (e.g., `feat-20260128-001720/`) - these document actual history
- **CHANGELOG.md**: Keep historical entries referencing old prefixes
- **Directory names in archive/**: These are actual branch names used historically
