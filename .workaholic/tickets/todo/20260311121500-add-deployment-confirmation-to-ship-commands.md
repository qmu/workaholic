---
created_at: 2026-03-11T12:15:00+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
---

# Add Deployment Confirmation to Ship Commands

## Overview

The `/ship-drive` and `/ship-trip` commands execute arbitrary deployment instructions from user-provided `cloud.md` files without any confirmation step. The merge step is inherently confirmed by the user approving the Bash tool call, but the deploy step reads free-form instructions and executes them immediately after merge succeeds.

Add an explicit confirmation step between the merge and deploy phases. After cloud.md is found, display its Deploy section contents to the user and ask for confirmation before executing. This adds a safety checkpoint without breaking the automated flow for users who approve quickly.

## Key Files

- `plugins/drivin/commands/ship-drive.md` - Deploy step at Step 3 (lines 48-56)
- `plugins/trippin/commands/ship-trip.md` - Deploy step at Step 5 (lines 64-73)
- `plugins/drivin/skills/ship/SKILL.md` - Cloud.md convention documentation

## Related History

- [20260311105613-add-ship-drive-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105613-add-ship-drive-command.md) - Created ship-drive with cloud.md convention
- [20260311105614-add-ship-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105614-add-ship-trip-command.md) - Created ship-trip reusing the same convention

## Implementation Steps

1. **Update `plugins/drivin/commands/ship-drive.md` Step 3 (Deploy)**:
   - After finding cloud.md and before executing, add a confirmation substep:
     - Read the `## Deploy` section
     - Display the deploy instructions to the user
     - Ask the user to confirm: "Deploy instructions found in cloud.md. Proceed with deployment?" using `AskUserQuestion`
     - If user declines, skip deployment and proceed to completion with "Deployment skipped by user"
   - Keep the step structure clean -- this is a substep within the existing deploy step, not a new top-level step

2. **Update `plugins/trippin/commands/ship-trip.md` Step 5 (Deploy)**:
   - Apply the same confirmation pattern as ship-drive
   - After finding cloud.md, display deploy instructions and ask for confirmation before executing

3. **Update `plugins/drivin/skills/ship/SKILL.md`**:
   - Add a note in the Cloud.md Convention section about the confirmation step: "Before executing deploy instructions, the ship command displays the Deploy section and asks for user confirmation."

## Patches

### `plugins/drivin/commands/ship-drive.md`

```diff
--- a/plugins/drivin/commands/ship-drive.md
+++ b/plugins/drivin/commands/ship-drive.md
@@ -53,7 +53,7 @@

 - If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to completion.
-- If `found` is `true`: read the file, find the `## Deploy` section, and execute the instructions using Bash.
+- If `found` is `true`: read the file and find the `## Deploy` section. Display the deploy instructions to the user, then ask for confirmation with AskUserQuestion: "Proceed with deployment?". If the user declines, report "Deployment skipped by user." and skip to completion. If confirmed, execute the instructions using Bash.
```

### `plugins/trippin/commands/ship-trip.md`

```diff
--- a/plugins/trippin/commands/ship-trip.md
+++ b/plugins/trippin/commands/ship-trip.md
@@ -72,7 +72,7 @@

 - If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to completion.
-- If `found` is `true`: read the file, find the `## Deploy` section, and execute the instructions using Bash.
+- If `found` is `true`: read the file and find the `## Deploy` section. Display the deploy instructions to the user, then ask for confirmation with AskUserQuestion: "Proceed with deployment?". If the user declines, report "Deployment skipped by user." and skip to completion. If confirmed, execute the instructions using Bash.
```

## Considerations

- The confirmation uses `AskUserQuestion` which is a tool available to commands. This provides a structured yes/no prompt rather than relying on the user to manually approve each Bash execution. (`plugins/drivin/commands/ship-drive.md`, `plugins/trippin/commands/ship-trip.md`)
- Users who always want to deploy can still approve quickly -- the confirmation adds one interaction, not a complex gate. (`plugins/drivin/commands/ship-drive.md`)
- The Verify step does not need a separate confirmation since it follows directly from an approved deployment and is read-only (health checks, smoke tests). (`plugins/drivin/commands/ship-drive.md`)
