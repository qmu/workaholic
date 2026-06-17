---
name: ship
description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
skills:
  - workaholic:trip-protocol
  - workaholic:ship
  - workaholic:branching
  - workaholic:write-release-note
---

# Ship

**Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` - whether "run /ship", "do /ship", "ship it", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

Context-aware ship workflow. Steps:

1. **Workspace Guard** and **Ticket Guard** — follow `workaholic:ship` §3 and §4.
2. **Detect context**: `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh`.
3. **Route by context**:
   - `work` — run `workaholic:ship`'s **Ship Flow** (§5) directly on the current branch. No worktree handling.
   - `worktree` or `unknown` — follow `workaholic:trip-protocol`'s **Trip Ship → Context routing** (worktree selection / drive-vs-trip prompt), which wraps the `workaholic:ship` Ship Flow with worktree sync + cleanup.

**Deployment confirmation is required.** `/ship` only completes a deployment when an established way to confirm it succeeded exists (a `.workaholic/deployments/` entry or a `CLAUDE.md` `## Verify` section). When none exists, the Ship Flow **halts** (§1-4) and this command asks the user — via AskUserQuestion at this command/main-agent level — to provide a verification path / credentials, inspect production to establish one, author a `.workaholic/deployments/` entry, or abort. All such user interaction happens here, not in the skill's leaf scripts.

`workaholic:ship` is the trip-independent essence (usable by any agent on its own); the worktree/trip lifecycle lives in `workaholic:trip-protocol` and is Claude-Code-only.
