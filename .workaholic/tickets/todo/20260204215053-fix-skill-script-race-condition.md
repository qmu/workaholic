---
created_at: 2026-02-04T21:50:53+09:00
author: a@qmu.jp
type: bugfix
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
---

# Fix Skill Shell Script Race Condition on First Execution

## Overview

Claude Code intermittently fails to execute skill shell scripts with "no such file or directory" errors on the first attempt, then succeeds on retry. The error occurs when invoking scripts via paths like `~/.claude/plugins/cache/workaholic/core/1.0.31/skills/archive-ticket/sh/archive.sh`. This suggests a race condition where the plugin cache is not fully populated when Claude Code resolves the `.claude/skills/` virtual path.

## Problem Analysis

### Observed Behavior

1. First invocation fails: `bash: no such file or directory`
2. Immediate retry succeeds with identical command
3. Affects scripts referenced via `.claude/skills/` prefix
4. Full resolved path includes version-specific cache directory

### Possible Causes

1. **Plugin cache lazy loading**: The cache directory structure may be created asynchronously, and Claude Code attempts to resolve paths before files are copied
2. **Path resolution timing**: The `.claude/skills/` virtual path is resolved before the symlink or cache directory is fully set up
3. **Filesystem sync delay**: On some systems, file creation may not be immediately visible due to filesystem buffering

### Evidence from Path Structure

The error path `~/.claude/plugins/cache/workaholic/core/1.0.31/skills/archive-ticket/sh/archive.sh` shows:
- Plugin: `workaholic`
- Subplugin: `core`
- Version: `1.0.31`
- This versioned cache structure suggests lazy extraction from a plugin archive

## Key Files

- `plugins/core/skills/*/SKILL.md` - Skill definitions referencing shell scripts
- `plugins/core/skills/*/sh/*.sh` - Shell scripts that fail on first execution
- `plugins/core/skills/archive-ticket/sh/archive.sh` - Specifically mentioned in error report

## Related History

Historical tickets show recurring issues with skill script path references, indicating this is a persistent problem area that has been addressed from different angles without fully solving the race condition.

Past tickets that touched similar areas:

- [20260129101447-fix-archive-script-path-reference.md](.workaholic/tickets/archive/main/20260129101447-fix-archive-script-path-reference.md) - Fixed `.claude/skills/` vs `plugins/core/skills/` path confusion (same layer: Config)
- [20260131225833-fix-archive-script-invocation-hallucination.md](.workaholic/tickets/archive/drive-20260131-223656/20260131225833-fix-archive-script-invocation-hallucination.md) - Fixed Claude hallucinating wrong script paths (same issue area)
- [20260127193706-bundle-shell-scripts-for-permission-free-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127193706-bundle-shell-scripts-for-permission-free-skills.md) - Established bundled script pattern for permission-free execution

## Implementation Steps

### Investigation Phase

1. **Reproduce the issue**: Run `/drive` or other commands that invoke skill scripts and observe first-execution failures

2. **Identify timing**: Add diagnostic output to determine if the cache directory exists but file is missing vs directory not existing

3. **Check Claude Code plugin loader**: Review if there's a documented mechanism for ensuring cache is ready before script execution

### Mitigation Options

#### Option A: Add retry logic to skill scripts (Workaround)

Create a wrapper function or modify invocation pattern to retry on first failure:

```bash
# In skill SKILL.md, document retry pattern:
script=".claude/skills/<skill>/sh/<script>.sh"
if ! bash "$script" "$@" 2>/dev/null; then
  sleep 0.1
  bash "$script" "$@"
fi
```

**Pros**: Immediate fix, no Claude Code changes needed
**Cons**: Adds latency, treats symptom not cause, clutters skill documentation

#### Option B: Use `test -f` guard before execution

```bash
script=".claude/skills/<skill>/sh/<script>.sh"
while [ ! -f "$script" ]; do sleep 0.1; done
bash "$script" "$@"
```

**Pros**: More robust than blind retry
**Cons**: Could hang if file truly doesn't exist

#### Option C: Create skill initialization check skill

Create a dedicated skill that verifies cache readiness before other operations:

```bash
# .claude/skills/verify-cache/sh/check.sh
for skill in archive-ticket commit gather-ticket-metadata; do
  script=".claude/skills/${skill}/sh/*.sh"
  if ! ls $script >/dev/null 2>&1; then
    echo "Waiting for plugin cache..."
    sleep 0.5
  fi
done
echo '{"cache_ready": true}'
```

**Pros**: Centralizes fix, one-time delay
**Cons**: Adds initialization step to workflows

#### Option D: Report upstream to Claude Code

If this is a Claude Code plugin loader bug, file an issue with reproduction steps.

**Pros**: Addresses root cause
**Cons**: Depends on external fix, unknown timeline

### Recommended Approach

Implement Option C (cache verification skill) as an immediate mitigation, while preparing Option D (upstream report) for long-term fix.

1. Create `plugins/core/skills/verify-cache/SKILL.md` and `sh/check.sh`
2. Modify commands that use shell scripts to call verify-cache first
3. Document the issue for Claude Code team with reproduction steps

## Verification

1. Install plugin fresh (clear cache): `rm -rf ~/.claude/plugins/cache/workaholic`
2. Run `/drive` with a ticket that uses archive-ticket script
3. Verify no "no such file or directory" errors on first attempt
4. Repeat test 5 times to confirm reliability

## Considerations

- **Performance impact**: Any retry/wait logic adds latency; minimize by checking only critical scripts
- **False positives**: Ensure the guard doesn't mask legitimate missing-file errors (typos in path)
- **Plugin version transitions**: Cache may have stale entries from previous versions; consider version-aware checks
- **Cross-platform**: Ensure any timing-based fixes work on macOS, Linux, and Windows (WSL)
- **Root cause**: This ticket provides a workaround; the true fix may require changes to Claude Code's plugin loading mechanism
