---
created_at: 2026-04-04T01:44:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.1h
commit_hash: e160408
category: Added
---

# Add core dependency check to work plugin

## Context

When the work plugin is installed without the core plugin, commands will fail silently because they reference core skills and scripts via `${CLAUDE_PLUGIN_ROOT}/../core/`. Instead of cryptic "file not found" errors, the work plugin should detect the missing dependency and inform the user to install core.

## Plan

### Step 1: Create dependency check script

Create `plugins/work/skills/check-deps/scripts/check.sh`:

```bash
#!/bin/bash
# Check that required dependency plugins are installed
# Usage: bash check.sh
# Output: JSON with dependency status

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
plugin_root="$(cd "${script_dir}/../../.." && pwd)"

core_path="${plugin_root}/../core"

if [ -d "$core_path" ] && [ -f "${core_path}/.claude-plugin/plugin.json" ]; then
  echo '{"ok": true}'
else
  echo '{"ok": false, "missing": ["core"], "message": "The work plugin requires the core plugin. Please install it: /plugin marketplace add qmu/workaholic and enable the core plugin."}'
fi
```

### Step 2: Create `check-deps` skill

Create `plugins/work/skills/check-deps/SKILL.md` with documentation for the dependency check.

### Step 3: Add dependency check to commands

Add a dependency check as the first step (Step 0 or before existing Step 0) in each work command:
- `commands/drive.md` - Check deps before worktree guard
- `commands/ticket.md` - Check deps before worktree guard
- `commands/trip.md` - Check deps before create/resume
- `commands/scan.md` - Check deps before gather context

The check runs `bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh`. If `ok` is `false`, display the `message` to the user and stop.

## Verification

- With core installed: commands proceed normally, no visible check
- Without core installed: commands display clear message asking user to install core
- Script uses `${CLAUDE_PLUGIN_ROOT}` path resolution (not relative paths)
