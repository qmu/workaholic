---
created_at: 2026-04-04T01:44:05+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Block ship when todo tickets remain

## Context

The `/ship` command should refuse to merge a PR if there are remaining tickets in `.workaholic/tickets/todo/`. This prevents shipping incomplete work, especially when catching up with the main branch that includes other contributors' pull requests.

### Historical Context

A related rule previously existed in the `/story` command (now `/report`). Commit `277b63b` (2026-02-01, ticket `20260201103205-stop-story-moving-tickets-to-icebox.md`) removed it because `/story` was **automatically moving** remaining tickets to icebox without user consent. That was unwanted behavior — the report command silently reorganized tickets during documentation generation.

The approach here is fundamentally different:
- **Old (reverted)**: `/story` silently moved remaining tickets to icebox → invasive, unwanted automation
- **New (this ticket)**: `/ship` blocks the merge and informs the user → guard, not automatic cleanup

The user explicitly decides what to do with remaining tickets (implement via `/drive`, move to icebox manually, or abandon). `/ship` only enforces that the todo directory is clean before allowing the merge.

## Plan

### Step 1: Add todo-clean check to ship pre-check flow

In `plugins/core/commands/ship.md`, add a new step between the Workspace Guard (Step 0) and Context Detection (Step 1):

**Step 0.5: Ticket Guard**

```bash
ls -1 .workaholic/tickets/todo/*.md 2>/dev/null | wc -l
```

If count > 0:
1. List the remaining ticket filenames
2. Inform the user: "Cannot ship: N ticket(s) remaining in `.workaholic/tickets/todo/`. All tickets must be implemented, moved to icebox, or removed before merging."
3. Present options via AskUserQuestion:
   - **"Move all to icebox"** — Move remaining tickets to `.workaholic/tickets/icebox/`, stage and commit, then proceed with ship
   - **"Stop"** — Halt the command so the user can handle tickets first (run `/drive`, manually reorganize, etc.)
4. If "Stop", end the command immediately

If count = 0, proceed silently to Step 1.

### Step 2: Create check script

Create `plugins/core/skills/ship/scripts/check-todo.sh`:

```bash
#!/bin/bash
# Check if todo tickets directory is clean
# Usage: bash check-todo.sh
# Output: JSON with ticket count and file list

set -euo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
todo_dir="${root}/.workaholic/tickets/todo"

if [ ! -d "$todo_dir" ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
  exit 0
fi

tickets=()
while IFS= read -r f; do
  tickets+=("$(basename "$f")")
done < <(find "$todo_dir" -name '*.md' -type f 2>/dev/null | sort)

count=${#tickets[@]}

if [ "$count" -eq 0 ]; then
  echo '{"clean": true, "count": 0, "tickets": []}'
else
  ticket_json=$(printf '%s\n' "${tickets[@]}" | jq -R . | jq -s .)
  echo "{\"clean\": false, \"count\": ${count}, \"tickets\": ${ticket_json}}"
fi
```

### Step 3: Update ship.md to use the script

Replace the inline `ls` check with:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
```

Parse the JSON output. If `clean` is `false`, display ticket list and present the options from Step 1.

## Verification

- With no tickets in todo: ship proceeds normally (no visible check)
- With tickets in todo: ship blocks and shows ticket list with options
- "Move all to icebox" moves tickets, commits, and proceeds with ship
- "Stop" halts the command
- Script uses `${CLAUDE_PLUGIN_ROOT}` path (not relative)
- No inline shell conditionals in ship.md (uses skill script)
