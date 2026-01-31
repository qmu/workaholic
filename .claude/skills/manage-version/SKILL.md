---
name: manage-version
description: Determine version type and update version files.
allowed-tools: Bash
user-invocable: false
---

# Manage Version

Update version in marketplace.json and plugin.json files.

## Version Update Script

Run the bundled script to update version:

```bash
bash .claude/skills/manage-version/sh/update.sh <version-type>
```

Arguments:
- `patch` - Increment patch version (1.0.25 -> 1.0.26)
- `minor` - Increment minor version (1.0.25 -> 1.1.0)
- `major` - Increment major version (1.0.25 -> 2.0.0)

The script:
1. Reads current version from `.claude-plugin/marketplace.json`
2. Calculates new version based on type
3. Updates version in:
   - `.claude-plugin/marketplace.json` (root and plugins array)
   - `plugins/core/.claude-plugin/plugin.json`
4. Outputs: `<old-version> -> <new-version>`
