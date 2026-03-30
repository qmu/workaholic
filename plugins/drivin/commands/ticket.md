---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
---

# Ticket

**Notice:** When user input contains `/ticket` - whether "create /ticket", "write /ticket", "add /ticket for X", or similar - they likely want this command.

**CRITICAL:** NEVER implement code changes when this command is invoked - only create tickets. The actual implementation happens later via `/drive`.

Thin alias for ticket-organizer subagent.

## Instructions

### Step 0: Worktree Guard

Check if trip worktrees exist before proceeding:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-worktrees.sh
```

If `has_worktrees` is `true`, present the user with a choice using `AskUserQuestion` with selectable options:
- **"Continue here"** - Proceed with ticket creation on the current branch
- **"Switch to worktree"** - Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-all-worktrees.sh`, display the worktree list, and inform the user to navigate to the selected worktree to run `/ticket` there

If `has_worktrees` is `false`, proceed silently to Step 1.

**Rationale**: Prevents creating tickets on a drive branch when the user may intend to work within a trip worktree.

**Trip branch compatibility**: Ticket creation works on `trip/*` branches. The ticket-organizer detects these as non-main branches and skips branch creation. Tickets go to `.workaholic/tickets/todo/` regardless of branch type. When running inside a trip worktree, tickets are created in the worktree's ticket directory.

### Step 1: Invoke Ticket Organizer

Invoke ticket-organizer subagent via Task tool:

```
Task tool with subagent_type: "drivin:ticket-organizer", model: "opus"
prompt: "Create ticket for: <$ARGUMENT>. Target: <todo|icebox based on argument>"
```

Handle the response:

- `status: "success"` - If `branch_created` is present, confirm branch creation. Proceed to step 2.
- `status: "duplicate"` - Inform user, show existing ticket path, done
- `status: "needs_decision"` - Present options using `AskUserQuestion`, re-invoke with decision
- `status: "needs_clarification"` - Present questions using `AskUserQuestion`, re-invoke with answers

### Step 2: Commit and Present

**Skip commit if invoked during `/drive`** - archive script handles it.

Otherwise:
- Stage ticket(s): `git add <paths>`
- Commit: "Add ticket for <short-description>"
- Present ticket location and summary
- Tell user to run `/drive` to implement
