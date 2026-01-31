---
created_at: 2026-01-31T23:32:43+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: 0adb230
category: Changed
---

# Fix Archive Script Invocation Hallucination

## Overview

Claude hallucinates the archive script path and invocation method instead of reading the `archive-ticket` skill documentation. It invokes `plugins/core/skills/archive-ticket/sh/archive-ticket.sh` (wrong filename) without the `bash` prefix, causing "exit code 127: no such file or directory" errors.

## Current Behavior

```
Bash(plugins/core/skills/archive-ticket/sh/archive-ticket.sh ...)
⎿  Error: Exit code 127
   (eval):1: no such file or directory: plugins/core/skills/archive-ticket/sh/archive-ticket.sh
```

Claude is:
1. Guessing the filename as `archive-ticket.sh` (skill name + `.sh`)
2. Not using the `bash` prefix required for script execution
3. Not reading the actual skill documentation which clearly shows the correct usage

## Expected Behavior

Claude should read the `archive-ticket` skill documentation and invoke:

```bash
bash plugins/core/skills/archive-ticket/sh/archive.sh \
  <ticket-path> "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
```

## Related History

- `20260129101447-fix-archive-script-path-reference.md`: Fixed path `.claude/skills/archive-ticket/sh/archive.sh` → `plugins/core/skills/archive-ticket/sh/archive.sh`
- `20260127103522-posix-shell-compatibility.md`: Converted scripts to POSIX sh, established `bash <path>` invocation pattern

## Root Cause Analysis

The skill is preloaded in `drive.md` frontmatter, but Claude doesn't always read the preloaded skill content before invoking it. Instead, it guesses the invocation based on:
- Skill name → filename pattern (`archive-ticket` → `archive-ticket.sh`)
- Directory structure pattern (without reading actual files)

## Key Files

| File | Purpose |
|------|---------|
| `plugins/core/skills/archive-ticket/SKILL.md` | Contains correct usage: `bash plugins/core/skills/archive-ticket/sh/archive.sh` |
| `plugins/core/commands/drive.md` | Preloads archive-ticket skill, says "Follow **archive-ticket** skill" |
| `plugins/core/skills/request-approval/SKILL.md` | References archive-ticket skill after approval |

## Implementation

### Approach: Add Explicit Invocation Instructions

Rather than relying on Claude to read the skill, add the exact command inline where the skill is referenced.

### 1. Update `drive.md` Command

Replace vague "Follow **archive-ticket** skill" with explicit command:

```markdown
**"Approve"**:
1. Follow **write-final-report** skill to update ticket effort
2. Archive and commit using the preloaded **archive-ticket** skill:
   ```bash
   bash plugins/core/skills/archive-ticket/sh/archive.sh \
     "<ticket-path>" "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
   ```
3. Continue to next ticket
```

### 2. Update `request-approval/SKILL.md`

Add explicit invocation after approval options:

```markdown
- **Approve**: Follow write-final-report skill, then run:
  ```bash
  bash plugins/core/skills/archive-ticket/sh/archive.sh \
    "<ticket-path>" "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
  ```
```

### 3. Cross-Reference Verification

Ensure all references to archive-ticket skill include the actual command, not just "follow the skill".

## Verification

1. Run `/drive` with a test ticket
2. Approve the implementation
3. Verify the archive script is invoked with:
   - `bash` prefix
   - Correct path: `plugins/core/skills/archive-ticket/sh/archive.sh`
   - All required arguments
4. Confirm no "exit code 127" errors

## Out of Scope

- Changing the script filename (keep as `archive.sh`)
- Modifying the script itself
- Adding validation to detect wrong invocations
