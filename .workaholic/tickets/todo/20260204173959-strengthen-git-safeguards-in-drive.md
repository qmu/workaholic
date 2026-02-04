---
created_at: 2026-02-04T17:39:59+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Strengthen safeguards against destructive git operations in /drive workflow

## Overview

Add explicit protections against destructive git operations (`git clean`, `git checkout .`, `git restore .`, `git reset --hard`) in the /drive workflow. Users have encountered situations where uncommitted tickets or unapproved ticket modifications were lost due to destructive operations during the drive workflow. This ticket adds pre-flight checks and explicit prohibitions to prevent accidental loss of ticket files or user work.

## Key Files

- `plugins/core/skills/drive-approval/SKILL.md` - Contains `git restore .` in abandonment flow (Section 4)
- `plugins/core/skills/drive-workflow/SKILL.md` - Implementation workflow, needs safeguard documentation
- `plugins/core/commands/drive.md` - Main drive command, may need critical rules section update
- `plugins/core/agents/drive-navigator.md` - Navigator subagent, may need safeguard awareness

## Related History

Several archived tickets relate to safeguarding against destructive operations in the /drive workflow, covering topics like approval requirements, ticket protection, archive enforcement, and git command restrictions. However, none specifically address git clean or comprehensive pre-flight checks for destructive operations.

Past tickets that touched similar areas:

- [20260125114643-require-approval-for-icebox-moves.md](.workaholic/tickets/archive/feat-20260124-200439/20260125114643-require-approval-for-icebox-moves.md) - Established pattern of requiring user approval before autonomously moving tickets (same layer: Config)
- [20260128213850-rename-fail-to-abandon-with-analysis.md](.workaholic/tickets/archive/feat-20260128-012023/20260128213850-rename-fail-to-abandon-with-analysis.md) - Introduced git restore . for discarding changes during abandonment flow
- [20260128224841-enforce-archive-script-usage.md](.workaholic/tickets/archive/feat-20260128-220712/20260128224841-enforce-archive-script-usage.md) - Strengthened prohibitions against manual ticket moves with DENY/NEVER patterns
- [20260131153736-split-drive-workflow-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131153736-split-drive-workflow-skill.md) - Created handle-abandon skill with git restore . procedure
- [20260201101950-halt-on-ticket-update-failure.md](.workaholic/tickets/archive/drive-20260131-223656/20260201101950-halt-on-ticket-update-failure.md) - Added safeguard to halt workflow when operations fail
- [20260127094857-use-deny-for-git-prohibition.md](.workaholic/tickets/archive/feat-20260126-214833/20260127094857-use-deny-for-git-prohibition.md) - Established deny rule pattern in settings.json to block git -C commands
- [20260124002211-include-uncommitted-tickets-in-drive-commit.md](.workaholic/tickets/archive/feat-20260123-191707/20260124002211-include-uncommitted-tickets-in-drive-commit.md) - Documents that uncommitted tickets are included via git add -A

## Implementation Steps

1. **Add pre-flight check to drive-approval skill** - Before executing `git restore .` in Section 4 (Handle Abandonment), add a check to ensure no uncommitted ticket files exist that would be lost:
   - Check for uncommitted changes in `.workaholic/tickets/` directory
   - If uncommitted ticket files exist, warn user and require explicit confirmation
   - Document this as a mandatory pre-flight check

2. **Add explicit prohibitions to drive-workflow skill** - Add a "## Prohibited Operations" section listing destructive commands that must NEVER be executed:
   - `git clean` (any flags)
   - `git checkout .` or `git checkout -- <path>`
   - `git restore .` (except in approved abandonment flow)
   - `git reset --hard`
   - `git stash drop` without explicit user request

3. **Update drive-approval abandonment flow** - Modify Section 4 to:
   - Add pre-flight check before `git restore .`
   - Explicitly exclude `.workaholic/tickets/` from restore if it contains uncommitted work
   - Use more targeted restore: `git restore . ':!.workaholic/tickets/'` to preserve ticket files

4. **Add safeguard section to drive.md Critical Rules** - Extend the Critical Rules section to include:
   - Prohibition against destructive git operations
   - Requirement to preserve uncommitted ticket files
   - Reference to pre-flight check procedures

5. **Document in drive-workflow skill** - Add a section explaining that implementation changes should be isolated from ticket management:
   - Implementation affects source files
   - Ticket files are managed separately
   - Destructive operations must exclude ticket directory

## Patches

### `plugins/core/skills/drive-approval/SKILL.md`

```diff
--- a/plugins/core/skills/drive-approval/SKILL.md
+++ b/plugins/core/skills/drive-approval/SKILL.md
@@ -109,9 +109,22 @@ When user selects "Abandon", do NOT commit implementation changes.

 ### Discard Implementation Changes

+**Pre-flight check**: Before discarding changes, verify no uncommitted ticket work will be lost:
+
+```bash
+git status --porcelain .workaholic/tickets/
+```
+
+If this shows uncommitted changes to ticket files:
+1. Warn user: "Uncommitted ticket changes detected. These will be preserved."
+2. Use targeted restore that excludes tickets directory
+
+**Discard implementation changes only** (preserves ticket files):
+
 ```bash
-git restore .
+git restore . ':!.workaholic/tickets/'
 ```

-Reverts all uncommitted changes to the working directory.
+Reverts implementation changes while preserving any uncommitted ticket modifications.

 ### Append Failure Analysis Section
```

### `plugins/core/skills/drive-workflow/SKILL.md`

```diff
--- a/plugins/core/skills/drive-workflow/SKILL.md
+++ b/plugins/core/skills/drive-workflow/SKILL.md
@@ -62,3 +62,19 @@ After implementation is complete, return a summary to the parent command:
 - **NEVER use AskUserQuestion** - drive command handles approval dialog
 - **NEVER archive tickets** - drive command handles archiving
 - After implementation, proceed to approval flow
+
+## Prohibited Operations
+
+The following destructive git commands are **NEVER** allowed during implementation:
+
+| Command | Risk | Alternative |
+|---------|------|-------------|
+| `git clean` | Deletes untracked files including uncommitted tickets | Do not use |
+| `git checkout .` | Discards all uncommitted changes | Use targeted checkout for specific files |
+| `git restore .` | Discards all uncommitted changes | Reserved for abandonment flow only |
+| `git reset --hard` | Discards all uncommitted changes and resets HEAD | Do not use |
+| `git stash drop` | Permanently deletes stashed changes | Only with explicit user request |
+
+**Rationale**: These operations can destroy uncommitted ticket files or user work. The `.workaholic/tickets/` directory may contain uncommitted tickets that must be preserved.
+
+If an implementation requires discarding changes, use targeted commands that exclude the tickets directory, or request user approval first.
```

### `plugins/core/commands/drive.md`

```diff
--- a/plugins/core/commands/drive.md
+++ b/plugins/core/commands/drive.md
@@ -150,3 +150,13 @@ If a ticket cannot be implemented (out of scope, too complex, blocked, or any ot
    - "Abort drive" - Stop the drive session entirely

 **Never commit ticket moves without explicit developer approval.**
+
+## Git Safety
+
+**NEVER execute destructive git operations** that could lose uncommitted work:
+
+- `git clean` - Deletes untracked files (would destroy uncommitted tickets)
+- `git checkout .` / `git restore .` - Discards changes (use only in approved abandonment with ticket exclusion)
+- `git reset --hard` - Discards all changes (never use)
+
+Before any operation that discards changes, verify `.workaholic/tickets/` has no uncommitted modifications. If it does, exclude it from the operation or warn user and get explicit approval.
```

> **Note**: These patches are based on current file structure. Verify exact line numbers before applying.

## Considerations

- The targeted `git restore . ':!.workaholic/tickets/'` syntax uses git pathspec exclusion, which should work with modern git versions
- Consider whether a shell script wrapper for safe restore would be more maintainable than inline commands
- The prohibition patterns follow established conventions from 20260128224841 (DENY/NEVER language)
- Pre-flight checks add overhead but prevent data loss - this trade-off is appropriate for destructive operations
- Future enhancement: could add a `safe-restore.sh` script to the skills directory that handles the pre-flight check and exclusion automatically
