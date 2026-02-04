---
created_at: 2026-02-04T16:13:50+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Update manage-branch SKILL.md to Reference check.sh Script

## Overview

The manage-branch skill has a `check.sh` script that already exists but the SKILL.md still documents inline bash code instead of referencing the script. This causes unnecessary Claude Code permission prompts for read-only git operations. Update the skill documentation to reference the bundled script and add guidance for users who want to configure auto-approval for these safe operations.

## Key Files

- `plugins/core/skills/manage-branch/SKILL.md` - Update to reference check.sh script instead of inline bash
- `plugins/core/skills/manage-branch/sh/check.sh` - Existing script (already outputs JSON)
- `.claude/settings.local.json` - Example showing how users can auto-approve bash scripts

## Related History

Historical tickets established the pattern of bundling shell scripts into skills to avoid permission prompts and improve UX. The check.sh script was created as part of the manage-branch refactoring but SKILL.md was not fully updated.

Past tickets that touched similar areas:

- [20260127193706-bundle-shell-scripts-for-permission-free-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127193706-bundle-shell-scripts-for-permission-free-skills.md) - Established bundled script pattern for permission-free execution (same pattern)
- [20260202182054-gather-ticket-metadata-skill.md](.workaholic/tickets/archive/drive-20260202-134332/20260202182054-gather-ticket-metadata-skill.md) - Used the bundled script pattern for ticket metadata (same layer: Config)
- [20260203200934-refactor-ticket-organizer.md](.workaholic/tickets/archive/drive-20260203-122444/20260203200934-refactor-ticket-organizer.md) - Renamed create-branch to manage-branch and added check.sh (same file)

## Implementation Steps

1. **Update SKILL.md "Check Branch" section**:
   - Replace inline bash code block with script reference
   - Document the JSON output format matching check.sh output

2. **Add "Auto-Approval Configuration" section to SKILL.md**:
   - Explain that users can configure Claude Code to auto-approve bundled scripts
   - Show example `.claude/settings.local.json` entry: `"Bash(bash:*)"`
   - Note this is optional and applies to all bundled bash scripts

## Patches

### `plugins/core/skills/manage-branch/SKILL.md`

```diff
--- a/plugins/core/skills/manage-branch/SKILL.md
+++ b/plugins/core/skills/manage-branch/SKILL.md
@@ -11,14 +11,22 @@ Check current branch state and create new topic branches when needed.

 ## Check Branch

-Check if currently on a topic branch:
+```bash
+bash .claude/skills/manage-branch/sh/check.sh
+```
+
+### Output

-```bash
-current=$(git branch --show-current)
-if [ "$current" = "main" ] || [ "$current" = "master" ]; then
-  echo "on_main"
-else
-  echo "on_topic:$current"
-fi
+JSON with branch state:
+
+```json
+{
+  "on_main": true,
+  "branch": "main"
+}
 ```

+- `on_main`: Boolean indicating if on main/master branch
+- `branch`: Current branch name
+
 Topic branch patterns: `drive-*`, `trip-*`
@@ -46,3 +54,18 @@ JSON with the created branch name:
 ```

 The branch is automatically checked out after creation.
+
+## Auto-Approval Configuration
+
+To avoid permission prompts for bundled skill scripts, users can add the following to their `.claude/settings.local.json`:
+
+```json
+{
+  "permissions": {
+    "allow": [
+      "Bash(bash:*)"
+    ]
+  }
+}
+```
+
+This auto-approves all `bash` script invocations. The `.settings.local.json` file is user-local and should not be committed to the repository.
```

## Considerations

- **Existing check.sh already works**: The script outputs proper JSON format; only SKILL.md documentation needs updating
- **settings.local.json pattern**: The existing settings.local.json already has `"Bash(bash:*)"` which auto-approves bundled scripts - this just needs documentation
- **User-local configuration**: Auto-approval settings are intentionally in settings.local.json (not settings.json) as they are user preferences, not project requirements
- **Security trade-off**: Auto-approving `Bash(bash:*)` is safe for this project since all bundled scripts are read-only operations, but users should understand this applies to all bash script invocations
