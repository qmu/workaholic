---
created_at: 2026-02-09T12:16:29+08:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Add Explicit run_in_background: false to Scan Command Agent Invocations

## Overview

Add an explicit `run_in_background: false` constraint to the `/scan` command's Phase 3 agent invocations. When the Bash tool's `run_in_background` parameter is set to `true` (or when Claude Code interprets parallel Task calls as background operations), agents running in the background automatically have their Write and Edit tool permissions denied. Since all 17 scan agents (8 viewpoint analysts, 7 policy analysts, changelog-writer, terms-writer) need Write/Edit to produce their output files, background execution causes silent failures where agents cannot write their documentation.

The fix is to add an explicit instruction in `plugins/core/commands/scan.md` (and any other scan-invoking commands) that all Task tool calls for scan agents MUST use `run_in_background: false` to ensure Write/Edit permissions are preserved.

## Key Files

- `plugins/core/commands/scan.md` - Phase 3 invokes all 17 agents in parallel; needs explicit `run_in_background: false` constraint
- `plugins/core/agents/stakeholder-analyst.md` - Example viewpoint analyst that requires Write/Edit tools (tools: Read, Write, Edit, Bash, Glob, Grep)
- `plugins/core/agents/changelog-writer.md` - Writer agent that requires Write/Edit tools
- `plugins/core/agents/terms-writer.md` - Writer agent that requires Write/Edit tools

## Related History

The scan command was recently migrated from a scanner subagent into a direct command-level orchestration to provide real-time agent progress visibility. The 17 parallel agent invocation pattern was established during the flatten-scan-writer-nesting refactoring.

Past tickets that touched similar areas:

- [20260208131751-migrate-scanner-into-scan-command.md](.workaholic/tickets/archive/drive-20260208-131649/20260208131751-migrate-scanner-into-scan-command.md) - Migrated scanner subagent into the scan command with direct 17-agent parallel invocation (same file: scan.md)
- [20260207035026-flatten-scan-writer-nesting.md](.workaholic/tickets/archive/drive-20260205-195920/20260207035026-flatten-scan-writer-nesting.md) - Flattened scan from 3-level to 2-level nesting with 17 parallel agents (same component: scan agents)
- [20260207113721-implement-full-partial-scan-modes.md](.workaholic/tickets/archive/drive-20260205-195920/20260207113721-implement-full-partial-scan-modes.md) - Implemented full/partial scan modes with agent selection (same component: scan command)
- [20260202201502-add-task-tool-to-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202201502-add-task-tool-to-ticket-organizer.md) - Fixed missing Task tool in ticket-organizer causing permission issues (same pattern: tool permission bugfix)

## Implementation Steps

1. **Update `plugins/core/commands/scan.md` Phase 3** to add an explicit constraint that all 17 agent Task tool calls must specify `run_in_background: false`. Add a note after the agent table explaining why this constraint is required (background agents lose Write/Edit permissions).

2. **Verify agent tool declarations** - Confirm all 17 scan agents declare Write and Edit in their tools frontmatter (they do based on current codebase review). No changes needed to agent files themselves.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -46,7 +46,9 @@
 | `changelog-writer` | `core:changelog-writer` | Pass repository URL |
 | `terms-writer` | `core:terms-writer` | Pass branch name |

-All invocations MUST be in a single message to run concurrently.
+All invocations MUST be in a single message to run concurrently. Each Task call MUST use `run_in_background: false` (the default).
+
+**CRITICAL**: Never set `run_in_background: true` for scan agents. Background agents have Write and Edit tool permissions automatically denied, which prevents agents from producing output files.
```

## Considerations

- The `run_in_background` parameter defaults to `false`, so this change is primarily a defensive safeguard against Claude Code interpreting the 17-agent parallel invocation as a background operation scenario (`plugins/core/commands/scan.md` Phase 3)
- All 17 scan agents declare `tools: Read, Write, Edit, Bash, Glob, Grep` in their frontmatter -- they all require Write/Edit to function correctly (`plugins/core/agents/stakeholder-analyst.md` and all sibling agents)
- The same constraint may need to apply to any future command that invokes scan agents in parallel, establishing a convention that write-capable agents must never run in background mode (`plugins/core/commands/scan.md`)
- This is a documentation-level fix in the command markdown, not a code change -- the behavior depends on how Claude Code interprets the Task tool invocation parameters at runtime
