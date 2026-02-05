---
created_at: 2026-02-04T21:43:11+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Domain]
effort:
commit_hash: 628b826
category: Changed
---

# Extract GitHub URL Transformation into gather-git-context Skill

## Overview

The `gather-git-context` skill currently outputs the raw `repo_url` from `git remote get-url origin`, which may be in SSH format (`git@github.com:owner/repo.git`). Consumers like write-changelog and write-story expect an HTTPS URL for GitHub links. The URL transformation should be handled within the gather-git-context shell script, not inline in subagents. Additionally, add a principle to CLAUDE.md prohibiting complex inline shell commands in subagents.

## Key Files

- `plugins/core/skills/gather-git-context/sh/gather.sh` - Add SSH-to-HTTPS transformation
- `plugins/core/skills/gather-git-context/SKILL.md` - Update documentation to show HTTPS output
- `CLAUDE.md` - Add principle about shell scripts in skills

## Related History

Historical tickets show the pattern of extracting inline bash commands into bundled shell scripts within skills. The gather-git-context skill was created to consolidate git context gathering, and other skills follow the same bundled script pattern.

Past tickets that touched similar areas:

- [20260202204753-add-shellscript-to-create-branch-skill.md](.workaholic/tickets/archive/drive-20260202-203938/20260202204753-add-shellscript-to-create-branch-skill.md) - Added shell script to create-branch skill (same pattern)
- [20260127193706-bundle-shell-scripts-for-permission-free-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127193706-bundle-shell-scripts-for-permission-free-skills.md) - Established bundled script pattern for skills
- [20260202182054-gather-ticket-metadata-skill.md](.workaholic/tickets/archive/drive-20260202-134332/20260202182054-gather-ticket-metadata-skill.md) - Created gather-ticket-metadata skill with shell script (same pattern)

## Implementation Steps

1. **Update gather-git-context shell script** (`plugins/core/skills/gather-git-context/sh/gather.sh`):
   - After getting `REPO_URL`, transform SSH URL to HTTPS format
   - Handle both SSH (`git@github.com:owner/repo.git`) and HTTPS URLs
   - Remove `.git` suffix if present

2. **Update gather-git-context SKILL.md** documentation:
   - Change example output from `"repo_url": "git@github.com:owner/repo.git"` to `"repo_url": "https://github.com/owner/repo"`
   - Update field description to clarify it outputs HTTPS format

3. **Add principle to CLAUDE.md** under "Common Operations" section:
   - Add note: "Never use complex inline shell commands (pipes, sed, awk) in subagent markdown files. Extract to shell scripts in skills instead."

## Patches

### `plugins/core/skills/gather-git-context/sh/gather.sh`

```diff
--- a/plugins/core/skills/gather-git-context/sh/gather.sh
+++ b/plugins/core/skills/gather-git-context/sh/gather.sh
@@ -7,7 +7,13 @@ set -eu

 BRANCH=$(git branch --show-current)
 BASE_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | sed 's/.*: //')
-REPO_URL=$(git remote get-url origin)
+REPO_URL_RAW=$(git remote get-url origin)
+
+# Transform SSH URL to HTTPS format
+# git@github.com:owner/repo.git -> https://github.com/owner/repo
+REPO_URL=$(echo "$REPO_URL_RAW" | \
+  sed 's|^git@github\.com:|https://github.com/|' | \
+  sed 's|\.git$||')

 # List archived tickets for the branch (empty array if none)
 ARCHIVE_DIR=".workaholic/tickets/archive/${BRANCH}"
```

### `plugins/core/skills/gather-git-context/SKILL.md`

```diff
--- a/plugins/core/skills/gather-git-context/SKILL.md
+++ b/plugins/core/skills/gather-git-context/SKILL.md
@@ -23,7 +23,7 @@ JSON with all context values:
 ```json
 {
   "branch": "feature-branch-name",
   "base_branch": "main",
-  "repo_url": "git@github.com:owner/repo.git",
+  "repo_url": "https://github.com/owner/repo",
   "archived_tickets": [".workaholic/tickets/archive/branch/ticket1.md", "..."],
   "git_log": "abc1234 First commit\\ndef5678 Second commit"
 }
@@ -33,7 +33,7 @@ JSON with all context values:

 - **branch**: Current branch name
 - **base_branch**: Default branch of the remote (usually `main`)
-- **repo_url**: Remote origin URL
+- **repo_url**: Remote origin URL in HTTPS format (SSH URLs are automatically converted)
 - **archived_tickets**: Array of archived ticket paths for current branch
 - **git_log**: Git log from base branch to HEAD (oneline format)
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -59,6 +59,8 @@ Subagents must use skills for common operations instead of inline shell commands

 Never write inline git commands like `git branch --show-current` or `git remote show origin` in subagent markdown files. Subagents preload the skill and gather context themselves.

+**Shell Script Principle**: Never use complex inline shell commands (pipes, sed, awk) in subagent or command markdown files. Extract multi-step shell operations to bundled scripts in skills (`skills/<name>/sh/<script>.sh`). This ensures consistency, testability, and permission-free execution.
+
 ## Commands

 | Command                          | Description                                      |
```

## Considerations

- **Backward compatibility**: The HTTPS format is already expected by consumers (write-changelog, write-story). This change makes the contract explicit.
- **Non-GitHub remotes**: The transformation only handles GitHub SSH URLs. Other formats (HTTPS, GitLab, etc.) pass through unchanged. This is acceptable since the codebase is GitHub-hosted.
- **Shell complexity**: The sed commands in the patch are simple single-purpose transformations. The principle discourages complex multi-pipe inline commands, not all shell usage.

## Final Report

Development completed as planned. Updated gather-git-context to transform SSH URLs to HTTPS format and added shell script principle to CLAUDE.md.
