---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills:
  - drive
  - core:system-safety
---

# Drive

**Notice:** When user input contains `/drive` - whether "run /drive", "do /drive", "start /drive", or similar - they likely want this command.

Implement tickets from `.workaholic/tickets/todo/` using intelligent prioritization, committing and archiving each one before moving to the next.

## Instructions

### Phase 0: Worktree Guard

Check if trip worktrees exist before proceeding:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-worktrees.sh
```

If `has_worktrees` is `true`, present the user with a choice using `AskUserQuestion` with selectable options:
- **"Continue here"** - Proceed with drive on the current branch
- **"Switch to worktree"** - Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-all-worktrees.sh`, display the worktree list, and inform the user to navigate to the selected worktree to run `/drive` there

If `has_worktrees` is `false`, proceed silently to Phase 1.

**Rationale**: Prevents accidental development on a drive branch when trip worktrees with in-progress work may be the intended target.

**Trip branch compatibility**: The drive workflow operates on any non-main topic branch, including `trip/*` branches. When running on a trip branch after a trip session completes, tickets are read from `.workaholic/tickets/todo/` and archived normally. Use `/ticket` to add refinement tickets, then `/drive` to implement them.

### Phase 1: Navigate Tickets

Invoke the drive-navigator subagent via Task tool:

```
Task tool with subagent_type: "drivin:drive-navigator", model: "opus"
prompt: "Navigate tickets. mode: <normal|icebox>"
```

Pass mode based on `$ARGUMENT`:
- If `$ARGUMENT` contains "icebox": mode = "icebox"
- Otherwise: mode = "normal"

Handle the response:
- `status: "empty"` - Inform user: "No tickets in queue or icebox."
- `status: "stopped"` - End the drive session
- `status: "icebox"` - Re-invoke with mode = "icebox"
- `status: "ready"` - Proceed to Phase 2 with the ordered ticket list

### Phase 2: Implement Tickets

For each ticket in the ordered list:

#### Step 2.1: Implement Ticket

Follow the preloaded **drive** skill (Workflow section). Implementation context is preserved in the main conversation, providing full visibility of changes made.

#### Step 2.2: Request Approval

Follow the preloaded **drive** skill (Approval section) to present approval dialog. **CRITICAL**: You MUST use the `title` and `overview` fields from the Step 2.1 workflow result to populate the approval prompt header and question. If these fields are unavailable, re-read the ticket file to obtain them. Never present an approval prompt without the ticket title and summary.

**CRITICAL**: Use `AskUserQuestion` with selectable `options`. NEVER proceed without explicit user approval.

#### Step 2.3: Handle User Response

**"Approve" or "Approve and stop"**:
1. Follow **drive** skill (Final Report section) to update ticket effort and append Final Report section
2. **Verify update succeeded**: If Edit tool fails, halt and report the error to user. DO NOT proceed to archive.
3. Archive and commit by calling the archive script directly:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh \
     <ticket-path> "<title>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"
   ```
   Where `<ticket-path>` is the current ticket file path in `todo/`, `<title>` is the commit title,
   and `<repo-url>` comes from the gather-git-context output.
   **NEVER manually move tickets** with `mv` + `git add` -- always use the archive script.
4. If "Approve and stop": break loop, skip Phase 3, go directly to Phase 4
5. Otherwise: continue to next ticket

**Free-form feedback** (user selects "Other" and provides text):

> **CRITICAL**: Update the ticket file FIRST. Do NOT re-implement until the ticket reflects the user's feedback.

1. Follow **drive** skill (Approval section, Handle Feedback) — this updates the ticket
2. **Verify** the ticket file was updated (re-read it)
3. Re-implement changes based on the updated ticket
4. Return to Step 2.2

**"Abandon"**:
1. Follow **drive** skill (Approval section, Handle Abandonment)
2. Continue to next ticket

### Phase 3: Re-check and Continue

After all tickets from the navigator's list are processed:

1. **Re-check todo directory**:
   ```bash
   ls -1 .workaholic/tickets/todo/*.md 2>/dev/null
   ```

2. **If new tickets found**:
   - Inform user: "Found N new ticket(s) added during this session."
   - Re-invoke drive-navigator with mode = "normal"
   - Continue to Phase 2 with the new ticket list

3. **If no new tickets**:
   - Check icebox (existing behavior from navigator)
   - If user declines icebox or icebox empty, proceed to Phase 4

### Phase 4: Completion

After todo is truly empty (and user declines icebox):
- Summarize what was done across all batches
- List all commits created during the session

**Session-wide tracking**: Maintain counters across multiple navigator batches:
- Total tickets implemented
- Total commits created
- List of all commit hashes

## Critical Rules

**NEVER autonomously move tickets to icebox.** Moving tickets is a developer decision, not an AI decision.

If a ticket cannot be implemented (out of scope, too complex, blocked, or any other reason):

1. **Stop and ask the developer** using `AskUserQuestion` with selectable `options`
2. Explain why implementation cannot proceed
3. Use selectable options (NEVER open-ended text questions):
   - "Move to icebox" - Move ticket to `.workaholic/tickets/icebox/` and continue to next
   - "Skip for now" - Leave ticket in queue, move to next ticket
   - "Abort drive" - Stop the drive session entirely

**Never commit ticket moves without explicit developer approval.**
