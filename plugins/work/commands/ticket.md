---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
---

# Ticket

**Notice:** When user input contains `/ticket` - whether "create /ticket", "write /ticket", "add /ticket for X", or similar - they likely want this command.

**CRITICAL:** NEVER implement code changes when this command is invoked - only create tickets. The actual implementation happens later via `/drive`.

**Lead Lens**: Ticket scoping uses the `standards:leading-*` skills as policy lenses, mapped to the ticket's `layer` field. The `core:create-ticket` skill preloads them; the Lead Lens table in the skill documents the mapping.

Thin alias for `work:ticket-organizer` subagent.

## Instructions

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop.

### Step 0: Worktree Guard

Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-worktrees.sh`. If `has_worktrees` is `true`, present an `AskUserQuestion` with selectable options:
- **"Continue here"** — Proceed with ticket creation on the current branch.
- **"Switch to worktree"** — Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-all-worktrees.sh`, display the worktree list, and inform the user to navigate to the selected worktree to run `/ticket` there.

Rationale: prevents creating tickets on a drive branch when the user may intend to work within a trip worktree.

### Step 1: Invoke Ticket Organizer

Invoke `work:ticket-organizer` via Task tool (`model: "opus"`, prompt: `"Create ticket for: <$ARGUMENT>. Target: <todo|icebox based on argument>"`).

Handle the response:
- `status: "success"` — If `branch_created` is present, confirm branch creation. Proceed to step 2.
- `status: "duplicate"` — Inform user, show existing ticket path, done.
- `status: "needs_decision"` — Present options using `AskUserQuestion`, re-invoke with decision.
- `status: "needs_clarification"` — Present questions using `AskUserQuestion`, re-invoke with answers.

### Step 2: Commit and Present

**Skip commit if invoked during `/drive`** — the archive script handles it.

Otherwise: stage ticket(s) with `git add <paths>`, commit `"Add ticket for <short-description>"`, present the ticket location and summary, and tell the user to run `/drive` to implement.
