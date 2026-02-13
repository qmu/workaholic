---
created_at: 2026-02-13T13:15:04+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Enforce Absolute Paths for Skill Shell Script References

## Overview

Skill shell scripts are referenced throughout the codebase with relative paths like `bash .claude/skills/<name>/sh/<script>.sh`. These paths fail at runtime with "No such file or directory" (exit code 127) because `.claude/skills/` does not exist -- the actual installed path is `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/`. This ticket adds an explicit rule to the root CLAUDE.md mandating absolute paths, and updates the existing "Common Operations" table and "Shell Script Principle" example which currently demonstrate the broken relative pattern.

## Key Files

- `CLAUDE.md` - Root project instructions; lines 59-88 contain the "Common Operations" table and "Shell Script Principle" section, both of which use the broken relative `.claude/skills/` path pattern

## Related History

This is a recurring class of bug that has caused runtime failures across multiple features. The fix was first applied to individual files (archive-ticket, commit, drive-approval) but never codified as a project-wide rule, allowing new code to continue introducing relative paths.

Past tickets that touched similar areas:

- [20260204215053-fix-skill-script-race-condition.md](.workaholic/tickets/archive/drive-20260204-160722/20260204215053-fix-skill-script-race-condition.md) - Fixed 4 skill files to use absolute `~/` paths (same root cause)
- [20260129101447-fix-archive-script-path-reference.md](.workaholic/tickets/archive/main/20260129101447-fix-archive-script-path-reference.md) - Fixed archive-ticket path reference (same class of bug)
- [20260129094618-fix-create-branch-path-reference.md](.workaholic/tickets/archive/feat-20260129-023941/20260129094618-fix-create-branch-path-reference.md) - Fixed create-branch path reference (same class of bug)
- [20260212183330-add-effort-enum-to-write-final-report.md](.workaholic/tickets/archive/drive-20260212-122906/20260212183330-add-effort-enum-to-write-final-report.md) - Discovered the relative path issue during write-final-report fix; final report notes it as an insight

## Implementation Steps

1. **Add "Skill Script Path Rule" section to CLAUDE.md** after the "Shell Script Principle" section (after line 88). This new rule mandates that all skill shell script invocations must use the absolute path from home directory: `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/<name>/sh/<script>.sh`. Include a "Wrong" / "Correct" example pair to match the existing documentation style.

2. **Update the "Common Operations" table in CLAUDE.md** (lines 59-62). Replace the relative paths in the Usage column with the absolute `~/` paths.

3. **Update the "Shell Script Principle" correct example in CLAUDE.md** (line 87). The existing "Correct" example already uses the absolute path -- verify it is consistent with the new rule. If it already matches, no change needed.

## Patches

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -58,8 +58,8 @@ Subagents must use skills for common operations instead of inline shell commands:

 | Operation | Skill | Usage |
 | --------- | ----- | ----- |
-| Git context (branch, base, URL) | gather-git-context | `bash .claude/skills/gather-git-context/sh/gather.sh` |
-| Ticket metadata (date, author) | gather-ticket-metadata | `bash .claude/skills/gather-ticket-metadata/sh/gather.sh` |
+| Git context (branch, base, URL) | gather-git-context | `bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/gather-git-context/sh/gather.sh` |
+| Ticket metadata (date, author) | gather-ticket-metadata | `bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/gather-ticket-metadata/sh/gather.sh` |

 Never write inline git commands like `git branch --show-current` or `git remote show origin` in subagent markdown files. Subagents preload the skill and gather context themselves.
```

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -87,6 +87,18 @@ if [ "$current" = "main" ]; then echo "on_main"; fi
 bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/check.sh
 ```

+### Skill Script Path Rule
+
+> **CRITICAL: All skill shell script references must use the absolute path from home directory.**
+
+The installed plugin path is `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/`. Relative paths like `.claude/skills/` do NOT resolve at runtime and cause exit code 127 failures.
+
+**Wrong** (relative path):
+```bash
+bash .claude/skills/gather-ticket-metadata/sh/gather.sh
+```
+
+**Correct** (absolute path):
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/gather-ticket-metadata/sh/gather.sh
+```
+
 ## Commands
```

## Considerations

- The CLAUDE.md "Shell Script Principle" section (line 87) already has one correct absolute path example for `branching/sh/check.sh`, but the "Common Operations" table two lines above uses the broken relative paths -- this inconsistency likely confuses agents into using either form (`CLAUDE.md` lines 61-62 vs line 87)
- The new rule must come before `## Commands` so agents read it as part of the architecture policy, not as a footnote
- Archived tickets in `.workaholic/tickets/archive/` also contain relative paths but these are historical records and should NOT be modified -- the audit in the companion ticket must exclude the archive directory
- The `.workaholic/specs/` and `.workaholic/policies/` documentation files also contain relative paths, but these are generated by scan agents and will be regenerated with correct paths once the skill SKILL.md files are fixed in the companion ticket
