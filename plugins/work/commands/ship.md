---
name: ship
description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
skills:
  - core:trip-protocol
  - core:ship
  - core:branching
---

# Ship

**Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` - whether "run /ship", "do /ship", "ship it", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`core:`, `work:`, `standards:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin` and `trippin` are obsolete names long since merged into `work`. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

Context-aware ship workflow. Steps:

1. **Workspace Guard** and **Ticket Guard** — follow `core:ship` §3 and §4.
2. **Detect context**: `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/detect-context.sh`.
3. **Route by context**:
   - `work` — run `core:ship`'s **Ship Flow** (§5) directly on the current branch. No worktree handling.
   - `worktree` or `unknown` — follow `core:trip-protocol`'s **Trip Ship → Context routing** (worktree selection / drive-vs-trip prompt), which wraps the `core:ship` Ship Flow with worktree sync + cleanup.

`core:ship` is the trip-independent essence (usable by any agent on its own); the worktree/trip lifecycle lives in `core:trip-protocol` and is Claude-Code-only.
