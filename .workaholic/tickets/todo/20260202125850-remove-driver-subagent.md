---
created_at: 2026-02-02T12:59:50+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Remove Driver Subagent from Drive Command

## Overview

Remove the driver subagent intermediary and have the `/drive` command directly implement tickets using the drive-workflow and archive-ticket skills. This preserves modification history in the main conversation context, improving visibility and reducing context isolation issues.

## Related History

- **20260131164315-add-driver-agent.md**: Introduced driver subagent for isolated ticket implementation. This ticket reverses that pattern to preserve context.
- **20260131194500-per-ticket-approval-in-drive-loop.md**: Moved approval handling from driver to parent command due to context isolation issues. This ticket extends that pattern to implementation itself.
- **20260131225833-fix-archive-script-invocation-hallucination.md**: Fixed archive script path issues caused by subagent context. Removing the subagent eliminates this category of issues.

## Motivation

The driver subagent pattern has drawbacks:
1. **Lost modification history**: Implementation changes are made in isolated subagent context, invisible to the main conversation
2. **Context isolation issues**: The subagent cannot properly surface prompts or access parent context
3. **Debugging difficulty**: When implementations fail, the main conversation lacks the context to understand why
4. **Unnecessary indirection**: The drive-workflow skill is simple enough to execute directly in the command

## Key Files

| File | Purpose |
|------|---------|
| `plugins/core/commands/drive.md` | Main command to modify - will directly implement tickets |
| `plugins/core/agents/driver.md` | Subagent to remove |
| `plugins/core/skills/drive-workflow/SKILL.md` | Skill to be directly preloaded in drive command |
| `plugins/core/skills/archive-ticket/SKILL.md` | Already used directly, no changes needed |
| `plugins/core/skills/request-approval/SKILL.md` | Already used directly, no changes needed |

## Implementation

### Step 1: Update drive.md frontmatter

Add `drive-workflow` to the skills list:

```yaml
skills:
  - drive-workflow        # ADD: now used directly
  - request-approval
  - write-final-report
  - handle-abandon
  - archive-ticket
```

### Step 2: Rewrite Phase 2 in drive.md

Replace the current Step 2.1 (Invoke Driver) with direct implementation:

**Current flow:**
```
Step 2.1: Invoke driver subagent
   ↓
Driver reads ticket, implements, returns JSON summary
   ↓
Step 2.2: Request user approval
```

**New flow:**
```
Step 2.1: Read and Implement Ticket (inline)
   ↓
Follow drive-workflow skill directly:
  1. Read ticket file to understand requirements
  2. Identify key files from ticket
  3. Implement changes following ticket steps
  4. Run type checks per CLAUDE.md
   ↓
Step 2.2: Request user approval (using implementation context directly)
```

Update the instruction text to:
- Remove all references to "driver" and "subagent"
- Inline the drive-workflow steps directly
- Note that implementation context is now preserved in main conversation

### Step 3: Delete driver.md

Remove the file: `plugins/core/agents/driver.md`

### Step 4: Update skill descriptions (optional)

Consider updating drive-workflow/SKILL.md to clarify it's now used directly by the drive command rather than through a subagent. However, the skill content itself is still valid and requires no functional changes.

## Considerations

- The drive-navigator subagent remains unchanged (Phase 1 ticket listing)
- All post-approval skills (request-approval, write-final-report, handle-abandon, archive-ticket) already work directly with the drive command
- The implementation loop in Phase 2 may need clearer separation between tickets to avoid confusion
- Main conversation context will now include all implementation details - this is the intended benefit

## Verification

1. Run `/drive` on a test ticket
2. Verify implementation changes are visible in main conversation
3. Verify approval flow still works correctly
4. Verify archive-ticket script runs successfully
5. Confirm no references to driver subagent remain in codebase
