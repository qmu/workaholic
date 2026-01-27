# Add Auto-Approve Permissions for Common Commands

## Overview

Configure `.claude/settings.json` with `allow` rules for safe, read-only commands used by workaholic agents. This eliminates repetitive permission prompts during skill execution (e.g., terms-writer, spec-writer, changelog).

## Layer

Config

## Key Files

- `.claude/settings.json` - Add allow rules for safe commands

## Implementation

1. **Add allow rules to settings.json**

   Update `.claude/settings.json` to include allow patterns for commonly used safe commands:

   ```json
   {
     "permissions": {
       "allow": [
         "Bash(git status*)",
         "Bash(git log*)",
         "Bash(git diff*)",
         "Bash(git branch*)",
         "Bash(git rev-parse*)",
         "Bash(git rev-list*)",
         "Bash(git remote show*)",
         "Bash(git show*)",
         "Bash(ls *)",
         "Bash(head *)",
         "Bash(tail *)",
         "Bash(wc *)",
         "Bash(date *)",
         "Bash(gh pr list*)",
         "Bash(gh pr view*)",
         "Bash(gh repo view*)",
         "Bash(gh api*)"
       ],
       "deny": [
         "Bash(git -C:*)"
       ]
     }
   }
   ```

2. **Test the configuration**

   Run `/drive` or invoke terms-writer to verify prompts no longer appear for these commands.

## Notes

- Only read-only and non-destructive commands are allowed
- Destructive commands (commit, push, rm, mv) still require approval
- The `deny` rule for `git -C` is preserved for safety
