---
created_at: 2026-02-12T18:33:30+08:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: b9ff019
category: Added
---

# Add Explicit Effort Enum and Update Command to write-final-report Skill

## Overview

After `/drive` approval, the agent updates ticket frontmatter with invalid effort values like "L" or "S" (t-shirt sizing) instead of the valid hour-based format (`0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`). This causes the PostToolUse hook validator (`validate-ticket.sh`) to reject the edit, breaking the archive flow. The root cause is that the `write-final-report` skill lists the valid values but does not instruct the agent to use the `update.sh` script for setting them. Without an explicit invocation command, the agent uses the Edit tool directly, and when it guesses the format wrong, the hook rejects it. This is a recurring problem already fixed twice (tickets `20260203174022` and `20260207170806`) but the fix remains incomplete because the skill still lacks the concrete `bash` invocation that would route the value through `update.sh`'s own validation gate.

## Key Files

- `plugins/core/skills/write-final-report/SKILL.md` - Primary target; lists valid effort values but does not show the `update.sh` invocation command, leaving the agent to guess the update mechanism
- `plugins/core/skills/update-ticket-frontmatter/SKILL.md` - Documents the `update.sh` usage pattern; preloaded by write-final-report but agent does not always consult it
- `plugins/core/skills/update-ticket-frontmatter/sh/update.sh` - Shell script with built-in effort validation (case statement at lines 22-29); the hard gate that prevents invalid values
- `plugins/core/skills/drive-approval/SKILL.md` - Approval flow that triggers write-final-report; already lists valid values inline at line 51
- `plugins/core/hooks/validate-ticket.sh` - PostToolUse hook that validates effort on Edit/Write operations (lines 155-164)

## Related History

This is the third attempt to fix the effort value mismatch problem. The first fix (20260203) added prominent warnings and a mapping table to write-final-report. The second fix (20260207) went further by adding validation to update.sh, inlining valid values, and adding guidance to drive-approval. Despite these improvements, the problem persists because the skill still does not explicitly instruct the agent to call `update.sh` -- the one path that has a hard validation gate. The agent continues to use the Edit tool directly, bypassing the script-level validation.

Past tickets that touched similar areas:

- [20260207170806-fix-effort-invalid-value-root-cause.md](.workaholic/tickets/archive/drive-20260205-195920/20260207170806-fix-effort-invalid-value-root-cause.md) - Added validation to update.sh, inlined valid values in write-final-report, added values to drive-approval (same files)
- [20260203174022-fix-effort-field-format-guidance.md](.workaholic/tickets/archive/drive-20260203-122444/20260203174022-fix-effort-field-format-guidance.md) - Added warning box and valid values table to write-final-report (same skill)
- [20260131162854-extract-update-ticket-frontmatter-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131162854-extract-update-ticket-frontmatter-skill.md) - Created update-ticket-frontmatter skill and update.sh script (same skill)

## Implementation Steps

1. **Add explicit `update.sh` invocation to write-final-report** (`plugins/core/skills/write-final-report/SKILL.md`): After the valid values table, add a "How to Update" subsection with the exact bash command to call `update.sh`. This ensures the agent uses the script (which has its own validation gate) rather than the Edit tool. The command should be: `bash .claude/skills/update-ticket-frontmatter/sh/update.sh <ticket-path> effort <value>`. Include an example with a concrete value.

2. **Add `allowed-tools: Bash` to write-final-report frontmatter** (`plugins/core/skills/write-final-report/SKILL.md`): The skill currently has no `allowed-tools` declaration. Adding `Bash` makes it explicit that the skill operates through shell commands, and reinforces that the update should go through `update.sh` rather than Edit.

3. **Add "MUST use update.sh" directive** (`plugins/core/skills/write-final-report/SKILL.md`): Add an explicit prohibition against using the Edit tool to modify the effort field. State: "ALWAYS use update.sh to set the effort value. NEVER use the Edit tool to modify the effort field directly." This closes the loophole where the agent sees the valid values, picks a wrong format anyway, and writes it directly via Edit.

## Patches

### `plugins/core/skills/write-final-report/SKILL.md`

```diff
--- a/plugins/core/skills/write-final-report/SKILL.md
+++ b/plugins/core/skills/write-final-report/SKILL.md
@@ -2,6 +2,7 @@
 name: write-final-report
 description: Write final report section with optional discovered insights.
 skills:
   - update-ticket-frontmatter
+allowed-tools: Bash
 user-invocable: false
 ---

@@ -30,6 +31,18 @@

 ALWAYS use one of these exact values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

+### How to Update
+
+**MUST use update.sh** -- NEVER use the Edit tool to modify the effort field directly.
+
+```bash
+bash .claude/skills/update-ticket-frontmatter/sh/update.sh <ticket-path> effort <value>
+```
+
+Example:
+```bash
+bash .claude/skills/update-ticket-frontmatter/sh/update.sh .workaholic/tickets/todo/20260212-example.md effort 0.5h
+```
+
 ## Final Report Section
```

## Considerations

- The `update.sh` script already validates effort values with a case statement (lines 22-29 of `plugins/core/skills/update-ticket-frontmatter/sh/update.sh`), so routing through it provides a double-check even if the agent passes a wrong value -- the script exits with an error and the agent can retry with a valid value
- The `validate-ticket.sh` hook (lines 155-164) only fires on Write/Edit tool operations, not on Bash tool operations. This means when the agent uses `update.sh` via Bash, the hook does NOT fire, but `update.sh` itself handles validation. When the agent uses Edit directly, the hook fires. Both paths now validate, but the `update.sh` path gives a clearer error message specific to effort values
- This is the third fix for the same recurring issue. The previous two fixes (20260203, 20260207) focused on making the valid values more prominent in documentation. This fix takes a different approach by explicitly directing the agent to use the script path, which has structural enforcement rather than relying on the agent reading and following documentation
- The `archive-ticket/sh/archive.sh` already uses `update.sh` for `commit_hash` and `category` fields (lines 62-64), establishing the pattern that frontmatter updates go through the script. The write-final-report skill should follow the same pattern for `effort`
- Adding `allowed-tools: Bash` to write-final-report may be slightly misleading since the skill also needs the Edit tool to append the Final Report section to the ticket. However, the Edit tool is available by default; `allowed-tools` adds additional tools beyond the default set. Verify that the skill frontmatter `allowed-tools` field adds to rather than replaces the default tool set (`plugins/core/skills/write-final-report/SKILL.md` lines 1-7)

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The relative `.claude/skills/` path used in skill documentation does not resolve at runtime
  **Context**: Skills reference shell scripts with `.claude/skills/<name>/sh/<script>.sh` but the actual installed path is `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/<name>/sh/<script>.sh`. The archive-ticket skill already uses the full absolute path pattern, which should be the standard for all skill script references.
